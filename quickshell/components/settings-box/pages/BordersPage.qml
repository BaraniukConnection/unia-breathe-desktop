import QtQuick
import "../../../theme"
import "../../../services"
import ".."

Page {
    title: "Windows & Borders"
    subtitle: "Gaps between windows, borders and corner rounding."
    Group {
        title: "GAPS"
        SettingRow {
            label: "Between windows"
            Slider { from: 0; to: 30; step: 1; decimals: 0; unit: " px"; value: HyprOpts.get("general:gaps_in", 5); onMoved: v => HyprOpts.set("general:gaps_in", v) }
        }
        SettingRow {
            label: "From screen edges"
            Slider { from: 0; to: 40; step: 1; decimals: 0; unit: " px"; value: HyprOpts.get("general:gaps_out", 20); onMoved: v => HyprOpts.set("general:gaps_out", v) }
        }
    }
    Group {
        title: "LOOK"
        SettingRow {
            label: "Border width"
            Slider { from: 0; to: 6; step: 1; decimals: 0; unit: " px"; value: HyprOpts.get("general:border_size", 1); onMoved: v => HyprOpts.set("general:border_size", v) }
        }
        SettingRow {
            label: "Corner rounding"
            Slider { from: 0; to: 30; step: 1; decimals: 0; unit: " px"; value: HyprOpts.get("decoration:rounding", 10); onMoved: v => HyprOpts.set("decoration:rounding", v) }
        }
    }
}
