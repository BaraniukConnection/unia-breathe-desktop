import QtQuick
import "../../../theme"

// A slider with its value on the right. Changes apply live while dragging.
Item {
    id: root
    property real value
    property real from: 0
    property real to: 1
    property real step: 0.05
    property int decimals: 2
    property string unit: ""
    property real display: value              // what to show (e.g. as a percentage)
    signal moved(real value)
    width: 300
    height: 32
    activeFocusOnTab: true
    function nudge(d) { moved(Number(Math.max(from, Math.min(to, value + d * step)).toFixed(decimals))) }
    Keys.onLeftPressed: nudge(-1)
    Keys.onDownPressed: nudge(-1)
    Keys.onRightPressed: nudge(1)
    Keys.onUpPressed: nudge(1)
    Rectangle { anchors.fill: parent; anchors.margins: -6; radius: 12; color: "transparent"; border.width: 2; border.color: Theme.accent; visible: root.activeFocus }

    Rectangle {
        id: track
        x: 0
        width: parent.width - 64
        height: 6; radius: 3
        anchors.verticalCenter: parent.verticalCenter
        color: Theme.paneHover
        Rectangle {
            width: Math.max(0, Math.min(1, (root.value - root.from) / (root.to - root.from))) * parent.width
            height: parent.height; radius: 3
            color: Theme.accent
        }
        Rectangle {
            x: Math.max(0, Math.min(1, (root.value - root.from) / (root.to - root.from))) * parent.width - width / 2
            anchors.verticalCenter: parent.verticalCenter
            width: 18; height: 18; radius: 9
            color: Theme.ink
            border.width: 3
            border.color: Theme.accent
        }
        MouseArea {
            anchors.fill: parent
            anchors.margins: -12
            cursorShape: Qt.PointingHandCursor
            function at(x) {
                const r = Math.max(0, Math.min(1, (x - 12) / track.width))
                const v = root.from + Math.round(r * (root.to - root.from) / root.step) * root.step
                if (Math.abs(v - root.value) > root.step / 2) root.moved(Number(v.toFixed(root.decimals)))
            }
            onPressed: m => at(m.x)
            onPositionChanged: m => at(m.x)
        }
    }
    Label {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: 52
        horizontalAlignment: Text.AlignRight
        text: Number(root.display).toFixed(root.unit === "%" ? 0 : root.decimals > 0 && root.step < 1 ? root.decimals : 0) + root.unit
        weight: Font.Bold
    }
}
