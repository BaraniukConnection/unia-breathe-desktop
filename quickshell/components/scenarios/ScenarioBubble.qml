import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../../theme"
import "../../services"

// "Scenario · OxygenDev" for this monitor's desk; "Empty" when no scenario was opened or its apps changed.
// The wheel scrolls through names (launching nothing); a click on the chosen name opens that scenario.
Bubble {
    id: root
    required property var screen
    readonly property var monitor: Hyprland.monitorFor(screen)
    readonly property int wsId: monitor && monitor.activeWorkspace ? monitor.activeWorkspace.id : 0
    readonly property string current: Scenarios.nameFor(wsId)
    property string pending: ""             // the name scrolled to with the wheel

    popup: pending === "" ? "ws" : ""
    popupScreen: screen
    active: Popups.isOpen("ws", screen)

    onClicked: if (pending !== "") { Scenarios.load(pending); pending = "" }
    onWheel: w => {
        if (Math.abs(w.angleDelta.y) < 60 || Scenarios.list.length === 0) return
        const names = Scenarios.list.map(s => s.name)
        const from = names.indexOf(pending || current)
        const i = Math.max(0, Math.min(names.length - 1, from + (w.angleDelta.y < 0 ? 1 : -1)))
        pending = names[i] === current ? "" : names[i]
        reset.restart()
    }
    Timer { id: reset; interval: 4000; onTriggered: root.pending = "" }

    Row {
        height: parent.height
        spacing: 10
        Label { text: root.pending ? "Open?" : "Scenario"; size: 13; muted: true; anchors.verticalCenter: parent.verticalCenter }
        Pill {
            anchors.verticalCenter: parent.verticalCenter
            width: val.implicitWidth + 28
            on: root.active
            hovered: root.hovered
            border.color: root.pending ? Theme.accent : Theme.paneLine
            Row {
                id: val
                anchors.centerIn: parent
                spacing: 6
                Label {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Scenarios.loading ? Scenarios.loading + "…" : root.pending || root.current || "Empty"
                    weight: Font.Bold
                    color: root.active ? Theme.accentInk : Theme.ink
                    shadow: !root.active
                }
            }
        }
    }
}
