import QtQuick
import Quickshell
import "../../theme"
import "../../services"
import "../../popups"

// Панель категорій налаштувань (304 px зліва на спецворкспейсі).
// Миша: клік — відкрити, права кнопка — закріпити в панелі керування.
// Клавіатура: Tab — вкладки → список → програма праворуч; ←→ — вкладки; ↑↓ — список;
// Enter/Пробіл — відкрити (групу — розгорнути); P — закріпити; Esc — закрити налаштування.
FloatingWindow {
    id: win
    title: "Unia · Налаштування"
    color: "transparent"
    implicitWidth: Settings.panelW
    implicitHeight: 800
    property var open: ({ keyboard: true })      // розгорнуті групи

    property string zone: "list"                 // де клавіатура: "tabs" | "list"
    property int cursor: 0                       // рядок списку під клавіатурою

    // плоский список рядків: окремі пункти, заголовки груп, пункти розгорнутих груп
    readonly property var rows: {
        const out = []
        const seen = {}
        for (const it of Settings.items.filter(i => i.tab === Settings.tab)) {
            if (!it.parent) { out.push({ type: "item", it: it }); continue }
            if (!seen[it.parent]) { seen[it.parent] = true; out.push({ type: "group", id: it.parent }) }
            if (win.open[it.parent]) out.push({ type: "kid", it: it })
        }
        return out
    }
    readonly property int tabIndex: Settings.tabs.findIndex(t => t.id === Settings.tab)

    function setTab(i) {
        const t = Settings.tabs[(i + Settings.tabs.length) % Settings.tabs.length]
        Settings.tab = t.id
        const first = Settings.items.find(x => x.tab === t.id)
        if (Settings.current.tab !== t.id && first) Settings.select(first.id)
        cursor = 0
    }
    function toggleGroup(id, value) {
        const o = Object.assign({}, open)
        o[id] = value ?? !o[id]
        open = o
    }
    function activate(i) {
        const r = rows[i]
        if (!r) return
        if (r.type === "group") toggleGroup(r.id)
        else Settings.select(r.it.id)
    }
    // курсор — на вибраному пункті, щоб Tab/↓ починали звідти
    function syncCursor() {
        const i = rows.findIndex(r => r.it && r.it.id === Settings.sel)
        cursor = i >= 0 ? i : 0
    }
    onRowsChanged: cursor = Math.min(cursor, rows.length - 1)
    Connections { target: Settings; function onSelChanged() { win.syncCursor() } }

    // вікно закрили ззовні (Super+C, Alt+F4) — це «закрити налаштування»; панель створимо знову
    // при наступному відкритті (інакше воно покаже лише затемнений порожній спецворкспейс)
    onClosed: { Settings.panelGone = true; Settings.close() }
    Connections {
        target: Settings
        function onPanelRestoreRequested() { win.visible = false; win.visible = true }
    }

    Item {
        id: keys
        anchors.fill: parent
        focus: true
        Keys.onPressed: e => {
            const back = e.key === Qt.Key_Backtab || (e.key === Qt.Key_Tab && (e.modifiers & Qt.ShiftModifier))
            if (e.key === Qt.Key_Escape) Settings.close()
            else if (back) {
                if (win.zone === "list") win.zone = "tabs"
                else Settings.focusTool()
            } else if (e.key === Qt.Key_Tab) {
                if (win.zone === "tabs") { win.zone = "list"; win.syncCursor() }
                else Settings.focusTool()
            } else if (win.zone === "tabs") {
                if (e.key === Qt.Key_Left) win.setTab(win.tabIndex - 1)
                else if (e.key === Qt.Key_Right) win.setTab(win.tabIndex + 1)
                else if (e.key === Qt.Key_Down || e.key === Qt.Key_Return || e.key === Qt.Key_Enter) { win.zone = "list"; win.syncCursor() }
                else return
            } else {
                const r = win.rows[win.cursor]
                if (e.key === Qt.Key_Down) win.cursor = Math.min(win.rows.length - 1, win.cursor + 1)
                else if (e.key === Qt.Key_Up) { if (win.cursor === 0) win.zone = "tabs"; else win.cursor-- }
                else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter || e.key === Qt.Key_Space) win.activate(win.cursor)
                else if (e.key === Qt.Key_Right && r && r.type === "group") win.toggleGroup(r.id, true)
                else if (e.key === Qt.Key_Left && r && r.type === "group") win.toggleGroup(r.id, false)
                else if (e.key === Qt.Key_Left && r && r.type === "kid") { win.toggleGroup(r.it.parent, false); win.cursor = win.rows.findIndex(x => x.type === "group" && x.id === r.it.parent) }
                else if (e.key === Qt.Key_P && r && r.it) Settings.togglePin(r.it.id)
                else return
            }
            e.accepted = true
        }
    }

    Glass {
        anchors.fill: parent
        radius: 26

        Column {
            x: 12; y: 12
            width: parent.width - 24
            spacing: 10

            // заголовок
            Item {
                width: parent.width
                height: 40
                Label { x: 6; anchors.verticalCenter: parent.verticalCenter; text: "Налаштування"; size: 16; weight: Font.ExtraBold }
                IconButton {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    implicitWidth: 32; implicitHeight: 32
                    icon: "close"
                    muted: true
                    onClicked: Settings.close()
                }
            }

            // розділи
            Rectangle {
                width: parent.width
                height: 40
                radius: 20
                color: Theme.pane
                border.width: win.zone === "tabs" ? 2 : 1
                border.color: win.zone === "tabs" ? Theme.accent : Theme.paneLine
                Row {
                    anchors.fill: parent
                    anchors.margins: 4
                    Repeater {
                        model: Settings.tabs
                        Rectangle {
                            required property var modelData
                            required property int index
                            readonly property bool on: Settings.tab === modelData.id
                            width: (parent.width) / 3
                            height: parent.height
                            radius: height / 2
                            color: on ? Theme.accent : tabArea.containsMouse ? Theme.paneHover : "transparent"
                            Label { anchors.centerIn: parent; text: modelData.label; size: 12; weight: Font.Bold; color: parent.on ? Theme.accentInk : Theme.ink; shadow: !parent.on }
                            MouseArea {
                                id: tabArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: { win.zone = "tabs"; win.setTab(index) }
                            }
                        }
                    }
                }
            }

            // категорії
            Column {
                width: parent.width
                spacing: 4
                Repeater {
                    model: win.rows
                    Rectangle {
                        id: row
                        required property var modelData
                        required property int index
                        readonly property bool isGroup: modelData.type === "group"
                        readonly property var it: modelData.it ?? null
                        readonly property bool on: !!it && Settings.sel === it.id
                        readonly property bool pinned: !!it && Settings.pins.includes(it.id)
                        readonly property bool kbd: win.zone === "list" && win.cursor === index
                        width: parent.width
                        height: 56
                        radius: 16
                        color: on ? Theme.accent : rowArea.containsMouse || kbd ? Theme.paneHover : "transparent"
                        border.width: kbd ? 2 : 0                      // рамка — де зараз клавіатура
                        border.color: on ? Theme.ink : Theme.accent

                        Rectangle {   // значок у плитці
                            visible: modelData.type !== "kid"
                            x: 8
                            anchors.verticalCenter: parent.verticalCenter
                            width: 40; height: 40; radius: 12
                            color: row.on ? Qt.rgba(0, 0, 0, 0.15) : Theme.pane
                            Icon { anchors.centerIn: parent; name: row.isGroup ? Settings.groups[modelData.id].icon : row.it.icon; color: row.on ? Theme.accentInk : Theme.ink }
                        }
                        Column {
                            x: 58
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - x - 40
                            Label {
                                width: parent.width
                                elide: Text.ElideRight
                                text: row.isGroup ? Settings.groups[modelData.id].label : row.it.label
                                weight: Font.Bold
                                color: row.on ? Theme.accentInk : Theme.ink
                                shadow: !row.on
                            }
                            Label {
                                width: parent.width
                                elide: Text.ElideRight
                                size: 12
                                weight: Font.Medium
                                text: row.isGroup ? Settings.items.filter(i => i.parent === modelData.id).map(i => i.label.toLowerCase()).join(", ")
                                    : row.it.kind === "app" ? row.it.tool : "власна сторінка"
                                color: row.on ? Theme.accentInk : Theme.inkMuted
                                shadow: !row.on
                                opacity: row.on ? 0.8 : 1
                            }
                        }
                        Icon {
                            anchors.right: parent.right
                            anchors.rightMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            visible: row.isGroup || row.pinned
                            name: row.isGroup ? (win.open[modelData.id] ? "expand_less" : "expand_more") : "push_pin"
                            filled: row.pinned
                            font.pixelSize: 18
                            color: row.on ? Theme.accentInk : Theme.inkMuted
                        }
                        MouseArea {
                            id: rowArea
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            cursorShape: Qt.PointingHandCursor
                            onClicked: m => {
                                win.zone = "list"
                                win.cursor = index
                                if (row.isGroup) win.toggleGroup(modelData.id)
                                else if (m.button === Qt.RightButton) Settings.togglePin(row.it.id)
                                else Settings.select(row.it.id)
                            }
                        }
                    }
                }
            }
        }

        Column {
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 12
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 2
            Label { anchors.horizontalCenter: parent.horizontalCenter; text: "Права кнопка або P — закріпити"; size: 11; muted: true }
            Label { anchors.horizontalCenter: parent.horizontalCenter; text: "Tab — до програми · Super+Tab — назад"; size: 11; muted: true }
        }
    }
}
