pragma Singleton
import QtQuick
import Quickshell

// Одночасно відкрите лише одне спливаюче вікно: назва, екран і де стоїть бульбашка, з якої його відкрили.
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

    // Відкрити з клавіатури/IPC: кожна смуга сама підставить свою бульбашку на моніторі з фокусом
    signal request(string name)
}
