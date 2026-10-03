import QtQuick
import "../../theme"

// Вибір одного з варіантів (сегменти).
Rectangle {
    id: root
    property var options: []          // [{ value, label }]
    property var current
    signal chosen(var value)
    width: row.implicitWidth + 8
    height: 36
    radius: 18
    color: Theme.paneHover
    border.width: 1
    border.color: Theme.paneLine
    Row {
        id: row
        x: 4; y: 4
        Repeater {
            model: root.options
            Rectangle {
                required property var modelData
                readonly property bool on: root.current === modelData.value
                width: lbl.implicitWidth + 24
                height: 28
                radius: 14
                color: on ? Theme.accent : a.containsMouse ? Theme.pane : "transparent"
                Label { id: lbl; anchors.centerIn: parent; text: modelData.label; size: 12; weight: Font.Bold; color: parent.on ? Theme.accentInk : Theme.ink; shadow: !parent.on }
                MouseArea { id: a; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.chosen(modelData.value) }
            }
        }
    }
}
