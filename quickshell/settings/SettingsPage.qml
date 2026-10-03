import QtQuick
import Quickshell
import "../theme"
import "../services"

// Власна сторінка налаштування (праворуч від панелі). Поки — опис того, що тут з'явиться на етапі 6.
FloatingWindow {
    id: win
    title: "Unia · Сторінка"
    color: "transparent"
    visible: !!Settings.current && Settings.current.kind === "own"
    implicitWidth: 900
    implicitHeight: 800

    Glass {
        anchors.fill: parent
        radius: 26

        Column {
            anchors.centerIn: parent
            width: Math.min(parent.width - 80, 480)
            spacing: 14
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 88; height: 88; radius: 28
                color: Theme.pane
                border.width: 1
                border.color: Theme.paneLine
                Icon { anchors.centerIn: parent; name: Settings.current ? Settings.current.icon : ""; font.pixelSize: 44; color: Theme.accent }
            }
            Label { anchors.horizontalCenter: parent.horizontalCenter; text: Settings.current ? Settings.current.label : ""; size: 22; weight: Font.ExtraBold }
            Label {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                text: Settings.current ? Settings.current.what ?? "" : ""
                muted: true
            }
            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Сторінка з'явиться на етапі 6"
                size: 12
                muted: true
            }
        }
    }
}
