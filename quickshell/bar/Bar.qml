import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../theme"
import "../services"
import "../components/scenarios"

// The top bar of one monitor: transparent, only separate bubbles. Clicks between them pass through.
// Focus mode (Theme.focusMode, the round button left of the desk): the bar gets lower and solid, full-width glass
// with an accent tint.
PanelWindow {
    id: bar
    required property var modelData
    screen: modelData
    readonly property bool compact: width < 2200      // narrow monitor: fewer labels

    WlrLayershell.namespace: "unia-bar"
    anchors { top: true; left: true; right: true }
    readonly property int barHeight: Theme.focusMode ? Theme.top * 2 + Theme.bubbleHeight : Theme.top + Theme.bubbleHeight
    implicitHeight: barHeight
    exclusiveZone: barHeight
    color: "transparent"
    // only bubbles take clicks; a click outside them (and outside the popup) closes the popup through the focus grab in shell.qml
    mask: Region {
        Region { item: left }
        Region { item: tasks }
        Region { item: clock }
        Region { item: media }
        Region { item: right }
    }

    // the solid ground of focus mode: system glass (Hyprland blurs) and an accent tint
    Rectangle {
        visible: Theme.focusMode
        width: parent.width
        height: bar.barHeight
        color: Theme.glass
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.22) }
                GradientStop { position: 0.5; color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.1) }
                GradientStop { position: 1; color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.22) }
            }
        }
        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.paneLine }
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
        // focus mode: the bar gets lower and solid (saved in settings)
        RoundBubble {
            icon: "center_focus_strong"
            filled: Theme.focusMode
            active: Theme.focusMode
            onClicked: Prefs.set("focusMode", !Theme.focusMode)
        }
        WorkspaceBubble { id: ws; screen: bar.screen }
    }

    // open windows: left of the clock, without running into the scenario and desk bubbles
    TaskBubble {
        id: tasks
        barWindow: bar
        maxWidth: clock.x - 16 - (left.x + left.width + 24)
        x: clock.x - 16 - width
        y: Theme.top
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

    // A hint under a status segment, or the audio source under media
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
                        if (k === "vol") return [{ icon: "speaker", text: Audio.device || "No output" }]
                        if (k === "bt") return !Bt.enabled ? [{ icon: "bluetooth_disabled", text: "Bluetooth is off" }]
                            : Bt.paired.length ? Bt.paired.map(d => ({ icon: d.icon && d.icon.indexOf("audio") >= 0 ? "headphones" : d.icon && d.icon.indexOf("input") >= 0 ? "sports_esports" : "bluetooth", text: d.name, sub: d.connected ? "connected" : "", cur: d.connected }))
                            : [{ icon: "bluetooth", text: "No paired devices" }]
                        if (k === "wifi") return Net.wired ? [{ icon: "lan", text: "Wired connection" }]
                            : Net.enabled && Net.name ? [{ icon: "wifi", text: Net.name, sub: `signal ${Net.signal}%` }]
                            : [{ icon: "wifi_off", text: Net.enabled ? "Not connected" : "Wi-Fi is off" }]
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
