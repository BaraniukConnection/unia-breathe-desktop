import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Hyprland
import "../../theme"

// WindowDrop одного монітора: прозорий шар над вікнами. Курсор він ловить лише на «гачках» —
// смужках посередині верхньої рамки видимих вікон; там з'являється краплина (Droplet).
// Затиснути краплину й тягнути — вікно стає квадратом і їде за курсором; клік — меню (DropMenu).
PanelWindow {
    id: win
    required property var modelData
    screen: modelData
    readonly property var mon: Drops.monitors.find(m => m.name === modelData.name) ?? null
    readonly property real ox: mon ? mon.x : 0
    readonly property real oy: mon ? mon.y : 0

    WlrLayershell.namespace: "unia-drop"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: here && Drops.busy ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"

    // ---------- гачки: { address, x, y, w, h } у координатах монітора ----------
    // присвоюємо лише коли справді змінились — інакше маска смикається й наведення скидається
    property var zones: []
    property string zonesKey: ""
    function updateZones() {
        const wins = Drops.visibleOn(mon)
        const z = []
        wins.forEach((c, i) => {
            const cx = c.at[0] + c.size[0] / 2, top = c.at[1]
            // середину рамки перекриває вікно вище — гачка немає
            if (wins.slice(i + 1).some(o => cx >= o.at[0] && cx <= o.at[0] + o.size[0] && top >= o.at[1] - 8 && top <= o.at[1] + o.size[1])) return
            const w = Math.round(Math.min(160, c.size[0] * 0.4))
            z.push({ address: c.address, x: Math.round(cx - ox - w / 2), y: Math.round(top - oy - 10), w: w, h: 16 })
        })
        const k = JSON.stringify(z)
        if (k !== zonesKey) { zonesKey = k; zones = z }
    }
    Connections { target: Drops; function onClientsChanged() { win.updateZones() } }
    onMonChanged: updateZones()

    mask: Region {
        item: Drops.busy ? base : null
        regions: Drops.busy ? [] : [...zoneRegions.instances, ...(win.here ? [dropRegion] : [])]
    }
    Variants {
        id: zoneRegions
        model: win.zones
        Region {
            required property var modelData
            x: modelData.x; y: modelData.y; width: modelData.w; height: modelData.h
        }
    }
    Region { id: dropRegion; item: holder }

    // ---------- вікно з краплею ----------
    readonly property var dc: Drops.client(Drops.current)
    readonly property bool here: !!dc && !!mon && (Drops.drag ? Drops.drag.mon === mon.id : dc.monitor === mon.id)
    // точка на рамці: посередині верхнього краю, у товщі рамки; коли вікна з краплею вже немає
    // (меню закривається, краплина ховається), лишається остання — анімація не стрибає в кут
    property real ax: 0
    property real ay: 0
    Binding {
        when: !!win.dc
        win.ax: !win.dc ? win.ax : Drops.drag ? Drops.drag.rect.x + Drops.drag.rect.w / 2 - win.ox : win.dc.at[0] + win.dc.size[0] / 2 - win.ox
        win.ay: !win.dc ? win.ay : (Drops.drag ? Drops.drag.rect.y : win.dc.at[1]) - win.oy - Drops.border / 2
        restoreMode: Binding.RestoreNone
    }

    // курсор на гачку (кожен монітор прибирає лише те наведення, яке поставив сам)
    property string mine: ""
    MouseArea {
        id: base
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.AllButtons
        onPositionChanged: m => {
            if (Drops.busy) return
            const z = win.zones.find(z => m.x >= z.x && m.x < z.x + z.w && m.y >= z.y && m.y < z.y + z.h)
            if (z) { leave.stop(); win.mine = z.address; Drops.hovered = z.address }
        }
        onContainsMouseChanged: if (!containsMouse) leave.restart()
        onClicked: if (Drops.menuFor) Drops.closeMenu()           // клік повз меню — закрити
    }
    Timer {
        id: leave
        interval: 350
        onTriggered: {
            if (Drops.busy || base.containsMouse || dropArea.containsMouse) return
            if (win.mine && Drops.hovered === win.mine) Drops.hovered = ""
            win.mine = ""
        }
    }

    // ---------- краплина ----------
    property real grow: 0
    readonly property bool wanted: here && !Drops.drag
    onWantedChanged: { growAnim.to = wanted ? 1 : 0; growAnim.duration = wanted ? 280 : 160; growAnim.easing.type = wanted ? Easing.OutBack : Easing.InCubic; growAnim.restart() }
    NumberAnimation { id: growAnim; target: win; property: "grow" }

    Item {
        id: holder
        visible: win.here && (win.grow > 0 || !!Drops.drag)
        x: win.ax - width / 2
        y: win.ay
        width: 40
        height: 44
        Droplet {
            anchors.fill: parent
            grow: win.grow
            neck: 1 - menu.detach
            fall: menu.detach * 10
            opacity: Drops.drag ? 0 : 1 - Math.min(1, menu.grow1 * 2)
        }
        MouseArea {
            id: dropArea
            anchors.fill: parent
            hoverEnabled: true
            enabled: !Drops.menuFor
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: Drops.drag ? Qt.ClosedHandCursor : Qt.OpenHandCursor
            property point press
            onContainsMouseChanged: containsMouse ? leave.stop() : leave.restart()
            onPressed: m => {
                if (m.button === Qt.RightButton) { if (Drops.drag) Drops.cancelDrag(); return }
                press = Qt.point(m.x, m.y)
            }
            onPositionChanged: m => {
                if (!pressed || !(pressedButtons & Qt.LeftButton)) return
                const p = mapToItem(base, m.x, m.y)
                if (!Drops.drag && Math.hypot(m.x - press.x, m.y - press.y) > 6) Drops.startDrag(Drops.hovered, p.x + win.ox, p.y + win.oy)
                else if (Drops.drag) Drops.moveDrag(p.x + win.ox, p.y + win.oy)
            }
            onReleased: m => {
                if (m.button !== Qt.LeftButton) return
                if (Drops.drag) Drops.endDrag()
                else Drops.openMenu(Drops.hovered)
            }
        }
        Keys.onEscapePressed: if (Drops.drag) Drops.cancelDrag()
    }

    DropMenu {
        id: menu
        x: win.ax
        y: win.ay
        client: win.dc
        open: win.here && Drops.menuFor !== "" && Drops.menuFor === Drops.current
        // не вилізти за край екрана
        shift: { const half = Math.max(w1, w2) / 2 + 12; return Math.max(half - win.ax, Math.min(0, win.width - half - win.ax)) }
    }

    // ---------- вікно, яке тягнемо: квадрат із заокругленими кутами під курсором ----------
    // кадр вікна знімаємо ще при наведенні: поки тягнемо, саме вікно сховане
    readonly property string shotAddress: Drops.drag ? Drops.drag.address : Drops.hovered
    readonly property var toplevel: Hyprland.toplevels.values.find(t => "0x" + t.address.replace(/^0x/, "") === shotAddress) ?? null
    onToplevelChanged: if (toplevel && !Drops.drag) Qt.callLater(() => shot.captureFrame())

    Item {
        id: ghost
        property var r0: ({ x: 0, y: 0, w: 1, h: 1 })
        property real t: 0
        readonly property real side: Math.max(150, Math.min(260, Math.min(r0.w, r0.h) * 0.45))
        x: win.lerp(r0.x - win.ox, Drops.dragX - win.ox - side / 2, t)
        y: win.lerp(r0.y - win.oy, Drops.dragY - win.oy - 12, t)
        width: win.lerp(r0.w, side, t)
        height: win.lerp(r0.h, side, t)
        opacity: Drops.drag ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 180 } }

        ClippingRectangle {
            anchors.fill: parent
            radius: win.lerp(14, 32, ghost.t)
            color: Theme.glassStrong
            ScreencopyView {
                id: shot
                captureSource: win.toplevel ? win.toplevel.wayland : null
                live: false
                // заповнити квадрат, зберігши пропорції (обрізаючи зайве)
                readonly property real k: sourceSize.width > 0 ? Math.max(ghost.width / sourceSize.width, ghost.height / sourceSize.height) : 1
                width: sourceSize.width * k
                height: sourceSize.height * k
                anchors.centerIn: parent
            }
            IconImage {
                anchors.centerIn: parent
                visible: !shot.hasContent
                implicitSize: 64
                source: win.dc ? Quickshell.iconPath(DesktopEntries.heuristicLookup(win.dc.class)?.icon ?? win.dc.class.toLowerCase(), "application-x-executable") : ""
            }
        }
        Rectangle {
            anchors.fill: parent
            radius: win.lerp(14, 32, ghost.t)
            color: "transparent"
            border.width: 2
            border.color: Theme.accent
        }
        Droplet {                                   // краплина, за яку тримаємо
            anchors.horizontalCenter: parent.horizontalCenter
            y: -1
            width: 40; height: 44
        }
    }
    NumberAnimation { id: shrink; target: ghost; property: "t"; from: 0; to: 1; duration: 260; easing.type: Easing.OutCubic }
    Connections {
        target: Drops
        function onDragChanged() {
            if (!Drops.drag) return
            ghost.r0 = Drops.drag.rect
            shrink.restart()
            holder.forceActiveFocus()
        }
    }

    function lerp(a, b, t) { return a + (b - a) * t }
}
