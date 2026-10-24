import QtQuick

// Text on glass: Manrope with a soft shadow (like text-shadow in the mockup).
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
