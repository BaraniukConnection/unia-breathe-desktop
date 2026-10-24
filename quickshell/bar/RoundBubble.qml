import QtQuick
import "../theme"

// A round bubble with an icon (bell, power, focus mode).
Bubble {
    id: root
    property string icon
    property bool badge: false
    property bool filled: false
    padLeft: 0
    padRight: 0
    implicitWidth: Theme.bubbleHeight
    Item {
        width: Theme.bubbleHeight
        height: Theme.bubbleHeight
        Icon { anchors.centerIn: parent; name: root.icon; filled: root.filled; font.pixelSize: 22 }
        Icon { visible: root.badge; name: "star"; filled: true; font.pixelSize: 14; color: Theme.accent; x: parent.width - width - 6; y: 5 }
    }
}
