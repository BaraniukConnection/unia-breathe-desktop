import QtQuick
import Quickshell
import "../theme"
import "../services"

// Йде запис екрана: червона крапка й час; клік — зупинити.
Bubble {
    id: root
    visible: Shot.recording
    padLeft: 14
    padRight: 16
    border.color: Theme.red
    onClicked: Shot.stopRecording()
    SystemClock { id: clock; precision: SystemClock.Seconds; enabled: Shot.recording }
    Row {
        height: parent.height
        spacing: 10
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 12; height: 12; radius: 6
            color: Theme.red
            SequentialAnimation on opacity { running: Shot.recording; loops: Animation.Infinite
                NumberAnimation { to: 0.3; duration: 700 } NumberAnimation { to: 1; duration: 700 } }
        }
        Label {
            anchors.verticalCenter: parent.verticalCenter
            weight: Font.Bold
            text: { const s = Math.max(0, Math.floor((clock.date - Shot.recStart) / 1000)); return `${Math.floor(s / 60)}:${String(s % 60).padStart(2, "0")}` }
        }
        Icon { anchors.verticalCenter: parent.verticalCenter; name: "stop_circle"; color: Theme.red }
    }
}
