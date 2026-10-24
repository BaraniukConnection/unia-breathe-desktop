import QtQuick
import Quickshell
import Quickshell.Wayland
import "../theme"
import "../services"
import "../dock"
import "../components/tile-menu"

// The layer under the bar that holds popups. It takes clicks only inside the popup itself;
// a click elsewhere closes it through the focus grab (shell.qml), Esc from the keyboard.
PanelWindow {
    id: pl
    required property var modelData
    screen: modelData
    // the layer always exists: the focus grab must know it in advance, or a click inside the popup counts as outside
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

        // the wrapper only slides in a little on show; where the popup sits is set by its component below
        Item {
            id: wrap
            width: parent.width
            height: parent.height
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
                    case "menu": return menuPanel
                    }
                    return null
                }
                onLoaded: {
                    wrap.opacity = 0
                    wrap.y = Popups.current === "menu" ? 12 : -8      // the menu comes from below, the rest from above
                    appear.restart()
                }
            }
            ParallelAnimation {
                id: appear
                NumberAnimation { target: wrap; property: "opacity"; to: 1; duration: 180; easing.type: Easing.OutCubic }
                NumberAnimation { target: wrap; property: "y"; to: 0; duration: 180; easing.type: Easing.OutCubic }
            }
        }
    }

    Component { id: calendar; Calendar { x: pl.centred(width); y: pl.y0 } }
    Component { id: mediaCenter; MediaCenter { x: Math.min(pl.width - width - Theme.edge, Popups.anchorLeft); y: pl.y0 } }
    Component { id: powerMenu; PowerMenu { x: Popups.anchorRight - width; y: pl.y0 } }
    Component { id: menuPanel; MenuPanel { screen: pl.screen; maxWidth: pl.width - 40; maxHeight: pl.height - 124 - 20; x: (pl.width - width) / 2; y: pl.height - 124 - height } }
    Component { id: controlCenter; ControlCenter { x: pl.width - width - Theme.edge; y: pl.y0 } }
    Component { id: wsList; WorkspaceList { screen: pl.screen; x: Theme.edge; y: pl.y0 } }
}
