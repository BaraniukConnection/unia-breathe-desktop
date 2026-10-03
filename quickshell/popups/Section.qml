import QtQuick
import "../theme"

// Внутрішня секція спливаючого вікна (.sec у макеті).
Rectangle {
    default property alias content: col.data
    property int pad: 14
    color: Theme.pane
    border.width: 1
    border.color: Theme.paneLine
    radius: 18
    implicitHeight: col.implicitHeight + 16
    Column {
        id: col
        x: parent.pad
        y: 8
        width: parent.width - 2 * parent.pad
        spacing: 6
    }
}
