import QtQuick
import Quickshell
import Quickshell.Widgets
import "../theme"
import "../services"

// Відкриті й згорнуті вікна ліворуч від годинника. Наведення — «Назва · Стіл N»;
// клік — перейти (по активному — згорнути), середня кнопка — закрити, права — згорнути/розгорнути.
Bubble {
    id: root
    required property var barWindow
    property real maxWidth: 400
    readonly property int cell: 34
    readonly property int fit: Math.max(1, Math.floor((maxWidth - 12) / cell))
    readonly property var shown: Windows.list.length > fit ? Windows.list.slice(0, fit - 1) : Windows.list
    readonly property int extra: Windows.list.length - shown.length
    // іконка під курсором: рахуємо за координатою — список вікон часто перебудовується,
    // і власний hover кожної іконки губився б разом з нею
    property int hoverIndex: -1
    readonly property var tipFor: hoverIndex >= 0 && hoverIndex < shown.length ? shown[hoverIndex] : null
    visible: Windows.list.length > 0
    interactive: false
    padLeft: 6
    padRight: 6

    HoverHandler {
        id: hover
        onPointChanged: root.hoverIndex = hovered ? Math.floor((point.position.x - root.padLeft) / root.cell) : -1
        onHoveredChanged: if (!hovered) root.hoverIndex = -1
    }

    Row {
        id: icons
        height: parent.height
        spacing: 0
        Repeater {
            model: root.shown
            Rectangle {
                id: cellItem
                required property var modelData
                required property int index
                width: root.cell; height: 34
                anchors.verticalCenter: parent.verticalCenter
                radius: 12
                color: modelData.active ? Qt.rgba(16 / 255, 185 / 255, 129 / 255, 0.28) : root.hoverIndex === index ? Theme.paneHover : "transparent"
                opacity: modelData.minimized ? 0.45 : 1
                IconImage { anchors.centerIn: parent; implicitSize: 22; source: Windows.icon(cellItem.modelData); asynchronous: true }
                Rectangle {     // крапка під активним вікном
                    visible: cellItem.modelData.active
                    width: 10; height: 3; radius: 2
                    color: Theme.accent
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 1
                }
                MouseArea {
                    id: area
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                    cursorShape: Qt.PointingHandCursor
                    onClicked: m => {
                        const w = cellItem.modelData
                        if (m.button === Qt.MiddleButton) Windows.close(w)
                        else if (m.button === Qt.RightButton) w.minimized ? Windows.focus(w) : Windows.minimize(w)
                        else if (w.active && !w.minimized) Windows.minimize(w)
                        else Windows.focus(w)
                    }
                }
            }
        }
        Label {
            visible: root.extra > 0
            anchors.verticalCenter: parent.verticalCenter
            leftPadding: 4; rightPadding: 6
            text: `+${root.extra}`
            size: 12
            weight: Font.Bold
            muted: true
        }
    }

    // підказка під іконкою
    PopupWindow {
        visible: root.tipFor !== null && Popups.current === ""
        anchor.window: root.barWindow
        anchor.rect.x: {
            const p = icons.mapToItem(null, 0, 0)
            return Math.max(8, p.x + (root.hoverIndex + 0.5) * root.cell - width / 2)
        }
        anchor.rect.y: Theme.top + Theme.bubbleHeight + 6
        implicitWidth: tipBox.width
        implicitHeight: tipBox.height
        color: "transparent"
        Glass {
            id: tipBox
            strong: true
            radius: 14
            width: tipLabel.implicitWidth + 24
            height: 30
            Label { id: tipLabel; anchors.centerIn: parent; size: 12; text: root.tipFor ? Windows.label(root.tipFor) : "" }
        }
    }
}
