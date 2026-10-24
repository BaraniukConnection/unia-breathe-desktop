import QtQuick
import "../../../theme"

// A colour dot: click to pick; selected adds a ring.
Rectangle {
    id: root
    property bool selected: false
    property string tip: ""
    signal clicked()
    width: 28; height: 28; radius: width / 2
    border.width: 1
    border.color: Qt.rgba(1, 1, 1, 0.25)
    activeFocusOnTab: true
    Keys.onSpacePressed: clicked()
    Keys.onReturnPressed: clicked()
    Rectangle {
        anchors.fill: parent
        anchors.margins: -4
        radius: width / 2
        color: "transparent"
        border.width: 2
        border.color: root.activeFocus ? Theme.accent : Theme.ink
        visible: root.selected || root.activeFocus || area.containsMouse
        opacity: root.selected || root.activeFocus ? 1 : 0.4
    }
    MouseArea { id: area; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.clicked() }
}
