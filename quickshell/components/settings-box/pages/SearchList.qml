import QtQuick
import QtQuick.Controls
import "../../../theme"

// A search field with a list of options under it (time zones, languages).
Column {
    id: root
    property var items: []                 // [{ value, label, sub }]
    property string current: ""
    property string placeholder: "Search..."
    signal picked(var value)
    function focusField() { field.forceActiveFocus() }
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
        background: Rectangle { radius: 20; color: Theme.paneHover; border.width: field.activeFocus ? 2 : 1; border.color: field.activeFocus ? Theme.accent : Theme.paneLine }
        Keys.onDownPressed: list.incrementCurrentIndex()
        Keys.onUpPressed: list.decrementCurrentIndex()
        onAccepted: if (list.count > 0) root.picked(list.model[Math.max(0, list.currentIndex)].value)
        onTextChanged: list.currentIndex = 0
    }
    ListView {
        id: list
        width: parent.width
        currentIndex: 0
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
            required property int index
            readonly property bool on: modelData.value === root.current
            readonly property bool kbd: field.activeFocus && ListView.isCurrentItem
            width: ListView.view.width
            height: 40
            radius: 12
            color: on ? Theme.accent : a.containsMouse || kbd ? Theme.paneHover : "transparent"
            border.width: kbd ? 2 : 0
            border.color: Theme.accent
            Label { x: 12; anchors.verticalCenter: parent.verticalCenter; text: modelData.label; weight: Font.DemiBold; color: parent.on ? Theme.accentInk : Theme.ink; shadow: !parent.on }
            Label { anchors.right: parent.right; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter; text: modelData.sub ?? ""; size: 12; color: parent.on ? Theme.accentInk : Theme.inkMuted; shadow: !parent.on }
            MouseArea { id: a; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.picked(modelData.value) }
        }
    }
}
