import QtQuick

// Текст на склі: шрифт Manrope, м'яка тінь (як text-shadow у макеті).
Text {
    property int size: Theme.fontSize
    property int weight: Font.DemiBold
    property bool muted: false
    property bool shadow: true
    font.family: Theme.font
    font.pixelSize: size
    font.weight: weight
    font.features: ({ "tnum": 1 })
    color: muted ? Theme.inkMuted : Theme.ink
    style: shadow ? Text.Raised : Text.Normal
    styleColor: Qt.rgba(0, 0, 0, 0.34)
    verticalAlignment: Text.AlignVCenter
}
