import QtQuick
import "../../../theme"
import "../../../services"
import ".."

Page {
    title: "Mouse"
    subtitle: "Shared settings for every mouse and touchpad."
    Group {
        title: "MOVEMENT"
        SettingRow {
            label: "Pointer speed"
            Slider { from: -1; to: 1; step: 0.05; value: HyprOpts.get("input:sensitivity", 0); onMoved: v => HyprOpts.set("input:sensitivity", v) }
        }
        SettingRow {
            label: "Acceleration"
            hint: "Without acceleration the pointer moves exactly as far as your hand"
            Choice {
                options: [{ value: "adaptive", label: "Adaptive" }, { value: "flat", label: "None" }]
                current: HyprOpts.get("input:accel_profile", "") === "flat" ? "flat" : "adaptive"
                onChosen: v => HyprOpts.set("input:accel_profile", v)
            }
        }
    }
    Group {
        title: "SCROLLING AND BUTTONS"
        SettingRow {
            label: "Scroll speed"
            Slider { from: 0.2; to: 3; step: 0.1; decimals: 1; unit: "×"; value: HyprOpts.get("input:scroll_factor", 1); onMoved: v => HyprOpts.set("input:scroll_factor", v) }
        }
        SettingRow {
            label: "Natural scrolling"
            hint: "Content follows your finger, as on a phone"
            Toggle { checked: HyprOpts.get("input:natural_scroll", 0) === 1; onToggled: v => HyprOpts.set("input:natural_scroll", v ? 1 : 0) }
        }
        SettingRow {
            label: "Left-handed"
            hint: "Swaps the left and right buttons"
            Toggle { checked: HyprOpts.get("input:left_handed", 0) === 1; onToggled: v => HyprOpts.set("input:left_handed", v ? 1 : 0) }
        }
    }
}
