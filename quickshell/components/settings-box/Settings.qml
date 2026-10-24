pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "../../services"

// Settings: the special workspace special:settings, the category panel on the left, the app on the right.
// A click on a category shows its app (launching it if needed) and hides the previous one in special:unia-stash.
Singleton {
    id: root

    readonly property var tabs: [
        { id: "main", label: "General" },
        { id: "custom", label: "Personalize" },
        { id: "devices", label: "Devices" },
    ]
    // kind "app": an existing app (classes: its window classes; empty means the first new window),
    // kind "own": the shell's own page
    readonly property var items: [
        { id: "net", tab: "main", label: "Network", icon: "wifi", kind: "app", tool: "Network editor", cmd: ["nm-connection-editor"], classes: ["nm-connection-editor"] },
        { id: "bt", tab: "main", label: "Bluetooth", icon: "bluetooth", kind: "app", tool: "Overskride", cmd: ["flatpak", "run", "io.github.kaii_lb.Overskride"], classes: ["io.github.kaii_lb.overskride"] },
        { id: "time", tab: "main", label: "Date & Time", icon: "schedule", kind: "own", what: "Time zone, time sync, 24-hour clock" },
        { id: "sound", tab: "main", label: "Sound", icon: "volume_up", kind: "app", tool: "pavucontrol", cmd: ["pavucontrol"], classes: ["pavucontrol", "org.pulseaudio.pavucontrol"] },
        { id: "display", tab: "main", label: "Displays", icon: "monitor", kind: "app", tool: "nwg-displays", cmd: ["nwg-displays"], classes: ["nwg-displays"] },
        { id: "layout", tab: "main", label: "Keyboard Layout", icon: "keyboard", kind: "own", what: "Languages and the layout switch key" },
        { id: "wall", tab: "custom", label: "Wallpaper", icon: "wallpaper", kind: "app", tool: "Waypaper", cmd: ["waypaper"], classes: ["waypaper"] },
        { id: "colors", tab: "custom", label: "App Theme", icon: "palette", kind: "app", tool: "nwg-look", cmd: ["nwg-look"], classes: ["nwg-look"] },
        { id: "theme", tab: "custom", label: "Theme", icon: "format_paint", kind: "own", what: "Main and secondary colours, window opacity, blur" },
        { id: "borders", tab: "custom", label: "Windows & Borders", icon: "border_style", kind: "own", what: "Gaps between windows, borders, rounding" },
        { id: "mouse", tab: "devices", label: "Mouse", icon: "mouse", kind: "own", what: "Speed, acceleration, natural scrolling, left-handed mode" },
        { id: "kb-layout", tab: "devices", parent: "keyboard", label: "Language & Layout", icon: "keyboard", kind: "own", what: "Languages and the layout switch key" },
        { id: "kb-rgb", tab: "devices", parent: "keyboard", label: "Backlight", icon: "keyboard", kind: "app", tool: "OpenRGB", cmd: ["openrgb"], classes: ["openrgb", "org.openrgb.openrgb"] },
        { id: "printers", tab: "devices", label: "Printers", icon: "print", kind: "app", tool: "system-config-printer", cmd: ["system-config-printer"], classes: ["system-config-printer"] },
        { id: "tablet", tab: "devices", label: "Drawing Tablet", icon: "draw", kind: "app", tool: "OpenTabletDriver", cmd: ["otd-gui"], classes: ["opentabletdriver.ux"] },
    ]
    readonly property var groups: ({ keyboard: { label: "Keyboard", icon: "keyboard" } })

    property string tab: "main"
    property string sel: "net"
    readonly property var current: find(sel)
    property bool shown: false                 // the settings special workspace is visible now
    property string monitorName: ""           // which monitor shows it
    property var addrs: ({})                   // id → address of the app's window
    property var pending: null                 // { id, classes, until }: waiting for a new window
    readonly property var pins: Prefs.data.pins ?? []      // pinned to the control centre (up to 6)

    function find(id) { return items.find(i => i.id === id) ?? null }

    // ---------- open / close ----------
    function toggle() {
        if (!shown && panelGone) { restorePanel(); return }
        Hyprland.dispatch("togglespecialworkspace settings")
    }
    function open(id) {
        if (id) select(id)
        if (!shown) toggle()
    }
    function close() { if (shown) toggle() }

    // the panel was closed from outside (Super+C): do not recreate it at once (a new window would show Settings again),
    // only on the next opening; a window appearing on the special workspace reveals it by itself
    property bool panelGone: false
    signal panelRestoreRequested()
    function restorePanel() {
        panelGone = false
        panelRestoreRequested()
        ensureShown.restart()
    }
    Timer { id: ensureShown; interval: 400; onTriggered: if (!root.shown) Hyprland.dispatch("togglespecialworkspace settings") }

    // ---------- geometry: the panel is 304 px on the left, the app takes the rest ----------
    readonly property int panelW: 304
    function area() {
        const m = Hyprland.monitors.values.find(m => m.name === monitorName) ?? Hyprland.focusedMonitor
        if (!m) return null
        const w = m.width / m.scale, h = m.height / m.scale
        const top = 72, side = 20, bottom = 20
        return { x: m.x + side, y: m.y + top, h: h - top - bottom,
                 toolX: m.x + side + panelW + 10, toolW: w - 2 * side - panelW - 10 }
    }
    // whether a window matches the selector: for a missing window Hyprland applies movetoworkspace/setfloating
    // to the ACTIVE window, which once pulled the browser into Settings
    function exists(sel) {
        const ts = Hyprland.toplevels.values
        if (sel.startsWith("address:")) {
            const a = sel.slice(8).replace(/^0x/, "")
            return ts.some(t => t.address.replace(/^0x/, "") === a)
        }
        const re = new RegExp(sel.replace(/^title:/, ""))
        return ts.some(t => re.test(t.title))
    }
    function place(sel, x, y, w, h) {
        if (!exists(sel)) return
        Hyprland.dispatch(`movetoworkspacesilent special:settings,${sel}`)
        Hyprland.dispatch(`setfloating ${sel}`)
        Hyprland.dispatch(`resizewindowpixel exact ${Math.round(w)} ${Math.round(h)},${sel}`)
        Hyprland.dispatch(`movewindowpixel exact ${Math.round(x)} ${Math.round(y)},${sel}`)
    }
    // refocus: give the keyboard back to the panel (on opening, on choosing a category); not on a plain relayout
    // (Hyprland reloaded its config): focuswindow also warps the cursor to the middle of the panel
    function layout(refocus) {
        const a = area()
        if (!a) return
        place("title:^(Unia · Settings)$", a.x, a.y, panelW, a.h)
        const it = current
        if (!it) return
        if (it.kind === "own") place("title:^(Unia · Page)$", a.toolX, a.y, a.toolW, a.h)
        else if (addrs[it.id]) place(`address:${addrs[it.id]}`, a.toolX, a.y, a.toolW, a.h)
        // focus only while Settings is open: focusing a window on a hidden special workspace reveals it
        // (that is how Settings used to pop up on every shell start, when the panel window appeared)
        if (!shown || refocus === false) return
        focusPanel()        // the keyboard stays in the panel: Tab goes to the app
        refocus.restart()   // a freshly opened app window takes focus: give it back to the panel
    }
    Timer { id: refocus; interval: 350; onTriggered: if (root.shown) root.focusPanel() }

    // ---------- keyboard focus: panel ↔ the app on the right ----------
    signal pageFocusRequested()        // tells a built-in page to focus its first control
    function focusPanel() { Hyprland.dispatch("focuswindow title:^(Unia · Settings)$") }
    function focusTool() {
        const it = current
        if (!it) return
        if (it.kind === "own") { Hyprland.dispatch("focuswindow title:^(Unia · Page)$"); pageFocusRequested() }
        else if (addrs[it.id]) Hyprland.dispatch(`focuswindow address:${addrs[it.id]}`)
    }

    // ---------- choosing a category ----------
    function select(id) {
        const it = find(id)
        if (!it) return
        const prev = current
        if (prev && prev.id !== id && prev.kind === "app" && addrs[prev.id] && exists(`address:${addrs[prev.id]}`))
            Hyprland.dispatch(`movetoworkspacesilent special:unia-stash,address:${addrs[prev.id]}`)
        sel = id
        tab = it.tab
        if (it.kind === "app" && !addrs[id]) adoptOrLaunch(it)
        layout()
    }

    function adoptOrLaunch(it) {
        // already open elsewhere? take its window
        const c = clients.find(c => it.classes.includes(c.class.toLowerCase()))
        if (c) { setAddr(it.id, c.address.replace(/^0x/, "")); return }
        pending = { id: it.id, classes: it.classes, until: Date.now() + 30000 }
        Quickshell.execDetached(it.cmd)
    }
    function setAddr(id, a) {
        const m = Object.assign({}, addrs)
        m[id] = "0x" + a
        addrs = m
    }

    // ---------- pinning to the control centre ----------
    function togglePin(id) {
        Prefs.set("pins", pins.includes(id) ? pins.filter(x => x !== id) : [...pins, id].slice(0, 6))
    }

    // ---------- Hyprland state ----------
    property var clients: []                   // [{ address, class }]: refreshed through hyprctl
    Process {
        id: clientsProc
        command: ["hyprctl", "clients", "-j"]
        stdout: StdioCollector { onStreamFinished: { try { root.clients = JSON.parse(text) } catch (e) {} } }
    }
    Component.onCompleted: clientsProc.running = true

    Connections {
        target: Hyprland
        function onRawEvent(ev) {
            // Hyprland reloaded its config (e.g. Apply in nwg-displays) or monitors changed:
            // window rules may have moved the app under the panel, so lay things out again
            if (["configreloaded", "monitoradded", "monitorremoved"].includes(ev.name)) {
                if (root.shown) relayout.restart()
            } else if (ev.name === "activespecial") {
                const [ws, mon] = ev.data.split(",")
                root.shown = ws === "special:settings"
                if (root.shown) { root.monitorName = mon; root.layout() }
            } else if (ev.name === "openwindow") {
                const [addr, ws, cls, ...t] = ev.data.split(",")
                clientsProc.running = true
                // our own windows (panel, page) appear after select(): lay out once more
                if (t.join(",").startsWith("Unia · ")) { root.layout(); return }
                const p = root.pending
                // recognise the app's window by class; the fallback is the first new window on the special workspace
                if (p && Date.now() < p.until && (p.classes.includes(cls.toLowerCase()) || ws === "special:settings" && !cls.startsWith("org.quickshell"))) {
                    root.pending = null
                    root.setAddr(p.id, addr)
                    if (root.sel === p.id) root.layout()
                    else Hyprland.dispatch(`movetoworkspacesilent special:unia-stash,address:0x${addr}`)
                }
            } else if (ev.name === "closewindow") {
                const a = "0x" + ev.data
                const m = Object.assign({}, root.addrs)
                for (const k in m) if (m[k] === a) delete m[k]
                root.addrs = m
                clientsProc.running = true
            }
        }
    }

    Timer { id: relayout; interval: 400; onTriggered: root.layout(false) }

}
