pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

// The current keyboard layout (from hyprctl and Hyprland events) and switching it.
Singleton {
    id: root
    property string name: ""
    property string code: ""                 // code of the active layout from kb_layout (us, ua, de…)
    readonly property var names: ({ "English (US)": "English (US)", "Ukrainian": "Ukrainian" })
    readonly property string label: names[name] ?? name

    function next() { switcher.running = true }

    Process {
        id: query
        running: true
        command: ["hyprctl", "devices", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                const kbs = JSON.parse(text).keyboards
                const k = kbs.find(k => k.main) ?? kbs[0]
                if (!k) return
                root.name = k.active_keymap
                root.code = (k.layout.split(",")[k.active_layout_index] ?? k.active_keymap.slice(0, 2)).toLowerCase()
            }
        }
    }
    Process { id: switcher; command: ["hyprctl", "switchxkblayout", "all", "next"] }

    Connections {
        target: Hyprland
        function onRawEvent(ev) {
            if (ev.name === "activelayout") query.running = true
        }
    }
}
