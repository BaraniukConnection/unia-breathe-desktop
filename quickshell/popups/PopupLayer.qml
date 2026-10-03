import QtQuick
import Quickshell
import Quickshell.Wayland
import "../theme"
import "../services"

// Шар під смугою для спливаючих вікон. Ловить кліки лише в межах самого вікна;
// клік деінде закриває його через focus grab (shell.qml), Esc — з клавіатури.
PanelWindow {
    id: pl
    required property var modelData
    screen: modelData
    // шар існує завжди: focus grab має знати про нього заздалегідь, інакше клік у панелі вважається «повз»
    readonly property bool open: Popups.current !== "" && Popups.screen === modelData

    WlrLayershell.namespace: "unia-popup"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }
    margins.top: Theme.top + Theme.bubbleHeight
    color: "transparent"

    readonly property real y0: 10
    function centred(w) { return Math.max(Theme.edge, Math.min(width - w - Theme.edge, Popups.anchorCenter - w / 2)) }

    mask: Region { item: pl.open && loader.item ? loader.item : nothing }
    Item { id: nothing }

    Item {
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: Popups.close()

        Loader {
            id: loader
            active: pl.open
            sourceComponent: {
                switch (Popups.current) {
                case "cal": return calendar
                case "media": return mediaCenter
                case "power": return powerMenu
                case "ws": return wsList
                case "nc": return controlCenter
                }
                return null
            }
            onLoaded: { item.opacity = 0; item.y = pl.y0 - 8; appear.restart() }
            ParallelAnimation {
                id: appear
                NumberAnimation { target: loader.item; property: "opacity"; to: 1; duration: 180; easing.type: Easing.OutCubic }
                NumberAnimation { target: loader.item; property: "y"; to: pl.y0; duration: 180; easing.type: Easing.OutCubic }
            }
        }
    }

    Component { id: calendar; Calendar { x: pl.centred(width) } }
    Component { id: mediaCenter; MediaCenter { x: Math.min(pl.width - width - Theme.edge, Popups.anchorLeft) } }
    Component { id: powerMenu; PowerMenu { x: Popups.anchorRight - width } }
    Component { id: controlCenter; ControlCenter { x: pl.width - width - Theme.edge } }
    Component { id: wsList; WorkspaceList { screen: pl.screen; x: Theme.edge } }
}
