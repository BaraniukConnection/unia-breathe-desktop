import QtQuick

// The inner pill of a bubble (bubble-val / st / m-ctl in the mockup).
Rectangle {
    property bool hovered: false
    property bool on: false          // "open" state: accent ground
    height: 32
    radius: height / 2
    color: on ? Theme.accent : hovered ? Qt.rgba(1, 1, 1, 0.22) : Theme.paneHover
    border.width: on ? 0 : 1
    border.color: Theme.paneLine
    Behavior on color { ColorAnimation { duration: 160 } }
}
