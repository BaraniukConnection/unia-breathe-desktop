import QtQuick
import "../../../theme"
import "../../../services"
import ".."

Page {
    title: "Мишка"
    subtitle: "Загальні налаштування для всіх мишок і тачпадів (Logitech Lift тощо)."
    Group {
        title: "РУХ"
        SettingRow {
            label: "Швидкість курсора"
            Slider { from: -1; to: 1; step: 0.05; value: HyprOpts.get("input:sensitivity", 0); onMoved: v => HyprOpts.set("input:sensitivity", v) }
        }
        SettingRow {
            label: "Прискорення"
            hint: "Без прискорення курсор рухається рівно стільки, скільки рука"
            Choice {
                options: [{ value: "adaptive", label: "Адаптивне" }, { value: "flat", label: "Без прискорення" }]
                current: HyprOpts.get("input:accel_profile", "") === "flat" ? "flat" : "adaptive"
                onChosen: v => HyprOpts.set("input:accel_profile", v)
            }
        }
    }
    Group {
        title: "ПРОКРУЧУВАННЯ І КНОПКИ"
        SettingRow {
            label: "Швидкість прокручування"
            Slider { from: 0.2; to: 3; step: 0.1; decimals: 1; unit: "×"; value: HyprOpts.get("input:scroll_factor", 1); onMoved: v => HyprOpts.set("input:scroll_factor", v) }
        }
        SettingRow {
            label: "Природне прокручування"
            hint: "Вміст рухається за пальцем, як на телефоні"
            Toggle { checked: HyprOpts.get("input:natural_scroll", 0) === 1; onToggled: v => HyprOpts.set("input:natural_scroll", v ? 1 : 0) }
        }
        SettingRow {
            label: "Для лівої руки"
            hint: "Міняє місцями ліву й праву кнопки"
            Toggle { checked: HyprOpts.get("input:left_handed", 0) === 1; onToggled: v => HyprOpts.set("input:left_handed", v ? 1 : 0) }
        }
    }
}
