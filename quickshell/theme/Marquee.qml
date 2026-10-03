import QtQuick

// Текст, що не влазить, повільно їздить туди-назад у своїй рамці (як .mq у макеті).
Item {
    id: root
    property alias text: label.text
    property alias size: label.size
    property alias weight: label.weight
    readonly property real over: label.implicitWidth - width
    implicitHeight: label.implicitHeight
    clip: true

    Label {
        id: label
        x: 0
        anchors.verticalCenter: parent.verticalCenter
        onTextChanged: { x = 0; slide.restart() }
    }
    SequentialAnimation {
        id: slide
        running: root.over > 4 && root.visible
        loops: Animation.Infinite
        onStopped: label.x = 0
        PauseAnimation { duration: 1800 }
        NumberAnimation { target: label; property: "x"; to: -(root.over + 12); duration: Math.max(3000, root.over * 40); easing.type: Easing.InOutSine }
        PauseAnimation { duration: 1800 }
        NumberAnimation { target: label; property: "x"; to: 0; duration: Math.max(3000, root.over * 40); easing.type: Easing.InOutSine }
    }
}
