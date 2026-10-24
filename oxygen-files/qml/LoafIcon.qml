import QtQuick

Item {
    id: iconRoot
    property string name: "file"
    property real size: 20
    property color color: (typeof theme !== "undefined" && theme && theme.textMain) ? theme.textMain : "#e6e1e6"

    width: size
    height: size

    // Codepoints verified against Phosphor web 2.1.1 (matches assets/fonts/Phosphor.ttf).
    // Each icon is a single PUA glyph; duotone renders base (codepoint) + overlay (codepoint+1).

    readonly property string primaryGlyph: (typeof theme !== "undefined" && theme.glyphs[name]) || "\ue230"
    readonly property bool isDuotone: (typeof theme !== "undefined" && theme.phosphorWeight === "duotone")
    readonly property string fontFamily: (typeof theme !== "undefined" && theme.getFontFamily) ? theme.getFontFamily() : "Phosphor"

    Text {
        anchors.centerIn: parent
        text: iconRoot.primaryGlyph
        font.family: iconRoot.fontFamily
        font.pixelSize: iconRoot.size
        color: iconRoot.color
        opacity: iconRoot.isDuotone ? 0.32 : 1.0
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    Loader {
        active: iconRoot.isDuotone
        anchors.centerIn: parent
        sourceComponent: duotoneOverlay
    }

    Component {
        id: duotoneOverlay
        Text {
            text: String.fromCharCode(iconRoot.primaryGlyph.charCodeAt(0) + 1)
            font.family: iconRoot.fontFamily
            font.pixelSize: iconRoot.size
            color: iconRoot.color
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }
}
