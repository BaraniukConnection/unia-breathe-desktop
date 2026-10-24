import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../theme"
import "../services"

// The screenshot picker on one monitor: the frozen frame, dimming outside the selection and, on the monitor
// where Print was pressed, the controls (modes, shot/video, pointer, the capture button).
PanelWindow {
    id: win
    required property var modelData
    screen: modelData
    readonly property string name: modelData.name
    readonly property bool here: Shot.monitor === name                 // the selection is on this monitor
    readonly property bool ui: Shot.uiMonitor === name                 // the controls are shown here
    visible: Shot.active

    WlrLayershell.namespace: "unia-shot"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: ui ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }
    color: "black"

    readonly property var mon: Hyprland.monitors.values.find(m => m.name === name) ?? null
    readonly property color dim: Qt.rgba(0, 0, 0, 0.5)

    Image {
        anchors.fill: parent
        source: Shot.active ? Shot.frame(win.name, Shot.pointer) : ""
        cache: false
        smooth: false
    }

    // ---------- selection ----------
    Item {
        id: areaLayer
        anchors.fill: parent
        visible: Shot.mode === "area"
        readonly property rect r: win.here ? Shot.area : Qt.rect(0, 0, 0, 0)

        // dimming around the selection
        Rectangle { color: "#80000000"; x: 0; y: 0; width: parent.width; height: areaLayer.r.y }
        Rectangle { color: "#80000000"; x: 0; y: areaLayer.r.y + areaLayer.r.height; width: parent.width; height: parent.height - y }
        Rectangle { color: "#80000000"; x: 0; y: areaLayer.r.y; width: areaLayer.r.x; height: areaLayer.r.height }
        Rectangle { color: "#80000000"; x: areaLayer.r.x + areaLayer.r.width; y: areaLayer.r.y; width: parent.width - x; height: areaLayer.r.height }

        // a new selection / dragging the current one
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.CrossCursor
            property point start
            property rect from
            property bool moving: false
            onPressed: m => {
                const r = areaLayer.r
                moving = win.here && m.x > r.x && m.x < r.x + r.width && m.y > r.y && m.y < r.y + r.height
                start = Qt.point(m.x, m.y)
                from = r
                if (!moving) { Shot.monitor = win.name; Shot.area = Qt.rect(m.x, m.y, 0, 0) }
            }
            onPositionChanged: m => {
                if (!pressed) return
                if (moving) {
                    const x = Math.max(0, Math.min(width - from.width, from.x + m.x - start.x))
                    const y = Math.max(0, Math.min(height - from.height, from.y + m.y - start.y))
                    Shot.area = Qt.rect(x, y, from.width, from.height)
                } else {
                    const x = Math.max(0, Math.min(m.x, width)), y = Math.max(0, Math.min(m.y, height))
                    Shot.area = Qt.rect(Math.min(start.x, x), Math.min(start.y, y), Math.abs(x - start.x), Math.abs(y - start.y))
                }
            }
            onDoubleClicked: if (moving) Shot.capture()
        }

        // frame and handles
        Rectangle {
            visible: win.here
            x: areaLayer.r.x - 1; y: areaLayer.r.y - 1
            width: areaLayer.r.width + 2; height: areaLayer.r.height + 2
            color: "transparent"
            border.width: 2
            border.color: Theme.accent
        }
        Repeater {
            // handles: [x fraction, y fraction, edges it drags: left, top, right, bottom]
            model: win.here ? [[0, 0, 1, 1, 0, 0], [0.5, 0, 0, 1, 0, 0], [1, 0, 0, 1, 1, 0], [1, 0.5, 0, 0, 1, 0],
                               [1, 1, 0, 0, 1, 1], [0.5, 1, 0, 0, 0, 1], [0, 1, 1, 0, 0, 1], [0, 0.5, 1, 0, 0, 0]] : []
            Rectangle {
                required property var modelData
                readonly property var h: modelData
                x: areaLayer.r.x + areaLayer.r.width * h[0] - width / 2
                y: areaLayer.r.y + areaLayer.r.height * h[1] - height / 2
                width: 14; height: 14; radius: 7
                color: Theme.ink
                border.width: 3
                border.color: Theme.accent
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -6
                    cursorShape: (h[0] === 0.5) ? Qt.SizeVerCursor : (h[1] === 0.5) ? Qt.SizeHorCursor
                               : (h[0] === h[1]) ? Qt.SizeFDiagCursor : Qt.SizeBDiagCursor
                    property rect from
                    onPressed: from = Shot.area
                    onPositionChanged: m => {
                        if (!pressed) return
                        const p = mapToItem(areaLayer, m.x, m.y)
                        let l = from.x, t = from.y, r = from.x + from.width, b = from.y + from.height
                        if (h[2]) l = Math.min(p.x, r - 8)
                        if (h[3]) t = Math.min(p.y, b - 8)
                        if (h[4]) r = Math.max(p.x, l + 8)
                        if (h[5]) b = Math.max(p.y, t + 8)
                        Shot.area = Qt.rect(Math.max(0, l), Math.max(0, t), Math.min(areaLayer.width, r) - Math.max(0, l), Math.min(areaLayer.height, b) - Math.max(0, t))
                    }
                }
            }
        }
        // selection size
        Glass {
            visible: win.here && areaLayer.r.width > 0
            strong: true
            radius: 12
            x: areaLayer.r.x
            y: areaLayer.r.y > 40 ? areaLayer.r.y - 36 : areaLayer.r.y + 8
            width: sizeLabel.implicitWidth + 20
            height: 28
            Label { id: sizeLabel; anchors.centerIn: parent; size: 12; weight: Font.Bold; text: `${Math.round(areaLayer.r.width)} × ${Math.round(areaLayer.r.height)}` }
        }
    }

    // ---------- screen ----------
    Rectangle {
        anchors.fill: parent
        visible: Shot.mode === "screen"
        color: win.here ? "transparent" : "#80000000"
        border.width: win.here ? 4 : 0
        border.color: Theme.accent
        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Shot.monitor = win.name; onDoubleClicked: Shot.capture() }
    }

    // ---------- window ----------
    Item {
        anchors.fill: parent
        visible: Shot.mode === "window"
        Rectangle { anchors.fill: parent; color: "#80000000" }
        MouseArea { anchors.fill: parent }        // a click outside windows does nothing
        Repeater {
            model: Shot.windows.filter(w => w.monitor === win.name)
            Rectangle {
                id: wr
                required property var modelData
                readonly property bool sel: !!Shot.windowSel && Shot.windowSel.x === modelData.x && Shot.windowSel.y === modelData.y
                                            && Shot.windowSel.w === modelData.w && Shot.windowSel.monitor === modelData.monitor
                x: modelData.x - (win.mon ? win.mon.x : 0)
                y: modelData.y - (win.mon ? win.mon.y : 0)
                width: modelData.w
                height: modelData.h
                color: "transparent"
                border.width: sel ? 4 : wa.containsMouse ? 2 : 0
                border.color: Theme.accent
                // the chosen window is not dimmed: its piece of the frame is shown over the dimming
                Image {
                    visible: wr.sel || wa.containsMouse
                    anchors.fill: parent
                    anchors.margins: wr.border.width
                    source: Shot.active ? Shot.frame(win.name, Shot.pointer) : ""
                    sourceClipRect: Qt.rect(wr.x + anchors.margins, wr.y + anchors.margins, width, height)
                    cache: false
                    z: -1
                }
                MouseArea {
                    id: wa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Shot.windowSel = wr.modelData
                    onDoubleClicked: { Shot.windowSel = wr.modelData; Shot.capture() }
                }
            }
        }
    }

    // ---------- controls ----------
    Item {
        anchors.fill: parent
        visible: win.ui
        focus: win.ui
        Keys.onPressed: e => {
            if (e.key === Qt.Key_Escape) Shot.close()
            else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter || e.key === Qt.Key_Space) Shot.capture()
            else if (e.key === Qt.Key_S) Shot.mode = "area"
            else if (e.key === Qt.Key_C) Shot.mode = "screen"
            else if (e.key === Qt.Key_W) Shot.mode = "window"
            else if (e.key === Qt.Key_P) Shot.pointer = !Shot.pointer
            else if (e.key === Qt.Key_V && Shot.canRecord) Shot.video = !Shot.video
            else return
            e.accepted = true
        }

        component Seg: Rectangle {
            id: seg
            property string icon
            property string label
            property bool on
            property bool enabledSeg: true
            signal picked()
            width: segRow.implicitWidth + 28
            height: 44
            radius: 22
            color: on ? Theme.accent : segArea.containsMouse ? Theme.paneHover : "transparent"
            opacity: enabledSeg ? 1 : 0.4
            Row {
                id: segRow
                anchors.centerIn: parent
                spacing: 8
                Icon { name: seg.icon; color: seg.on ? Theme.accentInk : Theme.ink; anchors.verticalCenter: parent.verticalCenter }
                Label { visible: seg.label !== ""; text: seg.label; weight: Font.Bold; color: seg.on ? Theme.accentInk : Theme.ink; shadow: !seg.on; anchors.verticalCenter: parent.verticalCenter }
            }
            MouseArea { id: segArea; anchors.fill: parent; enabled: seg.enabledSeg; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: seg.picked() }
        }

        Glass {
            id: bar
            color: Theme.tint(Qt.rgba(8 / 255, 30 / 255, 25 / 255, 0.9))
            radius: 32
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 48
            width: barRow.implicitWidth + 24
            height: 76
            Row {
                id: barRow
                anchors.centerIn: parent
                spacing: 18
                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4
                    Seg { icon: "screenshot_region"; label: "Area"; on: Shot.mode === "area"; onPicked: Shot.mode = "area" }
                    Seg { icon: "desktop_windows"; label: "Screen"; on: Shot.mode === "screen"; onPicked: Shot.mode = "screen" }
                    Seg { icon: "web_asset"; label: "Window"; on: Shot.mode === "window"; onPicked: Shot.mode = "window" }
                }
                // the capture button: a white ring around a circle (red for video)
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 56; height: 56; radius: 28
                    color: "transparent"
                    border.width: 3
                    border.color: Theme.ink
                    Rectangle {
                        anchors.centerIn: parent
                        width: capArea.pressed ? 38 : 44; height: width; radius: width / 2
                        color: Shot.video ? Theme.red : capArea.containsMouse ? Theme.accent : Theme.ink
                        Behavior on width { NumberAnimation { duration: 80 } }
                    }
                    MouseArea { id: capArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Shot.capture() }
                }
                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4
                    Seg { icon: "photo_camera"; label: ""; on: !Shot.video; onPicked: Shot.video = false }
                    Seg { icon: "videocam"; label: ""; on: Shot.video; enabledSeg: Shot.canRecord; onPicked: Shot.video = true }
                }
                Seg { anchors.verticalCenter: parent.verticalCenter; icon: "arrow_selector_tool"; label: ""; on: Shot.pointer; onPicked: Shot.pointer = !Shot.pointer }
                IconButton { anchors.verticalCenter: parent.verticalCenter; implicitWidth: 40; implicitHeight: 40; icon: "close"; onClicked: Shot.close() }
            }
        }
        Glass {
            anchors.horizontalCenter: bar.horizontalCenter
            anchors.bottom: bar.top
            anchors.bottomMargin: 10
            color: Theme.tint(Qt.rgba(8 / 255, 30 / 255, 25 / 255, 0.85))
            radius: 14
            width: hint.implicitWidth + 24
            height: 28
            Label {
                id: hint
                anchors.centerIn: parent
                text: "Enter: capture · Esc: cancel · S / C / W: mode · P: pointer" + (Shot.canRecord ? " · V: video" : "")
                size: 12
            }
        }
    }
}
