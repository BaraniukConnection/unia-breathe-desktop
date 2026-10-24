import QtQuick
import Quickshell
import "../theme"
import "../services"

// Layout, volume, Bluetooth, Wi-Fi. Hover shows a hint, the wheel changes the value under the cursor.
Bubble {
    id: root
    required property var screen
    property bool compact: false
    property var hint: null                      // segment under the cursor (for the hint)
    padLeft: 6
    popup: "nc"
    popupScreen: screen
    active: Popups.isOpen("nc", screen)

    component Seg: Pill {
        id: seg
        property string kind
        property string icon
        property string label
        property bool off: false
        property bool showLabel: true
        width: segRow.implicitWidth + 20
        hovered: segArea.containsMouse
        Row {
            id: segRow
            anchors.centerIn: parent
            spacing: 6
            Icon { name: seg.icon; font.pixelSize: 18; color: seg.off ? Theme.inkMuted : Theme.ink; anchors.verticalCenter: parent.verticalCenter }
            Label {
                visible: seg.showLabel && seg.label !== ""
                text: seg.label
                size: 13
                weight: Font.Bold
                muted: seg.off
                elide: Text.ElideRight
                width: Math.min(implicitWidth, 96)
                anchors.verticalCenter: parent.verticalCenter
            }
        }
        MouseArea {
            id: segArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onContainsMouseChanged: root.hint = containsMouse ? seg : (root.hint === seg ? null : root.hint)
            onClicked: Popups.toggle("nc", root.screen, root)
            onWheel: w => root.wheelOn(seg.kind, w)
        }
    }

    function wheelOn(kind, w) {
        if (kind === "vol") Audio.setVolume(Audio.volume + (w.angleDelta.y > 0 ? 2 : -2))
        else if (kind === "kb" && Math.abs(w.angleDelta.y) >= 60) Keyboard.next()
    }

    Row {
        height: parent.height
        spacing: 4
        Seg { kind: "kb"; icon: "keyboard"; label: Keyboard.code; anchors.verticalCenter: parent.verticalCenter }
        Seg { kind: "vol"; icon: Audio.icon; label: Audio.muted ? "off" : `${Audio.volume}%`; anchors.verticalCenter: parent.verticalCenter }
        Seg {
            kind: "bt"; anchors.verticalCenter: parent.verticalCenter
            icon: Bt.enabled ? "bluetooth" : "bluetooth_disabled"
            label: Bt.enabled ? Bt.name : "off"
            off: !Bt.enabled
            showLabel: !root.compact
        }
        Seg {
            kind: "wifi"; anchors.verticalCenter: parent.verticalCenter
            icon: Net.wired ? "lan" : Net.enabled && Net.name ? "wifi" : "wifi_off"
            label: Net.wired ? "cable" : Net.enabled ? Net.name : "off"
            off: !Net.wired && !Net.enabled
            showLabel: !root.compact
        }
    }
}
