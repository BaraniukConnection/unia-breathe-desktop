import QtQuick
import "../../../theme"
import "../../../services"
import ".."

Page {
    id: page
    title: "Тема"
    subtitle: "Кольори оболонки й рамок вікон, прозорість і розмиття. Зміни видно одразу."

    // що зараз редагуємо: -1 — головний акцент, 0… — другорядний, -2 — нічого
    property int slot: -2
    readonly property color editing: slot === -1 ? Theme.accent : slot >= 0 ? Theme.secondary[slot] : "transparent"

    // зберегти кольори теми й перефарбувати рамки вікон (акцент → перший другорядний)
    function save(accent, secondary) {
        Prefs.set("theme", { accent: String(accent), secondary: secondary.map(String) })
        HyprOpts.set("general:col.active_border",
            `rgba(${Theme.hex(Theme.accent, 0xee / 255)}) rgba(${Theme.hex(Theme.mint, 0.6)}) 45deg`)
        HyprOpts.set("general:col.inactive_border", `rgba(${Theme.hex(Theme.ink, 0.1)})`)
    }
    function pick(c) {
        const sec = Theme.secondary.slice()
        if (slot === -1) save(c, sec)
        else { sec[slot] = c; save(Theme.accent, sec) }
    }
    // другорядний стає головним, а колишній головний — на його місце серед другорядних
    function promote() {
        const sec = Theme.secondary.slice()
        const old = Theme.accent
        const c = sec[slot]
        sec[slot] = old
        save(c, sec)
        slot = -1
    }
    readonly property bool custom: !!Prefs.data.theme

    Group {
        title: "КОЛЬОРИ"
        SettingRow {
            label: "Головний акцент"
            hint: "Кнопки, перемикачі, підсвічування, активна рамка вікна"
            Swatch {
                width: 40; height: 40
                color: Theme.accent
                selected: page.slot === -1
                onClicked: page.slot = page.slot === -1 ? -2 : -1
            }
        }
        SettingRow {
            label: "Другорядні"
            hint: "Другий колір рамки й мітки сценаріїв. Будь-який можна зробити головним"
            Row {
                spacing: 12
                Repeater {
                    model: Theme.secondary
                    Swatch {
                        required property var modelData
                        required property int index
                        anchors.verticalCenter: parent.verticalCenter
                        color: modelData
                        selected: page.slot === index
                        onClicked: page.slot = page.slot === index ? -2 : index
                    }
                }
            }
        }
        // редактор вибраного кольору — розкривається під рядками
        Item {
            width: parent.width
            height: page.slot > -2 ? editor.implicitHeight + 16 : 0
            clip: true
            visible: height > 0
            Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
            ColorEditor {
                id: editor
                y: 4
                value: page.editing
                canPromote: page.slot >= 0
                onPicked: c => page.pick(c)
                onPromote: page.promote()
                onDone: page.slot = -2
            }
        }
        SettingRow {
            visible: page.custom
            label: "Стандартні кольори"
            hint: "Повернути смарагдову тему Unia Breathe"
            Rectangle {
                width: resetLbl.implicitWidth + 28; height: 36; radius: 18
                color: resetArea.containsMouse ? Theme.paneHover : Theme.pane
                border.width: 1; border.color: Theme.paneLine
                Label { id: resetLbl; anchors.centerIn: parent; text: "Скинути"; size: 13; weight: Font.Bold }
                MouseArea {
                    id: resetArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: { page.save(Theme.defaultAccent, Theme.defaultSecondary); Prefs.set("theme", null); page.slot = -2 }
                }
            }
        }
    }
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
            hint: HyprOpts.get("decoration:blur:enabled", 1) === 1
                ? "Скляний ефект під прозорими вікнами й панелями"
                : "Вимкнено: панелі щільніші, щоб текст читався без розмиття"
            Toggle { checked: HyprOpts.get("decoration:blur:enabled", 1) === 1; onToggled: v => HyprOpts.set("decoration:blur:enabled", v ? 1 : 0) }
        }
        SettingRow {
            visible: HyprOpts.get("decoration:blur:enabled", 1) === 1
            label: "Сила"
            Slider { from: 1; to: 20; step: 1; decimals: 0; value: HyprOpts.get("decoration:blur:size", 8); onMoved: v => HyprOpts.set("decoration:blur:size", v) }
        }
        SettingRow {
            visible: HyprOpts.get("decoration:blur:enabled", 1) === 1
            label: "Проходи"
            hint: "Більше — м'якше, але важче для відеокарти"
            Slider { from: 1; to: 4; step: 1; decimals: 0; value: HyprOpts.get("decoration:blur:passes", 1); onMoved: v => HyprOpts.set("decoration:blur:passes", v) }
        }
    }
}
