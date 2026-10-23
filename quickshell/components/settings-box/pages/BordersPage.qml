import QtQuick
import "../../../theme"
import "../../../services"
import ".."

Page {
    title: "Вікна й межі"
    subtitle: "Відступи між вікнами, рамки й заокруглення кутів."
    Group {
        title: "ВІДСТУПИ"
        SettingRow {
            label: "Між вікнами"
            Slider { from: 0; to: 30; step: 1; decimals: 0; unit: " px"; value: HyprOpts.get("general:gaps_in", 5); onMoved: v => HyprOpts.set("general:gaps_in", v) }
        }
        SettingRow {
            label: "Від країв екрана"
            Slider { from: 0; to: 40; step: 1; decimals: 0; unit: " px"; value: HyprOpts.get("general:gaps_out", 20); onMoved: v => HyprOpts.set("general:gaps_out", v) }
        }
    }
    Group {
        title: "ВИГЛЯД"
        SettingRow {
            label: "Товщина рамки"
            Slider { from: 0; to: 6; step: 1; decimals: 0; unit: " px"; value: HyprOpts.get("general:border_size", 1); onMoved: v => HyprOpts.set("general:border_size", v) }
        }
        SettingRow {
            label: "Заокруглення кутів"
            Slider { from: 0; to: 30; step: 1; decimals: 0; unit: " px"; value: HyprOpts.get("decoration:rounding", 10); onMoved: v => HyprOpts.set("decoration:rounding", v) }
        }
    }
}
