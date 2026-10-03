import QtQuick

// Значок Material Symbols за назвою (наприклад "wifi", "volume_up").
Text {
    property string name
    property bool filled: false
    text: name
    font.family: Theme.icons
    font.pixelSize: 20
    font.variableAxes: ({ "FILL": filled ? 1 : 0, "wght": 400, "opsz": 24 })
    color: Theme.ink
    renderType: Text.NativeRendering
}
