pragma Singleton
import QtQuick
import QtCore
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

// Screenshots and screen recording (as in Ubuntu): Print opens the picker (area / screen / window,
// screenshot or video, with or without the pointer). The shot is taken from a frame frozen when the picker opened.
Singleton {
    id: root
    readonly property string home: Quickshell.env("HOME")
    readonly property string tmp: Quickshell.env("XDG_RUNTIME_DIR") + "/unia-shot"
    // the user's XDG Pictures and Videos folders (localized names included)
    function dir(loc) { return decodeURIComponent(String(StandardPaths.writableLocation(loc)).replace(/^file:\/\//, "")) }
    readonly property string shotsDir: dir(StandardPaths.PicturesLocation) + "/Screenshots"
    readonly property string videosDir: dir(StandardPaths.MoviesLocation) + "/Screencasts"

    property bool active: false              // the picker is open
    property string mode: "area"             // "area" | "screen" | "window"
    property bool video: false
    property bool pointer: false
    property string monitor: ""              // monitor of the chosen area / screen / window
    property string uiMonitor: ""            // where to show the controls (the focused monitor)
    property string quick: ""                // "screen" | "window": capture at once, without the picker
    property rect area: Qt.rect(0, 0, 0, 0)  // selection in monitor coordinates (kept between openings)
    property var windowSel: null             // { x, y, w, h, monitor }: global coordinates
    property var windows: []                 // windows on visible desks [{ x, y, w, h, monitor, title }]
    property int stamp: 0                    // changes on every opening, so the frames are re-read

    property bool recording: false
    property date recStart: new Date()
    property string recFile: ""
    readonly property bool canRecord: recorderCheck.found

    function frame(name, withPointer) { return `file://${tmp}/${name}${withPointer ? "-c" : ""}.png?${stamp}` }
    function mon(name) { return Hyprland.monitors.values.find(m => m.name === name) ?? null }

    // ---------- opening ----------
    function open(quickMode) {
        if (active || recording) { if (recording) stopRecording(); return }
        const ms = Hyprland.monitors.values
        quick = quickMode ?? ""
        uiMonitor = Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : ms[0].name
        if (!monitor || !mon(monitor) || quick === "screen") monitor = uiMonitor
        const cmds = ms.map(m => `grim -o ${m.name} "${tmp}/${m.name}.png" & grim -c -o ${m.name} "${tmp}/${m.name}-c.png" &`).join(" ")
        freeze.command = ["sh", "-c", `mkdir -p "${tmp}"; ${cmds} wait; hyprctl clients -j`]
        freeze.running = true
    }
    function close() { active = false }

    Process {
        id: freeze
        stdout: StdioCollector {
            onStreamFinished: {
                // windows on visible desks (the most recently focused on top)
                const vis = Hyprland.monitors.values.map(m => m.activeWorkspace ? m.activeWorkspace.id : null)
                try {
                    root.windows = JSON.parse(text).filter(c => c.mapped && !c.hidden && vis.includes(c.workspace.id))
                        .sort((a, b) => b.focusHistoryID - a.focusHistoryID)
                        .map(c => ({ x: c.at[0], y: c.at[1], w: c.size[0], h: c.size[1], title: c.title,
                                     monitor: (Hyprland.monitors.values.find(m => m.id === c.monitor) ?? {}).name }))
                } catch (e) { root.windows = [] }
                // the focused window by default (focusHistoryID 0 is last after sorting)
                if (root.windows.length && (root.quick === "window" || !root.windowSel)) root.windowSel = root.windows[root.windows.length - 1]
                if (root.area.width < 10) {
                    const m = root.mon(root.monitor)
                    root.area = Qt.rect(m.width / 4, m.height / 4, m.width / 2, m.height / 2)
                }
                root.stamp++
                if (root.quick) {                    // Shift+Print / Alt+Print: no picker
                    const keep = root.mode
                    root.mode = root.quick
                    root.video = false
                    root.capture()
                    root.mode = keep
                    return
                }
                root.active = true
            }
        }
    }

    // ---------- what to capture: a monitor and a rectangle in its coordinates ----------
    function target() {
        if (mode === "screen") { const m = mon(monitor); return { mon: monitor, x: 0, y: 0, w: m.width, h: m.height } }
        if (mode === "window" && windowSel) {
            const m = mon(windowSel.monitor)
            return { mon: windowSel.monitor, x: windowSel.x - m.x, y: windowSel.y - m.y, w: windowSel.w, h: windowSel.h }
        }
        return { mon: monitor, x: Math.round(area.x), y: Math.round(area.y), w: Math.round(area.width), h: Math.round(area.height) }
    }

    function capture() {
        const t = target()
        if (!t || t.w < 2 || t.h < 2) return
        active = false
        const stampStr = Qt.formatDateTime(new Date(), "yyyy-MM-dd HH-mm-ss")
        if (video) { startRecording(t, stampStr); return }
        const file = `${shotsDir}/Screenshot from ${stampStr}.png`
        const src = `${tmp}/${t.mon}${pointer ? "-c" : ""}.png`
        const m = mon(t.mon)
        const whole = t.x === 0 && t.y === 0 && t.w === m.width && t.h === m.height
        // every save runs as its own process, so two quick shots do not get in each other's way;
        // a whole screen is just copied (the frame is ready), anything else is cropped
        const make = whole ? `cp "$2" "$1"` : `magick "$2" -crop "$3" +repage "$1"`
        Quickshell.execDetached(["sh", "-c", `mkdir -p "$(dirname "$1")" && ${make} && wl-copy --type image/png < "$1" && exec unia-shot-notify "$1"`,
                                 "sh", file, src, `${t.w}x${t.h}+${t.x}+${t.y}`])
    }

    // ---------- video recording ----------
    function startRecording(t, stampStr) {
        const m = mon(t.mon)
        recFile = `${videosDir}/Screencast from ${stampStr}.mp4`
        recorder.command = ["sh", "-c", `mkdir -p "$(dirname "$1")" && exec wf-recorder -y -g "$2" -f "$1"`,
                            "sh", recFile, `${m.x + t.x},${m.y + t.y} ${t.w}x${t.h}`]
        recorder.running = true
        recStart = new Date()
        recording = true
    }
    function stopRecording() { recorder.signal(2) }    // SIGINT: wf-recorder closes the file properly
    Process {
        id: recorder
        onExited: {
            root.recording = false
            Quickshell.execDetached(["unia-shot-notify", root.recFile, "video"])
        }
    }
    Process {
        id: recorderCheck
        property bool found: false
        running: true
        command: ["sh", "-c", "command -v wf-recorder"]
        onExited: code => found = code === 0
    }
    function recheck() { recorderCheck.running = true }
}
