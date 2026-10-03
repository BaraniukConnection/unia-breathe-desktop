import QtQuick
import "../services"

// Скляна бульбашка верхньої смуги. Вміст кладеться всередину; клік і колесо — сигналами.
Glass {
    id: root
    default property alias content: holder.data
    property bool active: false              // відкрите її спливаюче вікно — акцентна обвідка
    property bool interactive: true
    readonly property bool hovered: area.containsMouse
    property int padLeft: 16
    property int padRight: 6
    // якщо задано: клік відкриває цю панель, а наведення перемикає на неї, коли інша вже відкрита
    property string popup: ""
    property var popupScreen: null
    signal clicked(var mouse)
    signal wheel(var wheel)

    height: Theme.bubbleHeight
    radius: height / 2
    implicitWidth: holder.childrenRect.width + padLeft + padRight
    border.width: active ? 2 : 1
    border.color: active ? Theme.accent : Theme.paneLine

    MouseArea {
        id: area
        anchors.fill: parent
        enabled: root.interactive
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        cursorShape: Qt.PointingHandCursor
        onClicked: m => { if (root.popup) Popups.toggle(root.popup, root.popupScreen, root); root.clicked(m) }
        onContainsMouseChanged: if (containsMouse && root.popup && Popups.current !== "" && Popups.screen === root.popupScreen
                                    && Popups.current !== root.popup) Popups.toggle(root.popup, root.popupScreen, root)
        onWheel: w => root.wheel(w)
    }
    Item {
        id: holder
        x: root.padLeft
        height: parent.height
        width: childrenRect.width
    }
}
