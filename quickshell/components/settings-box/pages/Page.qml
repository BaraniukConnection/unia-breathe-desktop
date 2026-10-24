import QtQuick
import "../../../theme"

// Page frame: title, subtitle and a scrolling column of groups up to 680 px wide, centred.
Flickable {
    id: root
    default property alias content: col.data
    property string title
    property string subtitle
    contentHeight: col.implicitHeight + 64
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    Column {
        id: col
        x: (root.width - width) / 2
        y: 32
        width: Math.min(root.width - 64, 680)
        spacing: 14
        Label { text: root.title; size: 26; weight: Font.ExtraBold }
        Label { visible: text !== ""; width: parent.width; text: root.subtitle; muted: true; wrapMode: Text.Wrap; bottomPadding: 8 }
    }
}
