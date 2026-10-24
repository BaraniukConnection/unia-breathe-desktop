import QtQuick
import Quickshell
import Quickshell.Io
import "../../../theme"
import "../../../services"
import ".."

// Keyboard layouts: the language list (order, remove, add) and the switch key.
Page {
    id: page
    title: "Language & Layout"
    subtitle: "The order of languages is the switching order. Changes apply at once."
    property var all: []                     // [{ value: "us", label: "English (US)" }]
    readonly property var layouts: String(HyprOpts.get("input:kb_layout", "us")).split(",").filter(x => x)
    readonly property var variants: String(HyprOpts.get("input:kb_variant", "")).split(",")
    readonly property var options: String(HyprOpts.get("input:kb_options", "")).split(",").filter(x => x)
    readonly property string grp: options.find(o => o.startsWith("grp:")) ?? ""

    function nameOf(code) { const l = all.find(x => x.value === code); return l ? l.label : code }
    function apply(list, vars) {
        HyprOpts.set("input:kb_layout", list.join(","))
        HyprOpts.set("input:kb_variant", list.map((_, i) => vars[i] ?? "").join(","))
    }
    function move(i, d) {
        const l = layouts.slice(), v = layouts.map((_, k) => variants[k] ?? "")
        const j = i + d
        if (j < 0 || j >= l.length) return;
        [l[i], l[j]] = [l[j], l[i]];
        [v[i], v[j]] = [v[j], v[i]]
        apply(l, v)
    }
    function remove(i) {
        if (layouts.length < 2) return
        apply(layouts.filter((_, k) => k !== i), layouts.map((_, k) => variants[k] ?? "").filter((_, k) => k !== i))
    }
    function add(code) {
        if (layouts.includes(code)) return
        apply([...layouts, code], [...layouts.map((_, k) => variants[k] ?? ""), ""])
        adding = false
    }
    property bool adding: false
    onAddingChanged: if (adding) Qt.callLater(() => addList.focusField())

    Process {
        running: true
        command: ["sh", "-c", "sed -n '/^! layout/,/^! variant/p' /usr/share/X11/xkb/rules/base.lst | sed '1d;$d'"]
        stdout: StdioCollector {
            onStreamFinished: page.all = text.split("\n").map(l => l.trim()).filter(l => l)
                .map(l => { const m = l.match(/^(\S+)\s+(.*)$/); return { value: m[1], label: m[2], sub: m[1] } })
        }
    }

    Group {
        title: "LANGUAGES"
        Repeater {
            model: page.layouts
            SettingRow {
                required property var modelData
                required property int index
                label: page.nameOf(modelData)
                hint: modelData + (page.variants[index] ? ` (${page.variants[index]})` : "") + (index === 0 ? " · main" : "")
                Row {
                    IconButton { focusable: true; implicitWidth: 32; implicitHeight: 32; icon: "arrow_upward"; muted: true; opacity: index > 0 ? 1 : 0.3; onClicked: page.move(index, -1) }
                    IconButton { focusable: true; implicitWidth: 32; implicitHeight: 32; icon: "arrow_downward"; muted: true; opacity: index < page.layouts.length - 1 ? 1 : 0.3; onClicked: page.move(index, 1) }
                    IconButton { focusable: true; implicitWidth: 32; implicitHeight: 32; icon: "close"; muted: true; opacity: page.layouts.length > 1 ? 1 : 0.3; onClicked: page.remove(index) }
                }
            }
        }
        Item {
            visible: !page.adding
            width: parent.width
            height: 48
            Pill {
                anchors.verticalCenter: parent.verticalCenter
                width: addRow.implicitWidth + 28
                height: 36
                hovered: addArea.containsMouse || activeFocus
                activeFocusOnTab: true
                Keys.onSpacePressed: page.adding = true
                Keys.onReturnPressed: page.adding = true
                border.width: activeFocus ? 2 : 1
                border.color: activeFocus ? Theme.accent : Theme.paneLine
                Row { id: addRow; anchors.centerIn: parent; spacing: 8
                    Icon { name: "add"; anchors.verticalCenter: parent.verticalCenter }
                    Label { text: "Add Language"; weight: Font.Bold; anchors.verticalCenter: parent.verticalCenter } }
                MouseArea { id: addArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: page.adding = true }
            }
        }
        SearchList {
            id: addList
            visible: page.adding
            items: page.all
            placeholder: "Search languages (e.g. German, Polish, de)"
            onPicked: v => page.add(v)
        }
    }
    Group {
        title: "SWITCHING"
        SettingRow {
            label: "Keys"
            Choice {
                options: [
                    { value: "grp:win_space_toggle", label: "Win+Space" },
                    { value: "grp:alt_shift_toggle", label: "Alt+Shift" },
                    { value: "grp:ctrl_shift_toggle", label: "Ctrl+Shift" },
                    { value: "grp:caps_toggle", label: "Caps Lock" },
                ]
                current: page.grp
                onChosen: v => HyprOpts.set("input:kb_options", [...page.options.filter(o => !o.startsWith("grp:")), v].join(","))
            }
        }
    }
}
