import QtQuick

// Кругла кнопка зі значком (m-btn / icon-btn у макеті).
Rectangle {
    id: root
    property string icon
    property int iconSize: 20
    property bool accent: false
    property bool muted: false
    property bool focusable: false            // брати участь у Tab (сторінки налаштувань)
    signal clicked()
    activeFocusOnTab: focusable
    Keys.onSpacePressed: clicked()
    Keys.onReturnPressed: clicked()
    implicitWidth: 28
    implicitHeight: 28
    radius: width / 2
    color: accent ? Theme.accent : area.containsMouse ? Qt.rgba(1, 1, 1, 0.2) : "transparent"
    Rectangle { anchors.fill: parent; anchors.margins: -2; radius: width / 2; color: "transparent"; border.width: 2; border.color: Theme.accent; visible: root.activeFocus }
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
