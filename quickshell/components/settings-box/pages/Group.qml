import QtQuick
import "../../../theme"

// Картка-група на сторінці налаштувань: заголовок і рядки.
Rectangle {
    default property alias content: col.data
    property string title
    width: parent ? parent.width : 0
    implicitHeight: col.implicitHeight + 24
    radius: 22
    color: Theme.pane
    border.width: 1
    border.color: Theme.paneLine
    Column {
        id: col
        x: 18; y: 12
        width: parent.width - 36
        spacing: 4
        Label { visible: text !== ""; text: title; size: 12; weight: Font.Bold; muted: true; font.letterSpacing: 1; bottomPadding: 4; topPadding: 4 }
    }
}
