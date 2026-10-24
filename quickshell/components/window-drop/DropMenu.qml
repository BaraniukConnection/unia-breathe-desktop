import QtQuick
import Quickshell.Hyprland
import "../../theme"

// Меню виїмки. Точка (0, 0) — середина рамки, зовнішній край. Відкриття: виїмка втягується в рамку, а крапка
// з неї падає (detach) і розтікається в панель дій (grow1); з-під неї стікають дві таблетки (grow2):
// посередині «Розмір» (клік — режим зміни розміру), праворуч «Стіл» (наведення — список столів, клік — наступний стіл).
Item {
    id: root
    property var client: null
    property bool open: false
    property real detach: 0
    property real grow1: 0
    property real grow2: 0
    property real shift: 0             // зсув панелей уздовж рамки, щоб не вилізти за край екрана
    property real band: 3              // товщина рамки
    readonly property real top1: band + 14
    readonly property real h1: 52
    readonly property real top2: top1 + h1 + 8
    readonly property real h2: 40

    // панель 1: дії
    readonly property var actions: [
        { act: "minimize", icon: "remove", tip: "Згорнути" },
        client && client.fullscreen
            ? { act: "fullscreen", icon: "close_fullscreen", tip: "Вийти з повного екрана" }
            : { act: "fullscreen", icon: "open_in_full", tip: "На весь екран" },
        client && client.floating
            ? { act: "float", icon: "grid_view", tip: "Повернути в сітку" }
            : { act: "float", icon: "picture_in_picture", tip: "Плаваюче вікно" },
        { act: "close", icon: "close", tip: "Закрити" },
    ]
    readonly property real w1: 16 + actions.length * 44 + (actions.length - 1) * 8
    property string tip: ""            // підказка під таблетками — що зробить кнопка під курсором

    // столи: усі звичайні, плюс новий (найменший вільний номер)
    readonly property var desks: {
        const ids = Hyprland.workspaces.values.map(w => w.id).filter(id => id > 0).sort((a, b) => a - b)
        let free = 1
        while (ids.includes(free)) free++
        return [...ids.map(id => ({ id: id, label: String(id) })), { id: free, label: "", fresh: true }]
    }
    // наступний стіл праворуч (клік по таблетці «Стіл»)
    readonly property int nextDesk: client ? Math.max(1, client.workspace.id + 1) : 1

    // розміри таблеток: згорнута — лише значок, розгорнута — з підписом / зі столами
    readonly property real pillW: 48
    readonly property real resizeOpenW: 132
    readonly property real deskOpenW: pillW + 4 + desks.length * 34 + (desks.length - 1) * 6 + 8
    readonly property real gap2: 8

    onOpenChanged: {
        if (open) { closing.stop(); detach = 0; grow1 = 0; grow2 = 0; tip = ""; opening.restart(); keys.forceActiveFocus() }
        else { opening.stop(); closing.restart() }
    }
    SequentialAnimation {
        id: opening
        NumberAnimation { target: root; property: "detach"; to: 1; duration: 150; easing.type: Easing.InQuad }
        NumberAnimation { target: root; property: "grow1"; to: 1; duration: 280; easing.type: Easing.OutBack; easing.overshoot: 1.2 }
        NumberAnimation { target: root; property: "grow2"; to: 1; duration: 320; easing.type: Easing.OutBack; easing.overshoot: 1.1 }
    }
    ParallelAnimation {
        id: closing
        NumberAnimation { target: root; properties: "grow1,grow2"; to: 0; duration: 150; easing.type: Easing.InCubic }
        NumberAnimation { target: root; property: "detach"; to: 0; duration: 150 }
    }
    readonly property bool shown: open || closing.running
    visible: shown

    function lerp(a, b, t) { return a + (b - a) * t }
    function fadeIn(t) { return Math.max(0, Math.min(1, (t - 0.55) / 0.45)) }

    Item {
        id: keys
        focus: root.open
        Keys.onEscapePressed: Drops.closeMenu()
    }

    // ---------- панель 1: згорнути, на весь екран, плаваюче, закрити ----------
    Item {
        id: p1
        readonly property real t: root.grow1
        width: root.lerp(7, root.w1, t)
        height: root.lerp(7, root.h1, Math.min(1, t))
        x: root.shift * t - width / 2
        y: root.lerp(root.band + 9 + 14 - 3.5, root.top1, t)   // з крапки, що випала з виїмки, — на своє місце
        visible: t > 0
        Glass {
            anchors.fill: parent
            strong: true
            radius: Math.min(width, height) / 2
        }
        Rectangle {                                         // ще крапка — біла, поки розтікається
            anchors.fill: parent
            radius: Math.min(width, height) / 2
            color: "white"
            opacity: 1 - Math.min(1, p1.t * 1.6)
        }
        Row {
            anchors.centerIn: parent
            spacing: 8
            opacity: root.fadeIn(p1.t)
            Repeater {
                model: root.actions
                Rectangle {
                    required property var modelData
                    width: 44; height: 40; radius: 20
                    color: area.containsMouse ? (modelData.act === "close" ? Theme.red : Theme.paneHover) : "transparent"
                    Icon { anchors.centerIn: parent; name: parent.modelData.icon; font.pixelSize: 22 }
                    MouseArea {
                        id: area
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onContainsMouseChanged: root.tip = containsMouse ? parent.modelData.tip : ""
                        onClicked: Drops.act(parent.modelData.act)
                    }
                }
            }
        }
    }

    // ---------- таблетки: «Розмір» посередині, «Стіл» праворуч ----------
    // стікають з-під панелі 1 крапкою; «Стіл» виїжджає з-під «Розміру»
    readonly property real t2: grow2
    readonly property real row2Y: lerp(top1 + h1 - 4, top2, Math.min(1, t2 * 1.4))

    Item {
        id: resizePill
        readonly property bool open: resizeHover.hovered && root.t2 > 0.9
        width: root.lerp(12, open ? root.resizeOpenW : root.pillW, root.t2)
        height: root.lerp(12, root.h2, Math.min(1, root.t2))
        x: root.shift * root.grow1 - width / 2
        y: root.row2Y
        visible: root.t2 > 0
        Behavior on width { enabled: root.t2 >= 1; NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Glass { anchors.fill: parent; strong: true; radius: height / 2 }
        Rectangle { anchors.fill: parent; radius: height / 2; color: Theme.accent; opacity: 1 - Math.min(1, root.t2 * 1.6) }
        Rectangle { anchors.fill: parent; radius: height / 2; color: Theme.paneHover; visible: resizePill.open }
        Row {
            anchors.centerIn: parent
            spacing: 6
            opacity: root.fadeIn(root.t2)
            Icon { name: "aspect_ratio"; font.pixelSize: 20; anchors.verticalCenter: parent.verticalCenter }
            Label {
                anchors.verticalCenter: parent.verticalCenter
                text: "Розмір"
                size: 13
                weight: Font.Bold
                visible: resizePill.width > root.pillW + 40
            }
        }
        HoverHandler { id: resizeHover; onHoveredChanged: root.tip = hovered ? "Змінити розмір — тягніть у потрібний бік" : "" }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: Drops.startResize(Drops.menuFor)
        }
    }

    Item {
        id: deskPill
        readonly property bool open: deskHover.hovered && root.t2 > 0.9
        readonly property real appear: Math.max(0, Math.min(1, (root.t2 - 0.4) / 0.6))   // виїжджає з-під «Розміру»
        width: open ? root.deskOpenW : root.pillW
        height: root.h2
        x: root.lerp(resizePill.x + resizePill.width / 2 - width / 2, resizePill.x + resizePill.width + root.gap2, appear)
        y: root.row2Y
        opacity: appear
        visible: appear > 0
        clip: true
        Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        Glass { anchors.fill: parent; strong: true; radius: height / 2 }
        // голова таблетки: клік — на наступний стіл
        Rectangle {
            id: deskHead
            width: root.pillW; height: parent.height; radius: height / 2
            color: headArea.containsMouse ? Theme.paneHover : "transparent"
            Icon { anchors.centerIn: parent; name: "arrow_forward"; font.pixelSize: 20 }
            MouseArea {
                id: headArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onContainsMouseChanged: if (containsMouse) root.tip = `На стіл ${root.nextDesk}`
                onClicked: Drops.moveTo(root.nextDesk)
            }
        }
        // розгорнута: усі столи (поточний підсвічений) і новий
        Row {
            x: root.pillW + 4
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6
            opacity: deskPill.open ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 150 } }
            Repeater {
                model: root.desks
                Rectangle {
                    required property var modelData
                    readonly property bool here: !!root.client && root.client.workspace.id === modelData.id
                    width: 34; height: 30; radius: 15
                    color: here ? Theme.accent : deskArea.containsMouse ? Theme.paneHover : Theme.pane
                    Label {
                        anchors.centerIn: parent
                        visible: !parent.modelData.fresh
                        text: parent.modelData.label
                        weight: Font.Bold
                        color: parent.here ? Theme.accentInk : Theme.ink
                        shadow: !parent.here
                    }
                    Icon { anchors.centerIn: parent; visible: !!parent.modelData.fresh; name: "add"; font.pixelSize: 18 }
                    MouseArea {
                        id: deskArea
                        anchors.fill: parent
                        enabled: !parent.here
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onContainsMouseChanged: if (containsMouse) root.tip = parent.modelData.fresh ? "На новий стіл" : `На стіл ${parent.modelData.id}`
                        onClicked: Drops.moveTo(parent.modelData.id)
                    }
                }
            }
        }
        HoverHandler { id: deskHover; onHoveredChanged: if (!hovered) root.tip = "" }
    }

    // підказка — під таблетками
    Label {
        visible: root.tip !== "" && root.t2 > 0.9
        x: root.shift * root.grow1 - width / 2
        y: root.top2 + root.h2 + 10
        text: root.tip
        size: 11
    }
}
