import QtQuick
import Quickshell
import Quickshell.Io
import "../../../theme"
import "../../../services"

// Час і дата: часовий пояс, автоматична синхронізація (timedatectl), формат годинника на смузі.
Page {
    id: page
    title: "Час і дата"
    subtitle: "Зміна часового поясу й синхронізації просить пароль — це системні налаштування."
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
                Label { text: Qt.locale("uk_UA").toString(clock.date, "dddd, d MMMM yyyy") + " · " + (page.info.Timezone ?? ""); muted: true }
            }
        }
    }
    Group {
        title: "ЧАС"
        SettingRow {
            label: "Синхронізувати автоматично"
            hint: page.info.NTPSynchronized === "yes" ? "Час звірено з інтернетом" : "Час не синхронізовано"
            Toggle { checked: page.info.NTP === "yes"; onToggled: v => page.run(["timedatectl", "set-ntp", v ? "true" : "false"]) }
        }
        SettingRow {
            label: "24-годинний формат"
            hint: "Як показувати час на верхній смузі"
            Toggle { checked: Prefs.data.clock24 !== false; onToggled: v => Prefs.set("clock24", v) }
        }
    }
    Group {
        title: "ЧАСОВИЙ ПОЯС"
        SearchList {
            items: page.zones
            current: page.info.Timezone ?? ""
            placeholder: "Пошук міста або регіону (напр. Kyiv, Berlin)"
            onPicked: v => page.run(["timedatectl", "set-timezone", v])
        }
    }
}
