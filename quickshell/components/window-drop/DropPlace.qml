import QtQuick
import Quickshell
import Quickshell.Widgets
import "../../theme"

// The "place" for a dragged tiled window: a translucent empty window (glass blurred by Hyprland)
// that Hyprland tiles like any other: neighbours make room, and you see where the window will land.
// Rules (unia.conf): tiled, no focus on open, no border or shadow, opens on a hidden desk.
FloatingWindow {
    title: Drops.placeTitle
    color: "transparent"
    visible: Drops.placeWanted
    implicitWidth: 400
    implicitHeight: 300
    onVisibleChanged: if (!visible) Drops.placeAddr = ""

    Rectangle {
        anchors.fill: parent
        radius: 14
        color: Theme.glass
        border.width: 2
        border.color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.8)
        IconImage {
            anchors.centerIn: parent
            implicitSize: Math.min(72, parent.width / 3, parent.height / 3)
            opacity: 0.45
            readonly property var c: Drops.drag ? Drops.client(Drops.drag.address) : null
            source: c ? Quickshell.iconPath(DesktopEntries.heuristicLookup(c.class)?.icon ?? c.class.toLowerCase(), "application-x-executable") : ""
        }
    }
}
