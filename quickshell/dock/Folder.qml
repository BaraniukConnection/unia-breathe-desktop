import QtQuick
import QtQuick.Controls
import "../theme"
import "../services"

// Папка: назва (клік — перейменувати) і сітка плиток 8 клітинок завширшки.
Column {
    id: root
    required property var group
    required property var panel
    readonly property alias grid: grid
    spacing: 8

    Item {
        width: grid.width
        height: 28
        Label {
            id: title
            visible: !edit.visible
            anchors.verticalCenter: parent.verticalCenter
            text: root.group.name
            size: 13
            weight: Font.Bold
            muted: true
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.IBeamCursor
                onClicked: { edit.text = root.group.name; edit.visible = true; edit.forceActiveFocus(); edit.selectAll() }
            }
        }
        TextField {
            id: edit
            visible: false
            width: 220
            height: 28
            font.family: Theme.font
            font.pixelSize: 13
            font.bold: true
            color: Theme.ink
            leftPadding: 8
            background: Rectangle { radius: 8; color: Theme.paneHover; border.width: 1; border.color: Theme.accent }
            onAccepted: { Menu.rename(root.group.id, text); visible = false }
            onActiveFocusChanged: if (!activeFocus) visible = false
            Keys.onEscapePressed: visible = false
        }
    }

    Item {
        id: grid
        readonly property var groupId: root.group.id
        width: Menu.cols * 48 + (Menu.cols - 1) * 8
        height: Math.max(1, Menu.rowsOf(root.group.tiles)) * 56 - 8

        // місце, куди впаде плитка, яку тягнуть
        Rectangle {
            readonly property var s: root.panel.dropSlot
            visible: !!s && s.group === root.group.id
            x: s ? s.x * 56 : 0
            y: s ? s.y * 56 : 0
            width: s ? Menu.sizes[s.size][0] * 56 - 8 : 0
            height: s ? Menu.sizes[s.size][1] * 56 - 8 : 0
            radius: Theme.radiusTile
            color: "transparent"
            border.width: 2
            border.color: Theme.accent
        }
        Repeater {
            model: root.group.tiles
            Tile {
                required property var modelData
                tile: modelData
                panel: root.panel
            }
        }
    }
}
