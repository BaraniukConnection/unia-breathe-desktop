import QtQuick
import Quickshell.Hyprland
import "../../theme"

// The notch menu. Point (0, 0) is the middle of the border, outer edge. Opening: the notch sinks into the border, the dot
// drops out of it (detach) and spreads into the action panel (grow1); two pills flow out from under it (grow2):
// Size in the middle (click: resize mode) and Desk on the right (hover: desk list, click: next desk).
Item {
    id: root
    property var client: null
    property bool open: false
    property real detach: 0
    property real grow1: 0
    property real grow2: 0
    property real shift: 0             // shift of the panels along the border, to stay on screen
    property real band: 3              // border width
    readonly property real top1: band + 14
    readonly property real h1: 52
    readonly property real top2: top1 + h1 + 8
    readonly property real h2: 40

    // panel 1: actions
    readonly property var actions: [
        { act: "minimize", icon: "remove", tip: "Minimize" },
        client && client.fullscreen
            ? { act: "fullscreen", icon: "close_fullscreen", tip: "Exit Fullscreen" }
            : { act: "fullscreen", icon: "open_in_full", tip: "Fullscreen" },
        client && client.floating
            ? { act: "float", icon: "grid_view", tip: "Back to the Grid" }
            : { act: "float", icon: "picture_in_picture", tip: "Float" },
        { act: "close", icon: "close", tip: "Close" },
    ]
    readonly property real w1: 16 + actions.length * 44 + (actions.length - 1) * 8
    property string tip: ""            // the hint under the pills: what the button under the cursor will do

    // desks: all regular ones plus a new one (the lowest free number)
    readonly property var desks: {
        const ids = Hyprland.workspaces.values.map(w => w.id).filter(id => id > 0).sort((a, b) => a - b)
        let free = 1
        while (ids.includes(free)) free++
        return [...ids.map(id => ({ id: id, label: String(id) })), { id: free, label: "", fresh: true }]
    }
    // the next desk to the right (a click on the Desk pill)
    readonly property int nextDesk: client ? Math.max(1, client.workspace.id + 1) : 1

    // pill sizes: collapsed is just the icon, expanded adds the label / the desks
    readonly property real pillW: 48
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

    // ---------- panel 1: minimize, fullscreen, float, close ----------
    Item {
        id: p1
        readonly property real t: root.grow1
        width: root.lerp(7, root.w1, t)
        height: root.lerp(7, root.h1, Math.min(1, t))
        x: root.shift * t - width / 2
        y: root.lerp(root.band + 9 + 14 - 3.5, root.top1, t)   // from the dot that fell out of the notch to its place
        visible: t > 0
        Glass {
            anchors.fill: parent
            strong: true
            radius: Math.min(width, height) / 2
        }
        Rectangle {                                         // still a dot: white while it spreads
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

    // ---------- pills: Size and Desk, sharing the width under panel 1 ----------
    // they flow out under panel 1 as a dot in the middle and part to their halves
    readonly property real t2: grow2
    readonly property real row2Y: lerp(top1 + h1 - 4, top2, Math.min(1, t2 * 1.4))
    readonly property real halfW: (w1 - gap2) / 2
    readonly property real cx: shift * grow1                         // middle of panel 1
    readonly property real appear: Math.max(0, Math.min(1, (t2 - 0.4) / 0.6))

    Item {
        id: resizePill
        width: root.lerp(12, root.halfW, Math.min(1, root.t2))
        height: root.lerp(12, root.h2, Math.min(1, root.t2))
        x: root.lerp(root.cx - width / 2, root.cx - root.w1 / 2, root.appear)
        y: root.row2Y
        visible: root.t2 > 0
        Glass { anchors.fill: parent; strong: true; radius: height / 2 }
        Rectangle { anchors.fill: parent; radius: height / 2; color: Theme.accent; opacity: 1 - Math.min(1, root.t2 * 1.6) }
        Rectangle { anchors.fill: parent; radius: height / 2; color: Theme.paneHover; visible: resizeArea.containsMouse }
        Row {
            anchors.centerIn: parent
            spacing: 6
            opacity: root.fadeIn(root.t2)
            Icon { name: "aspect_ratio"; font.pixelSize: 20; anchors.verticalCenter: parent.verticalCenter }
            Label { anchors.verticalCenter: parent.verticalCenter; text: "Size"; size: 13; weight: Font.Bold }
        }
        MouseArea {
            id: resizeArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onContainsMouseChanged: root.tip = containsMouse ? "Resize: drag the way you want it to grow" : ""
            onClicked: Drops.startResize(Drops.menuFor)
        }
    }

    Item {
        id: deskPill
        readonly property bool open: deskHover.hovered && root.t2 > 0.9
        readonly property real appear: root.appear
        width: open ? Math.max(root.halfW, root.deskOpenW) : root.halfW
        height: root.h2
        x: root.lerp(root.cx - root.halfW / 2, root.cx - root.w1 / 2 + root.halfW + root.gap2, appear)
        y: root.row2Y
        opacity: appear
        visible: appear > 0
        clip: true
        Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        Glass { anchors.fill: parent; strong: true; radius: height / 2 }
        // the pill's head: a click moves to the next desk; expanded it is just the arrow, then the desks
        Rectangle {
            id: deskHead
            width: deskPill.open ? root.pillW : root.halfW
            height: parent.height; radius: height / 2
            color: headArea.containsMouse ? Theme.paneHover : "transparent"
            Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            Row {
                anchors.centerIn: parent
                spacing: 6
                Label {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Desk"; size: 13; weight: Font.Bold
                    visible: !deskPill.open
                }
                Icon { name: "arrow_forward"; font.pixelSize: 20; anchors.verticalCenter: parent.verticalCenter }
            }
            MouseArea {
                id: headArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onContainsMouseChanged: if (containsMouse) root.tip = `To Desk ${root.nextDesk}`
                onClicked: Drops.moveTo(root.nextDesk)
            }
        }
        // expanded: every desk (the current one highlighted) and a new one
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
                        onContainsMouseChanged: if (containsMouse) root.tip = parent.modelData.fresh ? "To a New Desk" : `To Desk ${parent.modelData.id}`
                        onClicked: Drops.moveTo(parent.modelData.id)
                    }
                }
            }
        }
        HoverHandler { id: deskHover; onHoveredChanged: if (!hovered) root.tip = "" }
    }

    // the hint, under the pills
    Label {
        visible: root.tip !== "" && root.t2 > 0.9
        x: root.shift * root.grow1 - width / 2
        y: root.top2 + root.h2 + 10
        text: root.tip
        size: 11
    }
}
