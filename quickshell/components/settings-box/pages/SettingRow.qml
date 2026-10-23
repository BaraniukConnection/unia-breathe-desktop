import QtQuick
import "../../../theme"

// Рядок налаштування: назва (+ пояснення) ліворуч, елемент керування праворуч.
Item {
    default property alias control: slot.data
    property string label
    property string hint
    width: parent ? parent.width : 0
    implicitHeight: Math.max(52, texts.implicitHeight + 16)
    Column {
        id: texts
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width - slot.width - 16
        Label { width: parent.width; text: label; weight: Font.Bold; wrapMode: Text.Wrap }
        Label { width: parent.width; visible: hint !== ""; text: hint; size: 12; weight: Font.Medium; muted: true; wrapMode: Text.Wrap }
    }
    Item {
        id: slot
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: childrenRect.width
        height: childrenRect.height
    }
}
