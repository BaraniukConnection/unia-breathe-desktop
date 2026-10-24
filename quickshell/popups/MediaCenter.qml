import QtQuick
import Quickshell
import Quickshell.Widgets
import "../theme"
import "../services"

// Media centre: title, artist, large cover, large buttons, audio source.
Glass {
    width: 300
    height: sec.implicitHeight + 24

    Section {
        id: sec
        x: 12; y: 12
        width: parent.width - 24
        pad: 12
        Column {
            width: parent.width
            spacing: 2
            Marquee { width: parent.width; height: 22; text: Media.title; weight: Font.Bold }
            Label { width: parent.width; text: Media.artist; size: 13; weight: Font.Medium; muted: true; elide: Text.ElideRight; horizontalAlignment: Text.AlignHCenter; visible: text !== "" }
        }
        ClippingRectangle {
            width: parent.width
            height: 190
            radius: 16
            color: Theme.paneHover
            Icon { anchors.centerIn: parent; name: "music_note"; font.pixelSize: 64; color: Theme.inkMuted; visible: art.status !== Image.Ready }
            Image { id: art; anchors.fill: parent; source: Media.art; fillMode: Image.PreserveAspectCrop; asynchronous: true }
        }
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 14
            IconButton { implicitWidth: 40; implicitHeight: 40; iconSize: 26; icon: "skip_previous"; onClicked: Media.player.previous() }
            IconButton { implicitWidth: 40; implicitHeight: 40; iconSize: 26; accent: true; icon: Media.player && Media.player.isPlaying ? "pause" : "play_arrow"; onClicked: Media.player.togglePlaying() }
            IconButton { implicitWidth: 40; implicitHeight: 40; iconSize: 26; icon: "skip_next"; onClicked: Media.player.next() }
        }
        Pill {
            anchors.horizontalCenter: parent.horizontalCenter
            height: 30
            width: src.implicitWidth + 24
            Row {
                id: src
                anchors.centerIn: parent
                spacing: 8
                IconImage { implicitSize: 18; source: Media.sourceIcon; visible: Media.sourceIcon !== ""; anchors.verticalCenter: parent.verticalCenter }
                Label { text: Media.source; size: 12; anchors.verticalCenter: parent.verticalCenter }
            }
        }
    }
}
