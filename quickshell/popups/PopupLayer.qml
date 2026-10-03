import QtQuick
import Quickshell
import Quickshell.Wayland
import "../theme"
import "../services"

// Шар під смугою для спливаючих вікон. Клік повз вікно або Esc закриває його.
PanelWindow {
    id: pl
    required property var modelData
    screen: modelData
    // шар з'являється на всіх моніторах: клік будь-де повз панель її закриває; вміст — лише на «своєму» моніторі
    visible: Popups.current !== ""
    readonly property bool home: Popups.screen === modelData

    WlrLayershell.namespace: "unia-popup"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: home ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }
    margins.top: Theme.top + Theme.bubbleHeight
    color: "transparent"

    readonly property real y0: 10
    function centred(w) { return Math.max(Theme.edge, Math.min(width - w - Theme.edge, Popups.anchorCenter - w / 2)) }

    MouseArea { anchors.fill: parent; onClicked: Popups.close() }

    Item {
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: Popups.close()

        Loader {
            id: loader
            active: pl.visible && pl.home
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
