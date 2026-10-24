import QtQuick
import QtQuick.Shapes
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Hyprland
import "../../theme"

// WindowDrop одного монітора: прозорий шар над вікнами. Курсор він ловить лише на «гачках» —
// смугах посередині верхньої рамки видимих вікон. Там із рамки виростає виїмка (Notch): чим ближче курсор,
// тим глибша, на повну — з крапкою всередині. Затиснути й тягнути (чи Super+ЛКМ у вікні) — вікно стає квадратом
// і їде за курсором, а місце, куди стане, вже видно (DropPlace); клік — меню (DropMenu).
PanelWindow {
    id: win
    required property var modelData
    screen: modelData
    readonly property var mon: Drops.monitors.find(m => m.name === modelData.name) ?? null
    readonly property real ox: mon ? mon.x : 0
    readonly property real oy: mon ? mon.y : 0

    WlrLayershell.namespace: "unia-drop"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: (here || resizeHere) && Drops.busy ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"

    // ---------- гачки: { address, x, y, w, h, cx, cy } у координатах монітора ----------
    // смуга навколо середини верхньої рамки: 14 px над нею (проміжок між вікнами) і 12 px у вікні.
    // Присвоюємо лише коли справді змінились — інакше маска смикається й наведення скидається
    property var zones: []
    property string zonesKey: ""
    function updateZones() {
        const wins = Drops.visibleOn(mon)
        const z = []
        wins.forEach((c, i) => {
            const cx = c.at[0] + c.size[0] / 2, top = c.at[1]
            // середину рамки перекриває вікно вище — гачка немає
            if (wins.slice(i + 1).some(o => cx >= o.at[0] && cx <= o.at[0] + o.size[0] && top >= o.at[1] - 8 && top <= o.at[1] + o.size[1])) return
            const w = Math.round(Math.min(200, c.size[0] * 0.5))
            // біля верхнього краю екрана (повноекранне вікно) смуга лише всередині вікна
            const y0 = Math.max(0, Math.round(top - oy - 14)), y1 = Math.round(top - oy + 12)
            z.push({ address: c.address, x: Math.round(cx - ox - w / 2), y: y0, w: w, h: y1 - y0,
                     cx: cx - ox, cy: top - oy - Drops.bandOf(c) / 2 })
        })
        const k = JSON.stringify(z)
        if (k !== zonesKey) { zonesKey = k; zones = z }
    }
    Connections { target: Drops; function onClientsChanged() { win.updateZones() } }
    onMonChanged: updateZones()

    mask: Region {
        item: Drops.busy ? base : null
        regions: Drops.busy ? [] : [...zoneRegions.instances, ...(win.here ? [notchRegion] : [])]
    }
    Variants {
        id: zoneRegions
        model: win.zones
        Region {
            required property var modelData
            x: modelData.x; y: modelData.y; width: modelData.w; height: modelData.h
        }
    }
    Region { id: notchRegion; item: holder }

    // ---------- вікно з виїмкою ----------
    readonly property var dc: Drops.client(Drops.current)
    readonly property bool here: !!dc && !!mon && (Drops.drag ? Drops.drag.mon === mon.id : dc.monitor === mon.id)
    // точка на рамці: посередині верхнього краю, зовнішній край рамки; коли вікна вже немає
    // (меню закривається, виїмка ховається), лишається остання — анімація не стрибає в кут
    property real ax: 0
    property real ay: 0
    property real band: 3
    Binding {
        when: !!win.dc
        win.ax: !win.dc ? win.ax : Drops.drag ? Drops.drag.rect.x + Drops.drag.rect.w / 2 - win.ox : win.dc.at[0] + win.dc.size[0] / 2 - win.ox
        win.ay: !win.dc ? win.ay : (Drops.drag ? Drops.drag.rect.y : win.dc.at[1]) - win.oy - win.band
        restoreMode: Binding.RestoreNone
    }
    Binding { when: !!win.dc && !Drops.drag; win.band: Drops.bandOf(win.dc); restoreMode: Binding.RestoreNone }

    // ---------- наближення: чим ближче курсор до середини рамки, тим глибша виїмка ----------
    property real near: 0                         // 0…1, куди тягнеться глибина
    property real depth: here && !Drops.drag ? (Drops.menuFor ? 1 : near) : 0
    Behavior on depth { SmoothedAnimation { velocity: 5 } }
    property string mine: ""                      // наведення, яке поставив цей монітор
    function proximity(x, y) {
        if (holder.visible && x >= holder.x && x < holder.x + holder.width && y >= holder.y && y < holder.y + holder.height)
            return { address: Drops.hovered, near: 1 }
        const z = zones.find(z => x >= z.x && x < z.x + z.w && y >= z.y && y < z.y + z.h)
        if (!z) return null
        const dx = (x - z.cx) / (z.w / 2), dy = (y - z.cy) / (y < z.cy ? 14 : 12)
        return { address: z.address, near: Math.max(0, Math.min(1, (1 - Math.hypot(dx, dy)) / 0.65)) }
    }

    // увесь ввід шару: наведення, натиск/перетягування, клік повз меню
    MouseArea {
        id: base
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Drops.drag ? Qt.ClosedHandCursor
            : win.resizeHere && win.quad ? (win.quad === "lt" || win.quad === "rb" ? Qt.SizeFDiagCursor : Qt.SizeBDiagCursor)
            : win.near > 0.5 ? Qt.OpenHandCursor : Qt.ArrowCursor
        property point press
        property string pressed_: ""              // вікно, виїмку якого натиснули
        property bool menuWasOpen: false
        onPositionChanged: m => {
            if (Drops.resizing) {
                if (Drops.resizing.rect) { resizeTick.dx = m.x - press.x; resizeTick.dy = m.y - press.y; if (!resizeTick.running) resizeTick.start() }
                else win.quad = win.resizeHere ? win.quadAt(m.x, m.y) : ""
                return
            }
            if (pressed_ && (pressedButtons & Qt.LeftButton)) {
                // далі курсор і відпускання веде Drops (сокет Hyprland)
                if (!Drops.drag && Math.hypot(m.x - press.x, m.y - press.y) > 6) Drops.startDrag(pressed_, m.x + win.ox, m.y + win.oy)
                return
            }
            if (Drops.busy) return
            const p = win.proximity(m.x, m.y)
            if (p && p.near > 0) { leave.stop(); win.mine = p.address; Drops.hovered = p.address; win.near = p.near }
            else { win.near = 0; leave.restart() }
        }
        onContainsMouseChanged: if (!containsMouse && !Drops.busy) { win.near = 0; leave.restart() }
        onPressed: m => {
            if (Drops.resizing) {
                // у вікні — тягнути з цієї чверті; поза ним чи права кнопка — режим завершено
                const q = win.resizeHere && m.button === Qt.LeftButton ? win.quadAt(m.x, m.y) : ""
                if (!q) { Drops.stopResize(); return }
                win.quad = q
                press = Qt.point(m.x, m.y)
                Drops.beginResize(q, m.x + win.ox, m.y + win.oy)
                return
            }
            menuWasOpen = !!Drops.menuFor
            if (m.button === Qt.RightButton) { if (Drops.drag) Drops.cancelDrag(); return }
            // запасний шлях: перетягування не закінчилось відпусканням (Hyprland його не передав) — ставимо кліком
            if (Drops.drag) { Drops.endDrag(); return }
            pressed_ = !menuWasOpen && Drops.hovered && win.near > 0 ? Drops.hovered : ""
            press = Qt.point(m.x, m.y)
            if (pressed_) { win.near = 1; forceActiveFocus() }
        }
        onReleased: m => {
            if (Drops.resizing) { resizeTick.stop(); Drops.moveResize(m.x - press.x, m.y - press.y); Drops.endResize(); return }
            if (m.button !== Qt.LeftButton) return
            // кінець перетягування ловить Hyprland (drop release); тут лише клік — меню
            if (!Drops.drag && pressed_) Drops.openMenu(pressed_)
            pressed_ = ""
        }
        onClicked: if (menuWasOpen) Drops.closeMenu()     // клік повз меню — закрити
        Keys.onEscapePressed: { if (Drops.drag) Drops.cancelDrag(); else if (Drops.resizing) Drops.stopResize() }
        Keys.onReturnPressed: if (Drops.resizing) Drops.stopResize()
    }
    // зміну розміру шлемо не частіше ніж раз на кадр
    Timer {
        id: resizeTick
        property real dx: 0
        property real dy: 0
        interval: 16
        onTriggered: Drops.moveResize(dx, dy)
    }
    Timer {
        id: leave
        interval: 250
        onTriggered: {
            if (Drops.busy || win.near > 0) return
            if (win.mine && Drops.hovered === win.mine) Drops.hovered = ""
            win.mine = ""
        }
    }

    // ---------- виїмка ----------
    Item {
        id: holder
        visible: win.depth > 0.01 || (!!Drops.drag && win.here)
        x: win.ax - width / 2
        y: win.ay
        width: notch.implicitWidth
        height: notch.implicitHeight
        Notch {
            id: notch
            anchors.fill: parent
            band: win.band
            depth: win.depth * (1 - menu.detach)
            dotFall: menu.detach * 14
            dotOpacity: Drops.drag ? 0 : menu.shown ? 1 - Math.min(1, menu.grow1 * 2) : Math.max(0, Math.min(1, (win.depth - 0.75) / 0.25))
        }
    }

    DropMenu {
        id: menu
        x: win.ax
        y: win.ay
        band: win.band
        client: win.dc
        open: win.here && Drops.menuFor !== "" && Drops.menuFor === Drops.current
        // не вилізти за край екрана
        // «Стіл» стоїть у правій половині під панеллю й розкривається праворуч
        shift: {
            const l = w1 / 2 + 12
            const r = Math.max(w1 / 2, gap2 / 2 + deskOpenW) + 12
            return Math.max(l - win.ax, Math.min(0, win.width - r - win.ax))
        }
    }

    // ---------- вікно, яке тягнемо: квадрат із заокругленими кутами під курсором ----------
    // кадр вікна знімаємо ще при наведенні: поки тягнемо, саме вікно сховане
    readonly property string shotAddress: Drops.drag ? Drops.drag.address : Drops.hovered
    readonly property var toplevel: Hyprland.toplevels.values.find(t => "0x" + t.address.replace(/^0x/, "") === shotAddress) ?? null
    onToplevelChanged: if (toplevel && !Drops.drag) Qt.callLater(() => shot.captureFrame())

    // ---------- режим зміни розміру: вікно трохи розмите, пунктирний хрест ділить його на чверті ----------
    readonly property var rc: Drops.resizing ? Drops.client(Drops.resizing.address) : null
    readonly property bool resizeHere: !!rc && !!mon && rc.monitor === mon.id
    property string quad: ""                  // чверть під курсором: "lt", "rt", "lb", "rb"
    function quadAt(x, y) {
        if (!rc) return ""
        const rx = rc.at[0] - ox, ry = rc.at[1] - oy
        if (x < rx || y < ry || x >= rx + rc.size[0] || y >= ry + rc.size[1]) return ""
        return (x < rx + rc.size[0] / 2 ? "l" : "r") + (y < ry + rc.size[1] / 2 ? "t" : "b")
    }
    onResizeHereChanged: { quad = ""; if (resizeHere) base.forceActiveFocus() }
    readonly property var resizeTop: rc ? Hyprland.toplevels.values.find(t => "0x" + t.address.replace(/^0x/, "") === rc.address) ?? null : null

    Item {
        id: resizeView
        visible: win.resizeHere
        x: win.rc ? win.rc.at[0] - win.ox : 0
        y: win.rc ? win.rc.at[1] - win.oy : 0
        width: win.rc ? win.rc.size[0] : 0
        height: win.rc ? win.rc.size[1] : 0

        // жива копія вікна, розмита не повністю
        ClippingRectangle {
            anchors.fill: parent
            radius: 14
            color: "transparent"
            ScreencopyView {
                id: live
                anchors.fill: parent
                captureSource: win.resizeHere && win.resizeTop ? win.resizeTop.wayland : null
                live: true
                layer.enabled: true
                layer.effect: MultiEffect { blurEnabled: Theme.blur; blur: 0.15; blurMax: 64 }
            }
            Rectangle { anchors.fill: parent; color: Qt.rgba(Theme.base.r, Theme.base.g, Theme.base.b, 0.15) }
        }
        // чверть під курсором
        Rectangle {
            visible: win.quad !== ""
            x: win.quad[0] === "r" ? parent.width / 2 : 0
            y: win.quad[1] === "b" ? parent.height / 2 : 0
            width: parent.width / 2
            height: parent.height / 2
            color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.12)
        }
        // пунктир: хрест і рамка
        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                strokeColor: Qt.rgba(1, 1, 1, 0.7)
                strokeWidth: 2
                strokeStyle: ShapePath.DashLine
                dashPattern: [4, 4]
                fillColor: "transparent"
                startX: resizeView.width / 2; startY: 0
                PathLine { x: resizeView.width / 2; y: resizeView.height }
                PathMove { x: 0; y: resizeView.height / 2 }
                PathLine { x: resizeView.width; y: resizeView.height / 2 }
            }
            ShapePath {
                strokeColor: Theme.accent
                strokeWidth: 2
                strokeStyle: ShapePath.DashLine
                dashPattern: [4, 4]
                fillColor: "transparent"
                startX: 1; startY: 1
                PathLine { x: resizeView.width - 1; y: 1 }
                PathLine { x: resizeView.width - 1; y: resizeView.height - 1 }
                PathLine { x: 1; y: resizeView.height - 1 }
                PathLine { x: 1; y: 1 }
            }
        }
        // стрілки: куди рухаються сторони з кожної чверті
        Repeater {
            model: [{ q: "lt", icon: "north_west" }, { q: "rt", icon: "north_east" }, { q: "lb", icon: "south_west" }, { q: "rb", icon: "south_east" }]
            Rectangle {
                required property var modelData
                readonly property bool on: win.quad === modelData.q
                width: 48; height: 48; radius: 24
                x: (modelData.q[0] === "l" ? 0.25 : 0.75) * resizeView.width - 24
                y: (modelData.q[1] === "t" ? 0.25 : 0.75) * resizeView.height - 24
                color: on ? Theme.accent : Theme.glassStrong
                border.width: 1
                border.color: Theme.paneLine
                opacity: on ? 1 : 0.7
                Icon { anchors.centerIn: parent; name: parent.modelData.icon; font.pixelSize: 26; color: parent.on ? Theme.accentInk : Theme.ink }
            }
        }
        // підказка посередині
        Rectangle {
            anchors.centerIn: parent
            width: hint.implicitWidth + 28
            height: 34
            radius: 17
            color: Theme.glassStrong
            border.width: 1
            border.color: Theme.paneLine
            Label { id: hint; anchors.centerIn: parent; text: "Тягніть із чверті — зміниться розмір · Esc — готово"; size: 12 }
        }
    }

    // плаваюче вікно нікого не розсуває — його місце малюємо самі: напівпрозоре порожнє вікно там, де стане
    Rectangle {
        readonly property var d: Drops.drag
        visible: !!d && d.floating
        x: d ? Drops.dragX - d.offX - win.ox : 0
        y: d ? Drops.dragY - d.offY - win.oy : 0
        width: d ? d.rect.w : 0
        height: d ? d.rect.h : 0
        radius: 14
        color: Theme.glass
        border.width: 2
        border.color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.8)
    }

    Item {
        id: ghost
        property var r0: ({ x: 0, y: 0, w: 1, h: 1 })
        property real t: 0
        // де тримаємо: та сама точка квадрата, що й вікна (за виїмку — верх посередині)
        property real fx: 0.5
        property real fy: 0
        readonly property real side: Math.max(150, Math.min(260, Math.min(r0.w, r0.h) * 0.45))
        x: win.lerp(r0.x - win.ox, Drops.dragX - win.ox - fx * side, t)
        y: win.lerp(r0.y - win.oy, Drops.dragY - win.oy - Math.max(12, fy * side), t)
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
        Notch {                                     // виїмка, за яку тримаємо
            anchors.horizontalCenter: parent.horizontalCenter
            y: 0
            band: 2
        }
    }
    NumberAnimation { id: shrink; target: ghost; property: "t"; from: 0; to: 1; duration: 260; easing.type: Easing.OutCubic }
    Connections {
        target: Drops
        function onDragChanged() {
            if (!Drops.drag) return
            const d = Drops.drag
            ghost.r0 = d.rect
            ghost.fx = d.offX / d.rect.w
            ghost.fy = d.offY / d.rect.h
            shrink.restart()
        }
    }

    function lerp(a, b, t) { return a + (b - a) * t }
}
