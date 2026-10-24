pragma Singleton
import QtQuick
import Quickshell
import "../services"

// Unia Breathe Desktop's palette, fonts and glass: one place for every colour and size (from the mockup).
Singleton {
    // colours: the main accent and the secondary ones are picked in Settings (Theme); the rest of the palette
    // (ground, glass, text) is tinted towards the accent. With the default emerald everything matches the mockup
    readonly property color defaultAccent: "#10b981"
    readonly property var defaultSecondary: ["#13eca4", "#5b9bff", "#f59e0b", "#b57bf9"]
    readonly property var colors: Prefs.data.theme ?? ({})
    readonly property color accent: colors.accent ?? defaultAccent
    readonly property var secondary: colors.secondary ?? defaultSecondary
    readonly property real hueShift: accent.hslSaturation < 0.08 ? 0 : accent.hslHue - defaultAccent.hslHue
    readonly property real satK: Math.min(1, accent.hslSaturation / defaultAccent.hslSaturation)
    function tint(c, a) {
        c = Qt.lighter(c, 1)                       // "#…" string → colour
        return Qt.hsla((c.hslHue + hueShift + 1) % 1, c.hslSaturation * satK, c.hslLightness, a ?? c.a)
    }
    // relative luminance (WCAG): decides the text colour on the accent
    function luminance(c) {
        const l = v => v <= 0.03928 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4)
        return 0.2126 * l(c.r) + 0.7152 * l(c.g) + 0.0722 * l(c.b)
    }
    function hex(c, alpha) {
        const h = v => Math.round(v * 255).toString(16).padStart(2, "0")
        return h(c.r) + h(c.g) + h(c.b) + (alpha === undefined ? "" : h(alpha))
    }

    readonly property color base: tint("#0b2a26")
    readonly property color ink: tint("#eaf6f0")
    readonly property color inkMuted: tint("#bfe3d5")
    readonly property color accentInk: luminance(accent) > 0.2 ? tint("#04231a") : "#ffffff"   // text on an accent ground

    // blur behind surfaces (the Blur switch in Settings)
    readonly property bool blur: (Prefs.data.hypr ?? {})["decoration:blur:enabled"] !== 0

    // glass: the ground of every surface, a denser one for menus, tiles and outlines; with blur off the ground is solid
    readonly property color glass: blur ? tint(Qt.rgba(8 / 255, 30 / 255, 25 / 255, 0.35)) : tint("#0d2a24")
    readonly property color glassStrong: blur ? tint(Qt.rgba(8 / 255, 30 / 255, 25 / 255, 0.62)) : tint("#081e19")
    readonly property color pane: Qt.rgba(1, 1, 1, 0.09)
    readonly property color paneHover: Qt.rgba(1, 1, 1, 0.15)
    readonly property color paneLine: Qt.rgba(1, 1, 1, 0.14)

    // colour marks: the theme's secondary colours (red always stays red: close, errors)
    readonly property color mint: secondary[0] ?? defaultSecondary[0]
    readonly property color blue: secondary[1] ?? defaultSecondary[1]
    readonly property color amber: secondary[2] ?? defaultSecondary[2]
    readonly property color purple: secondary[3] ?? defaultSecondary[3]
    readonly property color red: "#f26464"
    readonly property color emerald: accent

    // fonts
    // dates and day names: English, the week starts on Monday
    readonly property var locale: Qt.locale("en_GB")
    readonly property string font: "Manrope"
    readonly property string icons: "Material Symbols Outlined"
    readonly property int fontSize: 14

    // sizes
    // focus mode (the round button on the top bar): the bar gets lower and solid, see bar/Bar.qml
    readonly property bool focusMode: Prefs.data.focusMode ?? false
    readonly property int bubbleHeight: focusMode ? 30 : 44
    readonly property int edge: 20          // bubble margin from the screen edges
    readonly property int top: focusMode ? 4 : 16           // bubble margin from the top
    readonly property int gap: 10
    readonly property int radiusWindow: 26
    readonly property int radiusTile: 18
}
