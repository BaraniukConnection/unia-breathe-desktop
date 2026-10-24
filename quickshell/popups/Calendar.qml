import QtQuick
import Quickshell
import "../theme"
import "../services"

// Calendar: the month, ‹ › to switch, a grid of days from Monday, today highlighted.
Glass {
    id: root
    width: 328
    height: col.implicitHeight + 24
    property date today: new Date()
    property int year: today.getFullYear()
    property int month: today.getMonth()
    readonly property var loc: Theme.locale

    function shift(d) {
        const m = month + d
        year += Math.floor(m / 12)
        month = (m % 12 + 12) % 12
    }

    Column {
        id: col
        x: 12; y: 12
        width: parent.width - 24
        spacing: 12

        Section {
            width: parent.width
            Item {
                width: parent.width
                height: 40
                Label {
                    anchors.verticalCenter: parent.verticalCenter
                    text: { const n = root.loc.standaloneMonthName(root.month); return n.charAt(0).toUpperCase() + n.slice(1) + " " + root.year }
                    weight: Font.Bold
                }
                Row {
                    anchors.right: parent.right
                    anchors.rightMargin: -8
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2
                    IconButton { implicitWidth: 32; implicitHeight: 32; icon: "chevron_left"; muted: true; onClicked: root.shift(-1) }
                    IconButton { implicitWidth: 32; implicitHeight: 32; icon: "chevron_right"; muted: true; onClicked: root.shift(1) }
                }
            }
            Grid {
                columns: 7
                width: parent.width
                Repeater {
                    model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
                    Label { required property string modelData; text: modelData; width: col.width / 7 - 4; height: 28; horizontalAlignment: Text.AlignHCenter; size: 12; muted: true; weight: Font.Bold }
                }
                Repeater {
                    model: 42
                    Item {
                        required property int index
                        readonly property int lead: (new Date(root.year, root.month, 1).getDay() + 6) % 7
                        readonly property date day: new Date(root.year, root.month, 1 - lead + index)
                        readonly property bool other: day.getMonth() !== root.month
                        readonly property bool isToday: day.toDateString() === root.today.toDateString()
                        readonly property var events: Events.onDay(day)
                        width: col.width / 7 - 4
                        height: 36
                        Rectangle {
                            anchors.centerIn: parent
                            width: 32; height: 32; radius: 16
                            color: parent.isToday ? Theme.accent : "transparent"
                        }
                        Label {
                            anchors.centerIn: parent
                            text: parent.day.getDate()
                            weight: parent.isToday ? Font.ExtraBold : Font.DemiBold
                            color: parent.isToday ? Theme.accentInk : parent.other ? Qt.rgba(0.75, 0.89, 0.84, 0.4) : Theme.ink
                            shadow: !parent.isToday
                        }
                        Rectangle {
                            visible: parent.events.length > 0
                            width: 4; height: 4; radius: 2
                            color: parent.isToday ? Theme.accentInk : Theme.accent
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: parent.height / 2 + 9
                        }
                    }
                }
            }
        }

        // The next event (or a hint on connecting Google Calendar)
        Rectangle {
            width: parent.width
            height: nextCol.implicitHeight + 20
            radius: 26
            color: Theme.pane
            border.width: 1
            border.color: Theme.paneLine
            Column {
                id: nextCol
                x: 18; y: 10
                width: parent.width - 36
                spacing: 2
                Label { text: Events.configured ? "NEXT EVENT" : "GOOGLE CALENDAR"; size: 11; weight: Font.Bold; muted: true; font.letterSpacing: 1.2 }
                Item {
                    width: parent.width
                    height: 20
                    Label {
                        width: parent.width - when.implicitWidth - 12
                        text: !Events.configured ? "Not connected" : Events.next ? Events.next.title : "No events"
                        weight: Font.Bold
                        elide: Text.ElideRight
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Label {
                        id: when
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        size: 13
                        muted: true
                        text: {
                            const e = Events.next
                            if (!Events.configured || !e) return ""
                            const d0 = new Date(root.today.getFullYear(), root.today.getMonth(), root.today.getDate())
                            const days = Math.round((new Date(e.start.getFullYear(), e.start.getMonth(), e.start.getDate()) - d0) / 864e5)
                            const day = days === 0 ? "today" : days === 1 ? "tomorrow" : root.loc.toString(e.start, "d MMM")
                            return e.allDay ? day : `${day}, ${Qt.formatTime(e.start, "HH:mm")}`
                        }
                    }
                }
            }
        }
    }
}
