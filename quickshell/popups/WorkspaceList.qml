import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../theme"
import "../services"
import "../components/scenarios"

// "Desks and scenarios": open desks, one row per monitor ("+" makes a new desk on that monitor),
// with scenarios below.
Glass {
    id: root
    required property var screen
    width: 384
    height: col.implicitHeight + 24
    readonly property var monitors: Hyprland.monitors.values.slice().sort((a, b) => a.x - b.x)

    Column {
        id: col
        x: 12; y: 12
        width: parent.width - 24
        spacing: 12
        Section {
            width: parent.width
            Item { width: parent.width; height: 40; Label { anchors.verticalCenter: parent.verticalCenter; text: "Open Desks"; weight: Font.Bold } }

            Repeater {
                model: root.monitors
                Column {
                    id: mon
                    required property var modelData
                    readonly property bool here: modelData.name === root.screen.name
                    width: parent.width
                    spacing: 6
                    bottomPadding: 8

                    // monitor name: the model from its description (DELL 2208WFP) or the output name
                    Row {
                        spacing: 6
                        Icon { name: "monitor"; font.pixelSize: 16; color: mon.here ? Theme.accent : Theme.inkMuted; anchors.verticalCenter: parent.verticalCenter }
                        Label {
                            anchors.verticalCenter: parent.verticalCenter
                            text: {
                                const d = mon.modelData.lastIpcObject ? mon.modelData.lastIpcObject.model : ""
                                return (d || mon.modelData.name) + (mon.here ? " · this monitor" : "")
                            }
                            size: 12
                            muted: true
                        }
                    }
                    Flow {
                        width: parent.width
                        spacing: 8
                        Repeater {
                            model: Hyprland.workspaces.values.filter(w => w.id > 0 && w.monitor === mon.modelData).sort((a, b) => a.id - b.id)
                            Rectangle {
                                required property var modelData
                                readonly property bool on: mon.modelData.activeWorkspace === modelData
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
                                    onClicked: Hyprland.dispatch(`workspace ${modelData.id}`)
                                }
                            }
                        }
                        Rectangle {
                            width: 40; height: 40; radius: 20
                            color: addArea.containsMouse ? Theme.pane : "transparent"
                            border.width: 1
                            border.color: Theme.inkMuted
                            Icon { anchors.centerIn: parent; name: "add"; color: Theme.inkMuted }
                            MouseArea {
                                id: addArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: { Hyprland.dispatch(`focusmonitor ${mon.modelData.name}`); Hyprland.dispatch("workspace empty"); Popups.close() }
                            }
                        }
                    }
                }
            }
        }
        ScenarioSection { width: parent.width; screen: root.screen }
    }
}
