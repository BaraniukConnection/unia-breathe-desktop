pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland

// Open windows for the bar and app launching: go to a window, minimize, restore.
// Hyprland has no minimizing, so a minimized window lives on the hidden desk special:minimized.
Singleton {
    id: root
    readonly property string minimizedWs: "special:minimized"
    readonly property string dragWs: "special:unia-drop"       // the window being dragged by its drop (WindowDrop)
    property bool moving: false                                  // a window is being dragged: its desk is temporarily incomplete
    // the shell's service desks, whose windows are not listed
    readonly property var hiddenWs: ["special:settings", "special:unia-stash"]

    readonly property var list: Hyprland.toplevels.values
        .map(t => {
            const o = t.lastIpcObject
            if (!o || !o.class || o.class === "org.quickshell" || !o.workspace) return null
            const ws = o.workspace.name
            if (root.hiddenWs.includes(ws)) return null
            return {
                address: o.address, cls: o.class, title: o.title,
                wsId: o.workspace.id ?? 0, wsName: ws,          // special desks have no id since Hyprland 0.57
                minimized: ws === root.minimizedWs || ws === root.dragWs,
                active: t.activated,
                entry: DesktopEntries.heuristicLookup(o.class),
            }
        })
        .filter(w => w)
        .sort((a, b) => (a.minimized - b.minimized) || (a.wsId - b.wsId) || a.address.localeCompare(b.address))

    function label(w) {
        const name = w.entry ? w.entry.name : w.cls
        return w.minimized ? `${name} · minimized` : `${name} · Desk ${w.wsId > 0 ? w.wsId : w.wsName.replace(/^name:/, "")}`
    }
    function icon(w) {
        return Quickshell.iconPath(w.entry ? w.entry.icon : w.cls.toLowerCase(), "application-x-executable")
    }

    // where a window was minimized from: address → desk (to restore it there, as in Ubuntu)
    property var origin: ({})

    // go to a window; a minimized one first goes back to its desk (or the current one if unknown)
    function focus(w) {
        if (w.minimized) {
            const m = Hyprland.focusedMonitor
            const ws = origin[w.address] ?? (m && m.activeWorkspace ? m.activeWorkspace.id : 1)
            Hypr.moveToWorkspace(`address:${w.address}`, ws)
        }
        Hypr.focusWindow(`address:${w.address}`)
    }
    function remember(address, ws) {
        const o = Object.assign({}, origin)
        o[address] = ws
        origin = o
    }
    function minimize(w) {
        remember(w.address, w.wsId > 0 ? w.wsId : w.wsName)
        Hypr.moveToWorkspace(`address:${w.address}`, minimizedWs)
    }
    function close(w) { Hypr.close(`address:${w.address}`) }

    // an app's windows from its .desktop entry (by StartupWMClass, id or Quickshell's heuristics)
    function ofEntry(e) {
        if (!e || !e.id) return []
        return list.filter(w => {
            const c = w.cls.toLowerCase()
            return (e.startupClass && e.startupClass.toLowerCase() === c) || e.id.toLowerCase() === c
                || (w.entry && w.entry.id === e.id)
        })
    }

    // window classes (lastIpcObject) update only on request, so ask after window changes
    Connections {
        target: Hyprland
        function onRawEvent(ev) {
            if (["openwindow", "closewindow", "movewindowv2", "windowtitlev2", "activewindowv2"].includes(ev.name)) refresh.restart()
        }
    }
    Timer { id: refresh; interval: 150; onTriggered: Hyprland.refreshToplevels() }
    Component.onCompleted: Hyprland.refreshToplevels()
}
