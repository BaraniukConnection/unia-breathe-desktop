import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../theme"
import "../services"
import "../popups"

// Нові сповіщення у правому верхньому куті монітора з фокусом. Ховаються самі (крім важливих).
PanelWindow {
    id: win
    required property var modelData
    screen: modelData
    visible: Notifs.toasts.length > 0 && !!Hyprland.focusedMonitor && Hyprland.focusedMonitor.name === modelData.name
             && Popups.current !== "nc"

    WlrLayershell.namespace: "unia-toast"
    WlrLayershell.layer: WlrLayer.Overlay
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; right: true }
    margins { top: Theme.top + Theme.bubbleHeight + 12; right: Theme.edge }
    implicitWidth: 380
    implicitHeight: Math.max(1, stack.implicitHeight)
    color: "transparent"

    Column {
        id: stack
        width: parent.width
        spacing: 8
        Repeater {
            model: Notifs.toasts
            NotificationCard {
                id: card
                required property var modelData
                entry: modelData
                toast: true
                width: stack.width
                opacity: 0
                Component.onCompleted: fadeIn.start()
                NumberAnimation on opacity { id: fadeIn; running: false; to: 1; duration: 180 }
                Timer {
                    running: !card.critical
                    interval: card.n.expireTimeout > 0 ? card.n.expireTimeout : 6000
                    onTriggered: Notifs.hideToast(card.entry)
                }
            }
        }
    }
}
