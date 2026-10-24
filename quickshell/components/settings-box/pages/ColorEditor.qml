import QtQuick
import QtQuick.Controls
import "../../../theme"

// Colour picker: a palette (12 hues × 4 lightness steps plus greys) or a hex value typed in.
Column {
    id: root
    property color value
    property bool canPromote: false        // a secondary colour can be made the main one
    signal picked(color c)
    signal promote()
    signal done()
    width: parent ? parent.width : 0
    spacing: 12

    // palette: columns are hues 30° apart, rows go from light to dark; the last column is greys
    readonly property var swatches: {
        const rows = [[0.9, 0.72], [0.85, 0.6], [0.8, 0.48], [0.75, 0.36]]
        const greys = ["#f2f2f2", "#b8b8b8", "#7a7a7a", "#3d3d3d"]
        const out = []
        rows.forEach(([s, l], r) => {
            for (let i = 0; i < 12; i++) out.push("#" + Theme.hex(Qt.hsla(i / 12, s, l, 1)))
            out.push(greys[r])
        })
        return out
    }
    function same(a, b) { return Theme.hex(Qt.lighter(a, 1)) === Theme.hex(Qt.lighter(b, 1)) }

    Grid {
        columns: 13
        spacing: 8
        Repeater {
            model: root.swatches
            Swatch {
                required property string modelData
                color: modelData
                selected: root.same(modelData, root.value)
                onClicked: root.picked(modelData)
            }
        }
    }

    Row {
        spacing: 10
        Rectangle {
            width: 40; height: 40; radius: 20
            color: root.value
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.25)
        }
        TextField {
            id: field
            width: 150
            height: 40
            text: "#" + Theme.hex(root.value)
            placeholderText: "#10b981"
            font.family: Theme.font
            font.pixelSize: 14
            font.weight: Font.Bold
            color: Theme.ink
            placeholderTextColor: Theme.inkMuted
            leftPadding: 16
            maximumLength: 7
            validator: RegularExpressionValidator { regularExpression: /#?[0-9a-fA-F]{0,6}/ }
            readonly property bool valid: /^#?([0-9a-f]{3}|[0-9a-f]{6})$/i.test(text)
            background: Rectangle {
                radius: 20
                color: Theme.paneHover
                border.width: field.activeFocus ? 2 : 1
                border.color: !field.valid ? Theme.red : field.activeFocus ? Theme.accent : Theme.paneLine
            }
            // a full value applies at once; a short #abc applies on Enter, as #aabbcc
            onTextEdited: if (/^#?[0-9a-f]{6}$/i.test(text)) root.picked("#" + text.replace("#", ""))
            onAccepted: if (valid) {
                const h = text.replace("#", "")
                root.picked("#" + (h.length === 3 ? h.split("").map(c => c + c).join("") : h))
            }
            Keys.onEscapePressed: root.done()
        }
        Label { anchors.verticalCenter: parent.verticalCenter; text: "hex"; size: 12; muted: true }
    }

    Row {
        spacing: 8
        Rectangle {
            visible: root.canPromote
            width: promo.implicitWidth + 28; height: 36; radius: 18
            color: promoArea.containsMouse ? Theme.paneHover : Theme.pane
            border.width: 1; border.color: Theme.paneLine
            Row {
                id: promo
                anchors.centerIn: parent
                spacing: 6
                Icon { name: "star"; font.pixelSize: 18; anchors.verticalCenter: parent.verticalCenter }
                Label { text: "Make Main"; size: 13; weight: Font.Bold; anchors.verticalCenter: parent.verticalCenter }
            }
            MouseArea { id: promoArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.promote() }
        }
        Rectangle {
            width: doneLbl.implicitWidth + 28; height: 36; radius: 18
            color: doneArea.containsMouse ? Qt.lighter(Theme.accent, 1.1) : Theme.accent
            Label { id: doneLbl; anchors.centerIn: parent; text: "Done"; size: 13; weight: Font.Bold; color: Theme.accentInk; shadow: false }
            MouseArea { id: doneArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.done() }
        }
    }
}
