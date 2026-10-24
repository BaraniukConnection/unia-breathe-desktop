import QtQuick
import Quickshell
import "../theme"
import "../services"

// Date and time in the middle; a click opens the calendar.
Bubble {
    id: root
    required property var screen
    padLeft: 18
    padRight: 18
    popup: "cal"
    popupScreen: screen
    active: Popups.isOpen("cal", screen)

    SystemClock { id: clock; precision: SystemClock.Minutes }

    Row {
        height: parent.height
        spacing: 12
        Label {
            anchors.verticalCenter: parent.verticalCenter
            text: Theme.locale.toString(clock.date, "d MMM")
            muted: true
        }
        Label {
            anchors.verticalCenter: parent.verticalCenter
            text: Qt.formatTime(clock.date, Prefs.data.clock24 !== false ? "HH:mm" : "h:mm AP")
            size: 15
            weight: Font.ExtraBold
        }
    }
}
