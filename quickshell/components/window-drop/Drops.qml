pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "../../services"

// WindowDrop: виїмка-«крапля» посередині верхньої рамки вікна (як виріз під фронтальну камеру).
// Наближення курсора — виїмка росте з рамки; затиснути й тягнути — вікно стискається в квадрат
// і їде за курсором; клік — меню вікна.
// Тут стан і дії; малює кожен монітор свій шар (WindowDrop.qml).
Singleton {
    id: root
    readonly property string dragWs: Windows.dragWs      // де вікно чекає, поки його тягнуть
    // службові столи, на вікнах яких виїмки немає
    readonly property var skipWs: ["special:settings", "special:unia-stash", Windows.minimizedWs, Windows.dragWs]

    property var clients: []
    property var monitors: []
    property int border: 1                    // general:border_size

    property string hovered: ""               // адреса вікна, на рамці якого курсор
    property string menuFor: ""               // адреса вікна з відкритим меню
    property var drag: null                   // { address, floating, wsId, rect, mon } — поки тягнемо
    property real dragX: 0                    // курсор під час перетягування (глобальні координати)
    property real dragY: 0
    readonly property bool busy: menuFor !== "" || drag !== null
    readonly property string current: drag ? drag.address : menuFor || hovered   // вікно з виїмкою

    function client(a) { return clients.find(c => c.address === a) ?? null }
    // товщина рамки вікна: у повноекранного (не просто розгорнутого) рамки немає — виїмка росте з краю екрана
    function bandOf(c) { return c && c.fullscreen >= 2 ? 0 : border }
    function monitorAt(x, y) {
        return monitors.find(m => x >= m.x && x < m.x + m.width / m.scale && y >= m.y && y < m.y + m.height / m.scale) ?? null
    }

    // вікна, які видно на моніторі, знизу вгору: спершу розкладені, потім плаваючі; давніший фокус — нижче.
    // Є повноекранне вікно — видно лише його (решта під ним).
    function visibleOn(m) {
        if (!m) return []
        const ws = m.specialWorkspace.name || m.activeWorkspace.name
        if (skipWs.includes(ws)) return []
        const list = clients.filter(c => c.mapped && !c.hidden && c.workspace.name === ws && c.class !== "org.quickshell")
        const full = list.filter(c => c.fullscreen).sort((a, b) => a.focusHistoryID - b.focusHistoryID)
        if (full.length) return [full[0]]
        return list.sort((a, b) => (a.floating - b.floating) || (b.focusHistoryID - a.focusHistoryID))
    }
    // верхнє вікно під точкою (крім указаного)
    function windowAt(m, x, y, except) {
        const ws = visibleOn(m).filter(c => c.address !== except)
        for (let i = ws.length - 1; i >= 0; i--) {
            const c = ws[i]
            if (x >= c.at[0] && x < c.at[0] + c.size[0] && y >= c.at[1] && y < c.at[1] + c.size[1]) return c
        }
        return null
    }

    // ---------- стан Hyprland: вікна, монітори, товщина рамки ----------
    // подій про зміну розмірів Hyprland не шле, тож, крім подій, перечитуємо раз на 0,7 с
    Process {
        id: poll
        command: ["hyprctl", "--batch", "j/clients;j/monitors;j/getoption general:border_size"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const [c, m, b] = text.split(/\n\n\n/).map(s => JSON.parse(s))
                    root.clients = c
                    root.monitors = m
                    root.border = b.int ?? 1
                } catch (e) {}
                if (root.menuFor && !root.client(root.menuFor)) root.closeMenu()
            }
        }
    }
    function refresh() { if (!poll.running) poll.running = true }
    Timer { interval: 700; running: true; repeat: true; onTriggered: root.refresh() }
    Timer { id: soon; interval: 60; onTriggered: root.refresh() }
    Connections {
        target: Hyprland
        function onRawEvent(ev) {
            if (["openwindow", "closewindow", "movewindowv2", "changefloatingmode", "fullscreen", "workspacev2",
                 "activespecial", "focusedmonv2", "activewindowv2", "monitoraddedv2", "monitorremoved", "configreloaded"].includes(ev.name))
                soon.restart()
        }
    }
    Component.onCompleted: refresh()

    // ---------- наведення ----------
    // з нульовою (чи 1 px) рамкою виїмці нема з чого рости — поки вона є, рамка вікна 3 px
    property string thick: ""
    onCurrentChanged: {
        if (thick && thick !== current) { Hyprland.dispatch(`setprop address:${thick} border_size unset`); thick = "" }
        if (current && border < 2 && client(current) && !client(current).fullscreen) { Hyprland.dispatch(`setprop address:${current} border_size 3`); thick = current }
    }

    // ---------- меню ----------
    function openMenu(a) { hovered = a; menuFor = a }
    function closeMenu() { menuFor = ""; hovered = "" }    // курсор ще на гачку — наступний рух поверне виїмку
    function act(what) {
        const c = client(menuFor)
        closeMenu()
        if (!c) return
        const a = c.address
        if (what === "minimize")
            Windows.minimize({ address: a, wsId: c.workspace.id, wsName: c.workspace.name })
        else if (what === "fullscreen") {
            Hyprland.dispatch(`focuswindow address:${a}`)
            Hyprland.dispatch("fullscreen 0")
        } else if (what === "close")
            Hyprland.dispatch(`closewindow address:${a}`)
        soon.restart()
    }
    function moveTo(wsId) {
        const c = client(menuFor)
        closeMenu()
        if (c) Hyprland.dispatch(`movetoworkspacesilent ${wsId},address:${c.address}`)
        soon.restart()
    }

    // ---------- перетягування ----------
    function startDrag(a, x, y) {
        const c = client(a)
        if (!c) return
        dragX = x; dragY = y
        // повноекранне спершу повертаємо у звичайне — тягнути його як квадрат, а поставити звичайним вікном
        if (c.fullscreen) {
            Hyprland.dispatch(`focuswindow address:${a}`)
            Hyprland.dispatch("fullscreen 0")
        }
        drag = { address: a, floating: c.floating, wsId: c.workspace.id, mon: c.monitor,
                 rect: { x: c.at[0], y: c.at[1], w: c.size[0], h: c.size[1] } }
        // поки тягнемо, саме вікно чекає на схованому столі (у смузі — як згорнуте, сценарій його не втрачає)
        Windows.remember(a, c.workspace.id)
        Hyprland.dispatch(`movetoworkspacesilent ${dragWs},address:${a}`)
    }
    function moveDrag(x, y) { dragX = x; dragY = y }
    function endDrag() {
        const d = drag
        if (!d) return
        const m = monitorAt(dragX, dragY) ?? monitors.find(m => m.id === d.mon)
        drag = null
        if (!m) { cancel(d); return }
        const a = d.address, ws = m.activeWorkspace.id
        if (d.floating) {
            // плаваюче — туди, де відпустили: виїмка (верх посередині) під курсором
            const mw = m.width / m.scale, mh = m.height / m.scale
            const x = Math.round(Math.max(m.x, Math.min(dragX - d.rect.w / 2, m.x + mw - d.rect.w)))
            const y = Math.round(Math.max(m.y, Math.min(dragY - 8, m.y + mh - d.rect.h)))
            Hyprland.dispatch(`movetoworkspacesilent ${ws},address:${a}`)
            Hyprland.dispatch(`movewindowpixel exact ${x} ${y},address:${a}`)
        } else {
            // розкладене — поруч із вікном під курсором, з того боку, ближче до якого відпустили
            const t = windowAt(m, dragX, dragY, a)
            if (t && !t.floating) {
                const dx = (dragX - (t.at[0] + t.size[0] / 2)) / t.size[0]
                const dy = (dragY - (t.at[1] + t.size[1] / 2)) / t.size[1]
                Hyprland.dispatch(`focuswindow address:${t.address}`)
                Hyprland.dispatch(`layoutmsg preselect ${Math.abs(dx) > Math.abs(dy) ? (dx < 0 ? "l" : "r") : (dy < 0 ? "u" : "d")}`)
            }
            Hyprland.dispatch(`movetoworkspacesilent ${ws},address:${a}`)
        }
        Hyprland.dispatch(`focuswindow address:${a}`)
        hovered = ""
        soon.restart()
    }
    function cancelDrag() {
        const d = drag
        drag = null
        if (d) cancel(d)
    }
    function cancel(d) {
        Hyprland.dispatch(`movetoworkspacesilent ${d.wsId},address:${d.address}`)
        if (d.floating) Hyprland.dispatch(`movewindowpixel exact ${d.rect.x} ${d.rect.y},address:${d.address}`)
        hovered = ""
        soon.restart()
    }
}
