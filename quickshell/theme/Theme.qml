pragma Singleton
import QtQuick
import Quickshell
import "../services"

// Палітра, шрифти і «скло» Unia Breathe — одне місце для всіх кольорів і розмірів (з макета).
Singleton {
    // кольори
    readonly property color base: "#0b2a26"
    readonly property color ink: "#eaf6f0"
    readonly property color inkMuted: "#bfe3d5"
    readonly property color accent: "#10b981"
    readonly property color accentInk: "#04231a"   // текст на акцентному тлі

    // скло: тло всіх поверхонь, щільніше для меню, плитки й обвідка
    readonly property color glass: Qt.rgba(8 / 255, 30 / 255, 25 / 255, 0.35)
    readonly property color glassStrong: Qt.rgba(8 / 255, 30 / 255, 25 / 255, 0.62)
    readonly property color pane: Qt.rgba(1, 1, 1, 0.09)
    readonly property color paneHover: Qt.rgba(1, 1, 1, 0.15)
    readonly property color paneLine: Qt.rgba(1, 1, 1, 0.14)

    // кольорові мітки
    readonly property color mint: "#13eca4"
    readonly property color blue: "#5b9bff"
    readonly property color amber: "#f59e0b"
    readonly property color red: "#f26464"
    readonly property color purple: "#b57bf9"
    readonly property color emerald: "#10b981"

    // шрифти
    readonly property string font: "Manrope"
    readonly property string icons: "Material Symbols Outlined"
    readonly property int fontSize: 14

    // розміри
    // режим фокусу (кругла кнопка в меню WindowDrop): верхня панель нижча й суцільна — див. bar/Bar.qml
    readonly property bool focusMode: Prefs.data.focusMode ?? false
    readonly property int bubbleHeight: focusMode ? 30 : 44
    readonly property int edge: 20          // відступ бульбашок від країв екрана
    readonly property int top: focusMode ? 4 : 16           // відступ бульбашок зверху
    readonly property int gap: 10
    readonly property int radiusWindow: 26
    readonly property int radiusTile: 18
}
