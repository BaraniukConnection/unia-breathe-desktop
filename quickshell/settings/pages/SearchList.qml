import QtQuick
import QtQuick.Controls
import "../../theme"

// Поле пошуку і список варіантів під ним (часові пояси, мови).
Column {
    id: root
    property var items: []                 // [{ value, label, sub }]
    property string current: ""
    property string placeholder: "Пошук…"
    signal picked(var value)
    width: parent ? parent.width : 0
    spacing: 8

    TextField {
        id: field
        width: parent.width
        height: 40
        placeholderText: root.placeholder
        font.family: Theme.font
        font.pixelSize: 14
        color: Theme.ink
        placeholderTextColor: Theme.inkMuted
        leftPadding: 16
        background: Rectangle { radius: 20; color: Theme.paneHover; border.width: 1; border.color: field.activeFocus ? Theme.accent : Theme.paneLine }
    }
    ListView {
        width: parent.width
        height: Math.min(contentHeight, 280)
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        model: {
            const q = field.text.trim().toLowerCase()
            const list = q ? root.items.filter(i => (i.label + " " + (i.sub ?? "") + " " + i.value).toLowerCase().includes(q)) : root.items
            return list.slice(0, 300)
        }
        delegate: Rectangle {
            required property var modelData
            readonly property bool on: modelData.value === root.current
            width: ListView.view.width
            height: 40
            radius: 12
            color: on ? Theme.accent : a.containsMouse ? Theme.paneHover : "transparent"
            Label { x: 12; anchors.verticalCenter: parent.verticalCenter; text: modelData.label; weight: Font.DemiBold; color: parent.on ? Theme.accentInk : Theme.ink; shadow: !parent.on }
            Label { anchors.right: parent.right; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter; text: modelData.sub ?? ""; size: 12; color: parent.on ? Theme.accentInk : Theme.inkMuted; shadow: !parent.on }
            MouseArea { id: a; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.picked(modelData.value) }
        }
    }
}
