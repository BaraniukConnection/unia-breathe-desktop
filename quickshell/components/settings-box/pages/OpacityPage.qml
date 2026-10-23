import QtQuick
import "../../../theme"
import "../../../services"
import ".."

Page {
    title: "Прозорість"
    subtitle: "Прозорість вікон і розмиття під ними. Зміни видно одразу."
    Group {
        title: "ВІКНА"
        SettingRow {
            label: "Активне вікно"
            Slider { from: 0.3; to: 1; step: 0.05; unit: "%"; value: HyprOpts.get("decoration:active_opacity", 1); display: value * 100; onMoved: v => HyprOpts.set("decoration:active_opacity", v) }
        }
        SettingRow {
            label: "Неактивні вікна"
            hint: "Вікна, з якими ти зараз не працюєш"
            Slider { from: 0.3; to: 1; step: 0.05; unit: "%"; value: HyprOpts.get("decoration:inactive_opacity", 1); display: value * 100; onMoved: v => HyprOpts.set("decoration:inactive_opacity", v) }
        }
    }
    Group {
        title: "РОЗМИТТЯ"
        SettingRow {
            label: "Розмиття"
            hint: "Скляний ефект під прозорими вікнами й панелями"
            Toggle { checked: HyprOpts.get("decoration:blur:enabled", 1) === 1; onToggled: v => HyprOpts.set("decoration:blur:enabled", v ? 1 : 0) }
        }
        SettingRow {
            label: "Сила"
            Slider { from: 1; to: 20; step: 1; decimals: 0; value: HyprOpts.get("decoration:blur:size", 8); onMoved: v => HyprOpts.set("decoration:blur:size", v) }
        }
        SettingRow {
            label: "Проходи"
            hint: "Більше — м'якше, але важче для відеокарти"
            Slider { from: 1; to: 4; step: 1; decimals: 0; value: HyprOpts.get("decoration:blur:passes", 1); onMoved: v => HyprOpts.set("decoration:blur:passes", v) }
        }
    }
}
