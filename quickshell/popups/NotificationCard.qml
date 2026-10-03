import QtQuick
import Quickshell
import Quickshell.Widgets
import "../theme"
import "../services"

// Одне сповіщення: іконка програми, заголовок, текст, час, ✕, кнопки дій. Клік — дія за замовчуванням.
Rectangle {
    id: root
    required property var entry
    property bool toast: false
    readonly property var n: entry.n
    readonly property bool critical: n.urgency === 2
    implicitHeight: col.implicitHeight + 20
    radius: 16
    color: toast ? Theme.glassStrong : area.containsMouse ? Theme.paneHover : Theme.pane
    border.width: critical ? 2 : 1
    border.color: critical ? Theme.red : Theme.paneLine

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Notifs.activate(root.entry)
    }

    Row {
        x: 12; y: 10
        width: parent.width - 24
        spacing: 12

        ClippingRectangle {
            width: 32; height: 32; radius: 10
            color: Theme.paneHover
            readonly property string src: root.n.image || Notifs.icon(root.n)
            Image { id: pic; anchors.fill: parent; source: parent.src; fillMode: Image.PreserveAspectCrop; sourceSize: Qt.size(64, 64) }
            Icon { anchors.centerIn: parent; name: "notifications"; font.pixelSize: 18; visible: pic.status !== Image.Ready }
        }

        Column {
            id: col
            width: parent.width - 44 - 12
            spacing: 2
            Item {
                width: parent.width
                height: 20
                Label {
                    width: parent.width - time.implicitWidth - close.width - 12
                    text: root.n.summary || root.n.appName
                    weight: Font.Bold
                    elide: Text.ElideRight
                    anchors.verticalCenter: parent.verticalCenter
                }
                Label {
                    id: time
                    anchors.right: close.left
                    anchors.rightMargin: 6
                    anchors.verticalCenter: parent.verticalCenter
                    text: Qt.formatTime(root.entry.time, "HH:mm")
                    size: 12
                    muted: true
                }
                IconButton {
                    id: close
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    implicitWidth: 24; implicitHeight: 24
                    iconSize: 16
                    icon: "close"
                    muted: true
                    onClicked: root.toast ? Notifs.hideToast(root.entry) : Notifs.dismiss(root.entry)
                }
            }
            Label {
                width: parent.width
                visible: text !== ""
                text: root.n.body
                textFormat: Text.StyledText
                size: 13
                weight: Font.Medium
                muted: true
                wrapMode: Text.Wrap
                maximumLineCount: root.toast ? 4 : 3
                elide: Text.ElideRight
            }
            Flow {
                width: parent.width
                spacing: 6
                topPadding: 6
                visible: actions.count > 0
                Repeater {
                    id: actions
                    model: root.n.actions.filter(a => a.identifier !== "default")
                    Pill {
                        required property var modelData
                        height: 28
                        width: actLabel.implicitWidth + 24
                        hovered: actArea.containsMouse
                        Label { id: actLabel; anchors.centerIn: parent; text: modelData.text; size: 12; weight: Font.Bold }
                        MouseArea { id: actArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: modelData.invoke() }
                    }
                }
            }
        }
    }
}
