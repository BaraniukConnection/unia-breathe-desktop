import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../theme"
import "../services"

// «Стіл · ①» — номер столу цього монітора. Колесо — сусідній стіл, клік — список столів.
Bubble {
    id: root
    required property var screen
    readonly property var monitor: Hyprland.monitorFor(screen)
    readonly property int number: monitor && monitor.activeWorkspace ? monitor.activeWorkspace.id : 0
    popup: "ws"
    popupScreen: screen
    active: Popups.isOpen("ws", screen)
    onWheel: w => {
        if (Math.abs(w.angleDelta.y) < 60) return
        Hyprland.dispatch(`focusmonitor ${monitor.name}`)
        Hyprland.dispatch(w.angleDelta.y < 0 ? "workspace m+1" : "workspace m-1")
    }

    Row {
        height: parent.height
        spacing: 10
        Label { text: "Стіл"; size: 13; muted: true; anchors.verticalCenter: parent.verticalCenter }
        Pill {
            width: 32
            on: root.active
            hovered: root.hovered
            anchors.verticalCenter: parent.verticalCenter
            Label {
                anchors.centerIn: parent
                text: root.number
                weight: Font.Bold
                color: root.active ? Theme.accentInk : Theme.ink
                shadow: !root.active
            }
        }
    }
}
