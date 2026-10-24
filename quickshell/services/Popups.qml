pragma Singleton
import QtQuick
import Quickshell

// Only one popup is open at a time: its name, its screen, and where the bubble that opened it sits.
Singleton {
    id: root
    property string current: ""
    property var screen: null
    property real anchorLeft: 0
    property real anchorRight: 0
    readonly property real anchorCenter: (anchorLeft + anchorRight) / 2

    function isOpen(name, scr) { return current === name && screen === scr }

    function toggle(name, scr, item) {
        if (isOpen(name, scr)) { close(); return }
        const p = item.mapToItem(null, 0, 0)
        anchorLeft = p.x
        anchorRight = p.x + item.width
        screen = scr
        current = name
    }

    function close() { current = "" }

    // Opened from the keyboard or IPC: each bar fills in its own bubble on the focused monitor
    signal request(string name)
}
