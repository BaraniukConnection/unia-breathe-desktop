import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../theme"
import "../services"

// Відкриті столи (кружечки з номерами) і «+» — новий стіл. Сценарії додаються на етапі 4.
Glass {
    id: root
    required property var screen
    readonly property var monitor: Hyprland.monitorFor(screen)
    width: 384
    height: col.implicitHeight + 24
    readonly property var list: Hyprland.workspaces.values.filter(w => w.id > 0).sort((a, b) => a.id - b.id)

    Column {
        id: col
        x: 12; y: 12
        width: parent.width - 24
        Section {
            width: parent.width
            Item { width: parent.width; height: 40; Label { anchors.verticalCenter: parent.verticalCenter; text: "Відкриті столи"; weight: Font.Bold } }
            Flow {
                width: parent.width
                spacing: 8
                bottomPadding: 8
                Repeater {
                    model: root.list
                    Rectangle {
                        required property var modelData
                        readonly property bool on: root.monitor && root.monitor.activeWorkspace === modelData
                        width: 40; height: 40; radius: 20
                        color: on ? Theme.accent : dotArea.containsMouse ? Qt.rgba(1, 1, 1, 0.22) : Theme.paneHover
                        border.width: on ? 0 : 1
                        border.color: Theme.paneLine
                        Label { anchors.centerIn: parent; text: modelData.id; weight: Font.Bold; color: parent.on ? Theme.accentInk : Theme.ink; shadow: !parent.on }
                        MouseArea {
                            id: dotArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: { Hyprland.dispatch(`focusmonitor ${root.monitor.name}`); Hyprland.dispatch(`workspace ${modelData.id}`) }
                        }
                    }
                }
                Rectangle {
                    width: 40; height: 40; radius: 20
                    color: "transparent"
                    border.width: 1
                    border.color: Theme.inkMuted
                    Icon { anchors.centerIn: parent; name: "add"; color: Theme.inkMuted }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: { Hyprland.dispatch(`focusmonitor ${root.monitor.name}`); Hyprland.dispatch("workspace empty"); Popups.close() }
                    }
                }
            }
        }
    }
}
