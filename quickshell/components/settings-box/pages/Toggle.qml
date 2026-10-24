import QtQuick
import "../../../theme"

// An on/off switch.
Rectangle {
    id: root
    property bool checked
    signal toggled(bool value)
    width: 48; height: 28; radius: 14
    activeFocusOnTab: true
    Keys.onSpacePressed: toggled(!checked)
    Keys.onReturnPressed: toggled(!checked)
    // keyboard focus ring
    Rectangle { anchors.fill: parent; anchors.margins: -4; radius: parent.radius + 4; color: "transparent"; border.width: 2; border.color: Theme.accent; visible: parent.activeFocus }
    color: checked ? Theme.accent : Theme.paneHover
    border.width: checked ? 0 : 1
    border.color: Theme.paneLine
    Behavior on color { ColorAnimation { duration: 140 } }
    Rectangle {
        width: 20; height: 20; radius: 10
        y: 4
        x: root.checked ? root.width - width - 4 : 4
        color: root.checked ? Theme.accentInk : Theme.ink
        Behavior on x { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
    }
    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.toggled(!root.checked) }
}
