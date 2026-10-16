pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../../services"

// Параметри Hyprland для власних сторінок: читає поточні значення (hyprctl getoption),
// змінює наживо (hyprctl keyword) і запам'ятовує в Prefs, щоб пережили перезапуск.
Singleton {
    id: root
    readonly property var keys: [
        "general:gaps_in", "general:gaps_out", "general:border_size", "decoration:rounding",
        "decoration:active_opacity", "decoration:inactive_opacity",
        "decoration:blur:enabled", "decoration:blur:size", "decoration:blur:passes",
        "input:sensitivity", "input:accel_profile", "input:natural_scroll", "input:left_handed", "input:scroll_factor",
        "input:kb_layout", "input:kb_variant", "input:kb_options",
    ]
    property var values: ({})

    function get(key, fallback) { return values[key] ?? fallback }

    function set(key, value) {
        const v = Object.assign({}, values)
        v[key] = value
        values = v
        Quickshell.execDetached(["hyprctl", "keyword", key, String(value)])
        Prefs.setHypr(key, value)
    }

    function refresh() { reader.running = true }
    Component.onCompleted: refresh()

    Process {
        id: reader
        command: ["sh", "-c", root.keys.map(k => `hyprctl getoption ${k} -j | tr -d '\\n'; echo`).join("; ")]
        stdout: StdioCollector {
            onStreamFinished: {
                const v = {}
                for (const line of text.split("\n")) {
                    try {
                        const o = JSON.parse(line)
                        v[o.option] = "int" in o ? o.int : "float" in o ? o.float
                            : "custom" in o ? parseFloat(o.custom) : o.str === "[[EMPTY]]" ? "" : o.str
                    } catch (e) {}
                }
                root.values = v
            }
        }
    }
}
