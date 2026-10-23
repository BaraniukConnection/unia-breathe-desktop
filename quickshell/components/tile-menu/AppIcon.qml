import QtQuick
import Quickshell.Widgets
import "../../services"

// Іконка програми з теми іконок (за id .desktop-файлу).
IconImage {
    property string app
    readonly property var entry: Apps.byId(app)
    source: Apps.icon(entry)
    implicitSize: 40
    asynchronous: true
}
