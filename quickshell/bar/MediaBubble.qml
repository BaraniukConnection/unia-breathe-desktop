import QtQuick
import Quickshell
import Quickshell.Widgets
import "../theme"
import "../services"

// Обкладинка, назва бігучим рядком і ⏮ ⏸ ⏭. Клік по обкладинці/назві — медіацентр.
Bubble {
    id: root
    required property var screen
    property bool compact: false
    visible: Media.player !== null
    padLeft: 6
    padRight: 6
    popup: "media"
    popupScreen: screen
    active: Popups.isOpen("media", screen)

    Row {
        height: parent.height
        spacing: 8

        ClippingRectangle {
            width: 32; height: 32; radius: 16
            anchors.verticalCenter: parent.verticalCenter
            color: Theme.paneHover
            border.width: 1
            border.color: Theme.paneLine
            Icon { anchors.centerIn: parent; name: "music_note"; font.pixelSize: 18; visible: cover.status !== Image.Ready }
            Image { id: cover; anchors.fill: parent; source: Media.art; fillMode: Image.PreserveAspectCrop; asynchronous: true }
        }
        Marquee {
            width: root.compact ? 84 : 160
            height: parent.height
            text: Media.artist ? `${Media.title} – ${Media.artist}` : Media.title
        }
        Pill {
            width: ctl.implicitWidth + 4
            anchors.verticalCenter: parent.verticalCenter
            Row {
                id: ctl
                anchors.centerIn: parent
                spacing: 2
                IconButton { icon: "skip_previous"; onClicked: Media.player.previous(); visible: !!Media.player && Media.player.canGoPrevious }
                IconButton { icon: Media.player && Media.player.isPlaying ? "pause" : "play_arrow"; onClicked: Media.player.togglePlaying() }
                IconButton { icon: "skip_next"; onClicked: Media.player.next(); visible: !!Media.player && Media.player.canGoNext }
            }
        }
    }
}
