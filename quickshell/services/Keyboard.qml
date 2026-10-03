pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

// Поточна розкладка клавіатури (з hyprctl і подій Hyprland) та її перемикання.
Singleton {
    id: root
    property string name: ""
    readonly property var codes: ({ "English (US)": "us", "Ukrainian": "ua" })
    readonly property string code: codes[name] ?? name.slice(0, 2).toLowerCase()
    readonly property var names: ({ "English (US)": "English (US)", "Ukrainian": "Українська" })
    readonly property string label: names[name] ?? name

    function next() { switcher.running = true }

    Process {
        running: true
        command: ["hyprctl", "devices", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                const kbs = JSON.parse(text).keyboards
                const k = kbs.find(k => k.main) ?? kbs[0]
                if (k) root.name = k.active_keymap
            }
        }
    }
    Process { id: switcher; command: ["hyprctl", "switchxkblayout", "all", "next"] }

    Connections {
        target: Hyprland
        function onRawEvent(ev) {
            if (ev.name === "activelayout") root.name = ev.data.split(",").slice(1).join(",")
        }
    }
}
