import QtQuick
import Quickshell
import Quickshell.Widgets
import "../../theme"

// «Місце» для розкладеного вікна, яке тягнуть: напівпрозоре порожнє вікно (скло з розмиттям Hyprland),
// яке Hyprland розкладає як звичайне — сусіди розсуваються, і видно, куди стане вікно.
// Правила (unia.conf): розкладене, без фокусу при появі, без рамки й тіні, з'являється на схованому столі.
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
