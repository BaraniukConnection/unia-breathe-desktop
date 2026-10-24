import QtQuick
import "../services"

// A glass bubble on the top bar. Content goes inside; click and wheel come out as signals.
Glass {
    id: root
    default property alias content: holder.data
    property bool active: false              // its popup is open: accent outline
    property bool interactive: true
    readonly property bool hovered: area.containsMouse
    property int padLeft: 16
    property int padRight: 6
    // if set: a click opens this popup, and hovering switches to it while another one is open
    property string popup: ""
    property var popupScreen: null
    signal clicked(var mouse)
    signal wheel(var wheel)

    height: Theme.bubbleHeight
    radius: height / 2
    implicitWidth: holder.childrenRect.width + padLeft + padRight
    // in focus mode the solid bar strip is the ground: the bubble has no glass of its own, only a hover highlight
    color: Theme.focusMode ? (hovered ? Theme.pane : "transparent") : Theme.glass
    border.width: active ? 2 : Theme.focusMode ? 0 : 1
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
