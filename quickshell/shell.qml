import QtQuick
import Quickshell
import Quickshell.Wayland
import "theme"

// Unia Breathe — корінь оболонки. Поки що лише перевірочна бульбашка (етап 1).
ShellRoot {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData

            WlrLayershell.namespace: "unia-bubble"
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            anchors.top: true
            margins.top: Theme.top
            implicitWidth: probe.width
            implicitHeight: Theme.bubbleHeight

            Glass {
                id: probe
                height: Theme.bubbleHeight
                width: row.implicitWidth + 32
                radius: height / 2

                Row {
                    id: row
                    anchors.centerIn: parent
                    spacing: 10
                    Icon { name: "air"; color: Theme.accent; anchors.verticalCenter: parent.verticalCenter }
                    Text {
                        text: "Unia Breathe"
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize
                        font.weight: Font.DemiBold
                        color: Theme.ink
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
        }
    }
}
