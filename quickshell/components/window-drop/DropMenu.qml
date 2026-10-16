import QtQuick
import Quickshell.Hyprland
import "../../theme"

// Меню краплини. Точка (0, 0) — краплина на рамці. Відкриття: краплина відривається від рамки (detach),
// розтікається в панель із трьома діями (grow1), з-під неї стікає друга панель — перемістити на стіл (grow2).
Item {
    id: root
    property var client: null
    property bool open: false
    property real detach: 0
    property real grow1: 0
    property real grow2: 0
    property real shift: 0             // зсув панелей уздовж рамки, щоб не вилізти за край екрана
    readonly property real w1: 168
    readonly property real h1: 52
    readonly property real top1: 16
    readonly property real top2: top1 + h1 + 8

    // столи: усі звичайні, плюс новий (найменший вільний номер)
    readonly property var desks: {
        const ids = Hyprland.workspaces.values.map(w => w.id).filter(id => id > 0).sort((a, b) => a - b)
        let free = 1
        while (ids.includes(free)) free++
        return [...ids.map(id => ({ id: id, label: String(id) })), { id: free, label: "", fresh: true }]
    }
    readonly property real w2: Math.max(w1, 28 + desks.length * 34 + (desks.length - 1) * 6)
    readonly property real h2: 84

    onOpenChanged: {
        if (open) { closing.stop(); detach = 0; grow1 = 0; grow2 = 0; opening.restart(); keys.forceActiveFocus() }
        else { opening.stop(); closing.restart() }
    }
    SequentialAnimation {
        id: opening
        NumberAnimation { target: root; property: "detach"; to: 1; duration: 150; easing.type: Easing.InQuad }
        NumberAnimation { target: root; property: "grow1"; to: 1; duration: 280; easing.type: Easing.OutBack; easing.overshoot: 1.2 }
        NumberAnimation { target: root; property: "grow2"; to: 1; duration: 260; easing.type: Easing.OutBack; easing.overshoot: 1.1 }
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

    // ---------- панель 1: згорнути, на весь екран, закрити ----------
    Item {
        id: p1
        readonly property real t: root.grow1
        width: root.lerp(14, root.w1, t)
        height: root.lerp(14, root.h1, Math.min(1, t))
        x: root.shift * t - width / 2
        y: root.lerp(4 + 15 + 10 - 7, root.top1, t)          // з кульки, що впала, — на своє місце
        visible: t > 0
        Glass {
            anchors.fill: parent
            strong: true
            radius: Math.min(width, height) / 2
        }
        Rectangle {                                         // ще крапля — акцентна, поки розтікається
            anchors.fill: parent
            radius: Math.min(width, height) / 2
            color: Theme.accent
            opacity: 1 - Math.min(1, p1.t * 1.6)
        }
        Row {
            anchors.centerIn: parent
            spacing: 8
            opacity: root.fadeIn(p1.t)
            Repeater {
                model: [
                    { act: "minimize", icon: "remove", tip: "Згорнути" },
                    { act: "fullscreen", icon: "open_in_full", tip: "На весь екран" },
                    { act: "close", icon: "close", tip: "Закрити" },
                ]
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
                        onClicked: Drops.act(parent.modelData.act)
                    }
                    // підказка — під панеллю 1, поки не стекла панель 2
                    Label {
                        visible: area.containsMouse && root.grow2 < 0.3
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: parent.height + 10
                        text: parent.modelData.tip
                        size: 11
                    }
                }
            }
        }
    }

    // ---------- панель 2: перемістити на стіл ----------
    Item {
        id: p2
        readonly property real t: root.grow2
        width: root.lerp(12, root.w2, t)
        height: root.lerp(12, root.h2, Math.min(1, t))
        x: root.shift * root.grow1 - width / 2
        y: root.lerp(root.top1 + root.h1 - 4, root.top2, Math.min(1, t * 1.4))   // стікає з-під панелі 1
        visible: t > 0
        Glass {
            anchors.fill: parent
            strong: true
            radius: Math.min(width / 2, height / 2, 26)
        }
        Rectangle {
            anchors.fill: parent
            radius: Math.min(width / 2, height / 2, 26)
            color: Theme.accent
            opacity: 1 - Math.min(1, p2.t * 1.6)
        }
        Column {
            anchors.centerIn: parent
            spacing: 8
            opacity: root.fadeIn(p2.t)
            Label { anchors.horizontalCenter: parent.horizontalCenter; text: "Перемістити на стіл"; size: 12; muted: true }
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 6
                Repeater {
                    model: root.desks
                    Rectangle {
                        required property var modelData
                        readonly property bool here: !!root.client && root.client.workspace.id === modelData.id
                        width: 34; height: 32; radius: 16
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
                            onClicked: Drops.moveTo(parent.modelData.id)
                        }
                    }
                }
            }
        }
    }
}
