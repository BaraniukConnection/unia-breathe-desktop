import QtQuick
import Quickshell
import "../theme"
import "../services"
import "../popups"

// Панель категорій налаштувань (304 px зліва на спецворкспейсі). Права кнопка — закріпити в панелі керування.
FloatingWindow {
    id: win
    title: "Unia · Налаштування"
    color: "transparent"
    implicitWidth: Settings.panelW
    implicitHeight: 800
    property var open: ({ keyboard: true })      // розгорнуті групи

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
                border.width: 1
                border.color: Theme.paneLine
                Row {
                    anchors.fill: parent
                    anchors.margins: 4
                    Repeater {
                        model: Settings.tabs
                        Rectangle {
                            required property var modelData
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
                                onClicked: {
                                    Settings.tab = modelData.id
                                    const first = Settings.items.find(i => i.tab === modelData.id)
                                    if (Settings.current.tab !== modelData.id && first) Settings.select(first.id)
                                }
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
                    // плоский список рядків: окремі пункти, заголовки груп, пункти розгорнутих груп
                    model: {
                        const out = []
                        const seen = {}
                        for (const it of Settings.items.filter(i => i.tab === Settings.tab)) {
                            if (!it.parent) { out.push({ type: "item", it: it }); continue }
                            if (!seen[it.parent]) { seen[it.parent] = true; out.push({ type: "group", id: it.parent }) }
                            if (win.open[it.parent]) out.push({ type: "kid", it: it })
                        }
                        return out
                    }
                    Rectangle {
                        id: row
                        required property var modelData
                        readonly property bool isGroup: modelData.type === "group"
                        readonly property var it: modelData.it ?? null
                        readonly property bool on: !!it && Settings.sel === it.id
                        readonly property bool pinned: !!it && Settings.pins.includes(it.id)
                        width: parent.width
                        height: 56
                        radius: 16
                        color: on ? Theme.accent : rowArea.containsMouse ? Theme.paneHover : "transparent"

                        Rectangle {   // значок у плитці
                            visible: modelData.type !== "kid"
                            x: 8
                            anchors.verticalCenter: parent.verticalCenter
                            width: 40; height: 40; radius: 12
                            color: row.on ? Qt.rgba(0, 0, 0, 0.15) : Theme.pane
                            Icon { anchors.centerIn: parent; name: row.isGroup ? Settings.groups[modelData.id].icon : row.it.icon; color: row.on ? Theme.accentInk : Theme.ink }
                        }
                        Column {
                            x: modelData.type === "kid" ? 58 : 58
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
                                if (row.isGroup) {
                                    const o = Object.assign({}, win.open)
                                    o[modelData.id] = !o[modelData.id]
                                    win.open = o
                                } else if (m.button === Qt.RightButton) Settings.togglePin(row.it.id)
                                else Settings.select(row.it.id)
                            }
                        }
                    }
                }
            }
        }

        Label {
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 14
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Права кнопка — закріпити в панелі керування"
            size: 11
            muted: true
        }
    }
}
