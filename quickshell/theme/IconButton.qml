import QtQuick

// Кругла кнопка зі значком (m-btn / icon-btn у макеті).
Rectangle {
    id: root
    property string icon
    property int iconSize: 20
    property bool accent: false
    property bool muted: false
    signal clicked()
    implicitWidth: 28
    implicitHeight: 28
    radius: width / 2
    color: accent ? Theme.accent : area.containsMouse ? Qt.rgba(1, 1, 1, 0.2) : "transparent"
    Icon {
        anchors.centerIn: parent
        name: root.icon
        font.pixelSize: root.iconSize
        color: root.accent ? Theme.accentInk : root.muted && !area.containsMouse ? Theme.inkMuted : Theme.ink
    }
    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
