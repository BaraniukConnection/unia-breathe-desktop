import QtQuick
import Quickshell
import Quickshell.Widgets
import "../../theme"
import "../../services"

// An app tile. Small is just the icon; medium and larger are glass tiles with the name,
// and live tiles show content (calendar, clock, now playing).
Item {
    id: root
    required property var tile            // { id, app, size, x, y, live? }
    required property var panel           // MenuPanel: for dragging and the context menu
    readonly property var entry: Apps.byId(tile.app)
    readonly property bool small: tile.size === "small"
    readonly property string live: !small && tile.live !== false ? Apps.liveKind(entry) : ""
    readonly property int unit: 48
    readonly property int gap: 8
    readonly property var d: Menu.sizes[tile.size]
    x: tile.x * (unit + gap)
    y: tile.y * (unit + gap)
    width: d[0] * unit + (d[0] - 1) * gap
    height: d[1] * unit + (d[1] - 1) * gap
    opacity: panel.dragTile === tile.id ? 0.25 : 1
    Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
    Behavior on y { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

    SystemClock { id: clock; precision: SystemClock.Minutes; enabled: root.live === "clock" || root.live === "calendar" }

    Rectangle {
        anchors.fill: parent
        radius: root.small ? 14 : Theme.radiusTile
        color: root.small ? (area.containsMouse ? Theme.paneHover : "transparent") : area.containsMouse ? Theme.paneHover : Theme.pane
        border.width: root.small ? 0 : 1
        border.color: Theme.paneLine
    }

    // icon (small: centred; larger: in the corner, or centred if the tile is not live)
    AppIcon {
        app: root.tile.app
        implicitSize: root.small ? 36 : root.tile.size === "large" ? 72 : 44
        x: (root.width - width) / 2
        y: root.small ? (root.height - height) / 2 : (root.height - height) / 2 - 8
        width: implicitSize
        height: implicitSize
        visible: root.live === ""          // a live tile shows its content without the icon, so the icon does not cover it
    }
    Label {
        visible: !root.small
        x: 12
        width: root.width - 24
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 10
        text: root.entry ? root.entry.name : root.tile.app
        size: 12
        weight: Font.Bold
        elide: Text.ElideRight
        horizontalAlignment: root.live === "" ? Text.AlignHCenter : Text.AlignLeft
    }

    // live faces
    Column {
        visible: root.live === "calendar"
        x: 12; y: 10
        width: root.width - 24
        Label { text: Theme.locale.toString(clock.date, "dddd"); size: 11; muted: true; weight: Font.Bold }
        Label { text: clock.date.getDate(); size: root.tile.size === "large" ? 40 : 28; weight: Font.ExtraBold }
        Label { width: parent.width; visible: root.tile.size !== "medium"; text: Events.next ? Events.next.title : "No events"; size: 12; muted: true; elide: Text.ElideRight }
    }
    Column {
        visible: root.live === "clock"
        x: 12; y: 12
        Label { text: Qt.formatTime(clock.date, Prefs.data.clock24 !== false ? "HH:mm" : "h:mm AP"); size: root.tile.size === "large" ? 40 : 26; weight: Font.ExtraBold }
        Label { text: Theme.locale.toString(clock.date, "d MMM"); size: 12; muted: true }
    }
    Item {
        visible: root.live === "media"
        anchors.fill: parent
        anchors.margins: 10
        ClippingRectangle {
            width: root.tile.size === "medium" ? 40 : 64; height: width; radius: 10
            color: Theme.paneHover
            Image { anchors.fill: parent; source: Media.art; fillMode: Image.PreserveAspectCrop; asynchronous: true }
        }
        Label { y: root.tile.size === "medium" ? 46 : 72; width: parent.width; text: Media.title; size: 12; weight: Font.Bold; elide: Text.ElideRight; maximumLineCount: 1 }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        preventStealing: true          // otherwise the panel's scrolling steals the drag
        property point start
        property bool dragging: false
        onPressed: m => { start = Qt.point(m.x, m.y); dragging = false }
        onPositionChanged: m => {
            if (!pressed || m.buttons !== Qt.LeftButton) return
            const p = mapToItem(root.panel, m.x, m.y)
            if (!dragging && Math.hypot(m.x - start.x, m.y - start.y) > 6) {
                dragging = true
                root.panel.beginDrag(root.tile, Qt.point(start.x, start.y), p)
            } else if (dragging) root.panel.moveDrag(p)
        }
        onReleased: m => {
            if (dragging) { root.panel.endDrag(mapToItem(root.panel, m.x, m.y)); dragging = false }
        }
        onCanceled: if (dragging) { root.panel.cancelDrag(); dragging = false }
        onClicked: m => {
            if (dragging) return
            if (m.button === Qt.RightButton) root.panel.tileMenu(root.tile, mapToItem(root.panel, m.x, m.y))
            else root.panel.launch(root.tile.app)
        }
    }
}
