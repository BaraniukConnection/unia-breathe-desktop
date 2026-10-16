import QtQuick
import Quickshell
import Quickshell.Wayland
import "../theme"
import "../services"
import "../dock"
import "../components/app-menu"

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

        // обгортка лише трохи «виїжджає» при появі; де стоїть саме вікно — задає його компонент нижче
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
                    wrap.y = Popups.current === "menu" ? 12 : -8      // меню — знизу, решта — згори
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
