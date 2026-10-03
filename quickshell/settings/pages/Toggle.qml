import QtQuick
import "../../theme"

// Перемикач увімкнено/вимкнено.
Rectangle {
    id: root
    property bool checked
    signal toggled(bool value)
    width: 48; height: 28; radius: 14
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
