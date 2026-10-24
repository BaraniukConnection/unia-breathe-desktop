import QtQuick

// A glass surface: translucent ground and a thin light outline. Hyprland does the blur (layerrule blur).
Rectangle {
    property bool strong: false
    color: strong ? Theme.glassStrong : Theme.glass
    border.width: 1
    border.color: Theme.paneLine
    radius: Theme.radiusWindow
}
