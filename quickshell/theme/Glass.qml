import QtQuick

// Скляна поверхня: напівпрозоре тло + тонка світла обвідка. Розмиття дає Hyprland (layerrule blur).
Rectangle {
    property bool strong: false
    color: strong ? Theme.glassStrong : Theme.glass
    border.width: 1
    border.color: Theme.paneLine
    radius: Theme.radiusWindow
}
