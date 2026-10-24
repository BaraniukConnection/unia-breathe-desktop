import QtQuick
import QtQuick.Controls
import app.loaf

// Radio button drawn with the theme colors.
RadioButton {
    id: control
    spacing: 8
    Accessible.name: text

    indicator: Rectangle {
        implicitWidth: 18
        implicitHeight: 18
        x: control.leftPadding
        y: (control.height - height) / 2
        radius: 9
        color: "transparent"
        border.color: control.checked ? theme.primary : theme.outline
        border.width: 2
        Rectangle {
            anchors.centerIn: parent
            width: 8
            height: 8
            radius: 4
            color: theme.primary
            visible: control.checked
        }
    }

    contentItem: Text {
        text: control.text
        color: theme.textMain
        font.pixelSize: theme.fs(12)
        leftPadding: control.indicator.width + control.spacing
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }
}
