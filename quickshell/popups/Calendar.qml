import QtQuick
import Quickshell
import "../theme"

// Календар: місяць, перемикання ‹ ›, сітка днів з понеділка, сьогодні підсвічено.
Glass {
    id: root
    width: 328
    height: col.implicitHeight + 24
    property date today: new Date()
    property int year: today.getFullYear()
    property int month: today.getMonth()
    readonly property var loc: Qt.locale("uk_UA")

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
                    model: ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Нд"]
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
                    }
                }
            }
        }
    }
}
