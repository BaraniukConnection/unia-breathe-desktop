pragma Singleton
import QtQuick
import Quickshell
import "../services"

// Палітра, шрифти і «скло» Unia Breathe — одне місце для всіх кольорів і розмірів (з макета).
Singleton {
    // кольори: головний акцент і другорядні обирають у налаштуваннях («Тема»), решта палітри
    // (тло, скло, текст) відтінюється під акцент — на стандартному смарагді все як у макеті
    readonly property color defaultAccent: "#10b981"
    readonly property var defaultSecondary: ["#13eca4", "#5b9bff", "#f59e0b", "#b57bf9"]
    readonly property var colors: Prefs.data.theme ?? ({})
    readonly property color accent: colors.accent ?? defaultAccent
    readonly property var secondary: colors.secondary ?? defaultSecondary
    readonly property real hueShift: accent.hslSaturation < 0.08 ? 0 : accent.hslHue - defaultAccent.hslHue
    readonly property real satK: Math.min(1, accent.hslSaturation / defaultAccent.hslSaturation)
    function tint(c, a) {
        c = Qt.lighter(c, 1)                       // рядок "#…" → колір
        return Qt.hsla((c.hslHue + hueShift + 1) % 1, c.hslSaturation * satK, c.hslLightness, a ?? c.a)
    }
    // відносна яскравість (WCAG) — від неї колір тексту на акценті
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
    readonly property color accentInk: luminance(accent) > 0.2 ? tint("#04231a") : "#ffffff"   // текст на акцентному тлі

    // розмиття під поверхнями (тумблер «Розмиття» в налаштуваннях)
    readonly property bool blur: (Prefs.data.hypr ?? {})["decoration:blur:enabled"] !== 0

    // скло: тло всіх поверхонь, щільніше для меню, плитки й обвідка; розмиття вимкнене — тло суцільне
    readonly property color glass: blur ? tint(Qt.rgba(8 / 255, 30 / 255, 25 / 255, 0.35)) : tint("#0d2a24")
    readonly property color glassStrong: blur ? tint(Qt.rgba(8 / 255, 30 / 255, 25 / 255, 0.62)) : tint("#081e19")
    readonly property color pane: Qt.rgba(1, 1, 1, 0.09)
    readonly property color paneHover: Qt.rgba(1, 1, 1, 0.15)
    readonly property color paneLine: Qt.rgba(1, 1, 1, 0.14)

    // кольорові мітки: другорядні кольори теми (червоний — завжди червоний: закрити, помилки)
    readonly property color mint: secondary[0] ?? defaultSecondary[0]
    readonly property color blue: secondary[1] ?? defaultSecondary[1]
    readonly property color amber: secondary[2] ?? defaultSecondary[2]
    readonly property color purple: secondary[3] ?? defaultSecondary[3]
    readonly property color red: "#f26464"
    readonly property color emerald: accent

    // шрифти
    readonly property string font: "Manrope"
    readonly property string icons: "Material Symbols Outlined"
    readonly property int fontSize: 14

    // розміри
    // режим фокусу (кругла кнопка на верхній панелі): верхня панель нижча й суцільна — див. bar/Bar.qml
    readonly property bool focusMode: Prefs.data.focusMode ?? false
    readonly property int bubbleHeight: focusMode ? 30 : 44
    readonly property int edge: 20          // відступ бульбашок від країв екрана
    readonly property int top: focusMode ? 4 : 16           // відступ бульбашок зверху
    readonly property int gap: 10
    readonly property int radiusWindow: 26
    readonly property int radiusTile: 18
}
