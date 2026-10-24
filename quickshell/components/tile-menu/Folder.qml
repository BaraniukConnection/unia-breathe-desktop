import QtQuick
import QtQuick.Controls
import "../../theme"
import "../../services"

// A folder: its name (click to rename) and a tile grid 8 cells wide.
Column {
    id: root
    required property var group
    required property var panel
    readonly property alias grid: grid
    readonly property bool empty: root.group.tiles.length === 0
    spacing: 8
    opacity: root.panel.dragFolder === root.group.id ? 0.35 : 1

    function startEdit() { edit.text = root.group.name; edit.visible = true; edit.forceActiveFocus(); edit.selectAll() }

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
        }
        MouseArea {
            id: head
            anchors.fill: parent
            anchors.rightMargin: 34                  // keep clear of the ⋯ button
            visible: !edit.visible
            hoverEnabled: true
            preventStealing: true
            cursorShape: dragging ? Qt.ClosedHandCursor : Qt.OpenHandCursor
            property point start
            property bool dragging: false
            onPressed: m => { start = Qt.point(m.x, m.y); dragging = false }
            onPositionChanged: m => {
                if (!pressed) return
                const p = mapToItem(root.panel, m.x, m.y)
                if (!dragging && Math.hypot(m.x - start.x, m.y - start.y) > 6) { dragging = true; root.panel.beginFolderDrag(root.group, p) }
                else if (dragging) root.panel.moveFolderDrag(p)
            }
            onReleased: m => { if (dragging) { root.panel.endFolderDrag(mapToItem(root.panel, m.x, m.y)); dragging = false } }
            onCanceled: if (dragging) { root.panel.cancelFolderDrag(); dragging = false }
            onClicked: if (!dragging) root.startEdit()
        }
        Icon {   // a hint that the header can be dragged
            visible: head.containsMouse && !edit.visible
            x: title.implicitWidth + 8
            anchors.verticalCenter: parent.verticalCenter
            name: "drag_indicator"
            font.pixelSize: 16
            color: Theme.inkMuted
        }
        // folder menu: ⋯ on the right of the header
        IconButton {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            implicitWidth: 28; implicitHeight: 28
            iconSize: 18
            icon: "more_horiz"
            muted: true
            onClicked: root.panel.folderMenu(root.group, mapToItem(root.panel, 0, height))
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

        // an empty folder: a hint and a frame to drop tiles into
        Rectangle {
            visible: root.empty
            anchors.fill: parent
            radius: Theme.radiusTile
            color: "transparent"
            border.width: 1
            border.color: Theme.paneLine
            Label { anchors.centerIn: parent; text: "Drag tiles here"; size: 12; muted: true }
        }

        // where the dragged tile will land
        Rectangle {
            readonly property var s: root.panel.dropSlot
            visible: !!s && !!s.size && s.group === root.group.id
            x: visible ? s.x * 56 : 0
            y: visible ? s.y * 56 : 0
            width: visible ? Menu.sizes[s.size][0] * 56 - 8 : 0
            height: visible ? Menu.sizes[s.size][1] * 56 - 8 : 0
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
