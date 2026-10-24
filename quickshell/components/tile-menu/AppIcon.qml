import QtQuick
import Quickshell.Widgets
import "../../services"

// An app icon from the icon theme (by .desktop file id).
IconImage {
    property string app
    readonly property var entry: Apps.byId(app)
    source: Apps.icon(entry)
    implicitSize: 40
    asynchronous: true
}
