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
    readonly property var ws: monitor ? monitor.activeWorkspace : null
    // звичайний стіл — номер; іменований (id < 0) — його назва
    readonly property string number: !ws ? "" : ws.id > 0 ? String(ws.id) : ws.name
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
            width: Math.max(32, numLabel.implicitWidth + 20)
            on: root.active
            hovered: root.hovered
            anchors.verticalCenter: parent.verticalCenter
            Label {
                id: numLabel
                anchors.centerIn: parent
                text: root.number
                weight: Font.Bold
                color: root.active ? Theme.accentInk : Theme.ink
                shadow: !root.active
            }
        }
    }
}
