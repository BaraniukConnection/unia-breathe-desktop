pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland

// Відкриті вікна для смуги й запуску програм: перейти до вікна, згорнути, розгорнути.
// Hyprland не має «згортання», тож згорнуте вікно живе на схованому столі special:minimized.
Singleton {
    id: root
    readonly property string minimizedWs: "special:minimized"
    // службові столи оболонки, вікна з яких не показуємо
    readonly property var hiddenWs: ["special:settings", "special:unia-stash"]

    readonly property var list: Hyprland.toplevels.values
        .map(t => {
            const o = t.lastIpcObject
            if (!o || !o.class || o.class === "org.quickshell" || !o.workspace) return null
            const ws = o.workspace.name
            if (root.hiddenWs.includes(ws)) return null
            return {
                address: o.address, cls: o.class, title: o.title,
                wsId: o.workspace.id, wsName: ws,
                minimized: ws === root.minimizedWs,
                active: t.activated,
                entry: DesktopEntries.heuristicLookup(o.class),
            }
        })
        .filter(w => w)
        .sort((a, b) => (a.minimized - b.minimized) || (a.wsId - b.wsId) || a.address.localeCompare(b.address))

    function label(w) {
        const name = w.entry ? w.entry.name : w.cls
        return w.minimized ? `${name} · згорнуто` : `${name} · Стіл ${w.wsId > 0 ? w.wsId : w.wsName.replace(/^name:/, "")}`
    }
    function icon(w) {
        return Quickshell.iconPath(w.entry ? w.entry.icon : w.cls.toLowerCase(), "application-x-executable")
    }

    // звідки вікно згорнули: адреса → стіл (щоб розгорнути туди ж, як в Ubuntu)
    property var origin: ({})

    // перейти до вікна; згорнуте — спершу повернути на його стіл (або на поточний, якщо невідомо)
    function focus(w) {
        if (w.minimized) {
            const m = Hyprland.focusedMonitor
            const ws = origin[w.address] ?? (m && m.activeWorkspace ? m.activeWorkspace.id : 1)
            Hyprland.dispatch(`movetoworkspacesilent ${ws},address:${w.address}`)
        }
        Hyprland.dispatch(`focuswindow address:${w.address}`)
    }
    function minimize(w) {
        const o = Object.assign({}, origin)
        o[w.address] = w.wsId > 0 ? w.wsId : w.wsName
        origin = o
        Hyprland.dispatch(`movetoworkspacesilent ${minimizedWs},address:${w.address}`)
    }
    function close(w) { Hyprland.dispatch(`closewindow address:${w.address}`) }

    // вікна програми з .desktop-запису (за StartupWMClass, id або евристикою Quickshell)
    function ofEntry(e) {
        if (!e || !e.id) return []
        return list.filter(w => {
            const c = w.cls.toLowerCase()
            return (e.startupClass && e.startupClass.toLowerCase() === c) || e.id.toLowerCase() === c
                || (w.entry && w.entry.id === e.id)
        })
    }

    // класи вікон (lastIpcObject) оновлюються лише на запит — просимо після змін вікон
    Connections {
        target: Hyprland
        function onRawEvent(ev) {
            if (["openwindow", "closewindow", "movewindowv2", "windowtitlev2", "activewindowv2"].includes(ev.name)) refresh.restart()
        }
    }
    Timer { id: refresh; interval: 150; onTriggered: Hyprland.refreshToplevels() }
    Component.onCompleted: Hyprland.refreshToplevels()
}
