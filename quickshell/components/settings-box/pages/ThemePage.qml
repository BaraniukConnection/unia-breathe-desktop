import QtQuick
import "../../../theme"
import "../../../services"
import ".."

Page {
    id: page
    title: "Theme"
    subtitle: "Colours of the shell and window borders, opacity and blur. Changes show at once."

    // what is being edited: -1 the main accent, 0… a secondary colour, -2 nothing
    property int slot: -2
    readonly property color editing: slot === -1 ? Theme.accent : slot >= 0 ? Theme.secondary[slot] : "transparent"

    // save the theme colours and repaint window borders (accent → first secondary)
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
    // a secondary colour becomes the main one, and the old main one takes its place among the secondary
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
        title: "COLOURS"
        SettingRow {
            label: "Main accent"
            hint: "Buttons, switches, highlights, the active window border"
            Swatch {
                width: 40; height: 40
                color: Theme.accent
                selected: page.slot === -1
                onClicked: page.slot = page.slot === -1 ? -2 : -1
            }
        }
        SettingRow {
            label: "Secondary"
            hint: "The border's second colour and scenario marks. Any of them can become the main one"
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
        // the editor for the chosen colour opens under the rows
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
            label: "Default colours"
            hint: "Go back to the Unia Breathe Desktop emerald"
            Rectangle {
                width: resetLbl.implicitWidth + 28; height: 36; radius: 18
                color: resetArea.containsMouse ? Theme.paneHover : Theme.pane
                border.width: 1; border.color: Theme.paneLine
                Label { id: resetLbl; anchors.centerIn: parent; text: "Reset"; size: 13; weight: Font.Bold }
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
        title: "WINDOWS"
        SettingRow {
            label: "Active window"
            Slider { from: 0.3; to: 1; step: 0.05; unit: "%"; value: HyprOpts.get("decoration:active_opacity", 1); display: value * 100; onMoved: v => HyprOpts.set("decoration:active_opacity", v) }
        }
        SettingRow {
            label: "Inactive windows"
            hint: "Windows you are not working in right now"
            Slider { from: 0.3; to: 1; step: 0.05; unit: "%"; value: HyprOpts.get("decoration:inactive_opacity", 1); display: value * 100; onMoved: v => HyprOpts.set("decoration:inactive_opacity", v) }
        }
    }
    Group {
        title: "BLUR"
        SettingRow {
            label: "Blur"
            hint: HyprOpts.get("decoration:blur:enabled", 1) === 1
                ? "Frosted glass under translucent windows and panels. Turn it off for solid grounds"
                : "Off: panels have a solid ground, no transparency"
            Toggle { checked: HyprOpts.get("decoration:blur:enabled", 1) === 1; onToggled: v => HyprOpts.set("decoration:blur:enabled", v ? 1 : 0) }
        }
        SettingRow {
            visible: HyprOpts.get("decoration:blur:enabled", 1) === 1
            label: "Strength"
            Slider { from: 1; to: 20; step: 1; decimals: 0; value: HyprOpts.get("decoration:blur:size", 8); onMoved: v => HyprOpts.set("decoration:blur:size", v) }
        }
        SettingRow {
            visible: HyprOpts.get("decoration:blur:enabled", 1) === 1
            label: "Passes"
            hint: "More is softer but harder on the GPU"
            Slider { from: 1; to: 4; step: 1; decimals: 0; value: HyprOpts.get("decoration:blur:passes", 1); onMoved: v => HyprOpts.set("decoration:blur:passes", v) }
        }
    }
}
