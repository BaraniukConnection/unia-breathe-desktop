import QtQuick
import Quickshell
import Quickshell.Io
import "../../../theme"
import "../../../services"

// Date and time: time zone, automatic sync (timedatectl), the clock format on the bar.
Page {
    id: page
    title: "Date & Time"
    subtitle: "Changing the time zone or sync asks for your password: these are system settings."
    property var info: ({})
    property var zones: []

    function run(cmd) { act.command = cmd; act.running = true }
    Process { id: show; running: true; command: ["timedatectl", "show"]
        stdout: StdioCollector { onStreamFinished: { const o = {}; for (const l of text.split("\n")) { const i = l.indexOf("="); if (i > 0) o[l.slice(0, i)] = l.slice(i + 1) } page.info = o } } }
    Process { running: true; command: ["timedatectl", "list-timezones"]
        stdout: StdioCollector { onStreamFinished: page.zones = text.trim().split("\n").map(z => ({ value: z, label: z.replace(/_/g, " ") })) } }
    Process { id: act; onExited: show.running = true }

    SystemClock { id: clock; precision: SystemClock.Seconds }

    Group {
        Item {
            width: parent.width
            height: 96
            Column {
                anchors.verticalCenter: parent.verticalCenter
                Label { text: Qt.formatTime(clock.date, Prefs.data.clock24 ? "HH:mm:ss" : "h:mm:ss AP"); size: 40; weight: Font.ExtraBold }
                Label { text: Theme.locale.toString(clock.date, "dddd, d MMMM yyyy") + " · " + (page.info.Timezone ?? ""); muted: true }
            }
        }
    }
    Group {
        title: "TIME"
        SettingRow {
            label: "Set automatically"
            hint: page.info.NTPSynchronized === "yes" ? "Synced with internet time" : "Not synced"
            Toggle { checked: page.info.NTP === "yes"; onToggled: v => page.run(["timedatectl", "set-ntp", v ? "true" : "false"]) }
        }
        SettingRow {
            label: "24-hour clock"
            hint: "How the top bar shows the time"
            Toggle { checked: Prefs.data.clock24 !== false; onToggled: v => Prefs.set("clock24", v) }
        }
    }
    Group {
        title: "TIME ZONE"
        SearchList {
            items: page.zones
            current: page.info.Timezone ?? ""
            placeholder: "Search for a city or region (e.g. Kyiv, Berlin)"
            onPicked: v => page.run(["timedatectl", "set-timezone", v])
        }
    }
}
