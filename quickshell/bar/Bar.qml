import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../theme"
import "../services"
import "../components/scenarios"

// Верхня смуга одного монітора: прозора, лише окремі бульбашки. Кліки між ними проходять наскрізь.
PanelWindow {
    id: bar
    required property var modelData
    screen: modelData
    readonly property bool compact: width < 2200      // вузький монітор: менше підписів

    WlrLayershell.namespace: "unia-bar"
    anchors { top: true; left: true; right: true }
    implicitHeight: Theme.top + Theme.bubbleHeight
    exclusiveZone: Theme.top + Theme.bubbleHeight
    color: "transparent"
    // кліки ловлять лише бульбашки; клік повз них (і повз панель) закриває панель через focus grab у shell.qml
    mask: Region {
        Region { item: left }
        Region { item: clock }
        Region { item: media }
        Region { item: right }
    }

    Connections {
        target: Popups
        function onRequest(name) {
            if (!Hyprland.focusedMonitor || Hyprland.focusedMonitor.name !== bar.screen.name) return
            const item = { ws: ws, cal: clock, media: media, power: power, nc: status }[name]
            if (item && item.visible) Popups.toggle(name, bar.screen, item)
        }
    }

    Row {
        id: left
        x: Theme.edge
        y: Theme.top
        spacing: Theme.gap
        ScenarioBubble { screen: bar.screen }
        WorkspaceBubble { id: ws; screen: bar.screen }
    }

    ClockBubble {
        id: clock
        screen: bar.screen
        x: (bar.width - width) / 2
        y: Theme.top
    }
    MediaBubble {
        id: media
        screen: bar.screen
        compact: bar.compact
        x: clock.x + clock.width + 16
        y: Theme.top
    }

    Row {
        id: right
        anchors.right: parent.right
        anchors.rightMargin: Theme.edge
        y: Theme.top
        spacing: Theme.gap
        RecordBubble {}
        StatusBubble { id: status; screen: bar.screen; compact: bar.compact }
        RoundBubble {
            icon: Notifs.dnd ? "notifications_off" : "notifications"
            badge: Notifs.count > 0
            popup: "nc"
            popupScreen: bar.screen
            active: Popups.isOpen("nc", bar.screen)
        }
        RoundBubble {
            id: power
            icon: "power_settings_new"
            popup: "power"
            popupScreen: bar.screen
            active: Popups.isOpen("power", bar.screen)
        }
    }

    // Підказка під сегментом статусу або джерело звуку під медіа
    PopupWindow {
        id: hint
        readonly property var seg: status.hint
        readonly property bool showMedia: media.hovered && !media.active && Media.source !== ""
        readonly property var target: seg ?? (showMedia ? media : null)
        visible: target !== null && Popups.current === ""
        anchor.window: bar
        anchor.rect.x: {
            if (!target) return 0
            const p = target.mapToItem(null, 0, 0)
            return Math.max(8, Math.min(bar.width - width - 8, p.x + target.width / 2 - width / 2))
        }
        anchor.rect.y: Theme.top + Theme.bubbleHeight + 6
        implicitWidth: hintBox.width
        implicitHeight: hintBox.height
        color: "transparent"

        Glass {
            id: hintBox
            strong: true
            radius: 16
            width: rows.implicitWidth + 24
            height: rows.implicitHeight + 12
            Column {
                id: rows
                x: 12; y: 6
                spacing: 4
                Repeater {
                    model: {
                        const k = hint.seg ? hint.seg.kind : "media"
                        if (k === "kb") return [{ text: Keyboard.label }]
                        if (k === "vol") return [{ icon: "speaker", text: Audio.device || "Немає виходу" }]
                        if (k === "bt") return !Bt.enabled ? [{ icon: "bluetooth_disabled", text: "Bluetooth вимкнено" }]
                            : Bt.paired.length ? Bt.paired.map(d => ({ icon: d.icon && d.icon.indexOf("audio") >= 0 ? "headphones" : d.icon && d.icon.indexOf("input") >= 0 ? "sports_esports" : "bluetooth", text: d.name, sub: d.connected ? "під’єднано" : "", cur: d.connected }))
                            : [{ icon: "bluetooth", text: "Немає спарених пристроїв" }]
                        if (k === "wifi") return Net.wired ? [{ icon: "lan", text: "Дротове з'єднання" }]
                            : Net.enabled && Net.name ? [{ icon: "wifi", text: Net.name, sub: `сигнал ${Net.signal}%` }]
                            : [{ icon: "wifi_off", text: Net.enabled ? "Не під'єднано" : "Wi-Fi вимкнено" }]
                        return [{ icon: "music_note", text: Media.source }]
                    }
                    Row {
                        required property var modelData
                        spacing: 8
                        Icon { visible: !!modelData.icon; name: modelData.icon ?? ""; font.pixelSize: 16; color: modelData.cur ? Theme.accent : Theme.inkMuted; anchors.verticalCenter: parent.verticalCenter }
                        Label { text: modelData.text; size: 12 }
                        Label { visible: !!modelData.sub; text: modelData.sub ?? ""; size: 12; muted: true }
                    }
                }
            }
        }
    }
}
