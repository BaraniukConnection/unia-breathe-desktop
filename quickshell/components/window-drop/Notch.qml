import QtQuick
import QtQuick.Shapes
import "../../theme"

// Виїмка, що виростає з рамки донизу — як «крапля» під фронтальну камеру.
// y = 0 — зовнішній край рамки (band px завтовшки), посередині ширини; від y = band — вікно.
// depth — глибина (0…1, ближче курсор — глибше); на повну всередині з'являється крапка.
// dotFall — на скільки px крапка опустилась (відриваючись у меню).
Item {
    id: root
    property real depth: 1
    property real band: 3
    property real dotFall: 0
    property real dotOpacity: Math.max(0, Math.min(1, (depth - 0.75) / 0.25))
    property color color: Theme.accent
    readonly property real notchW: 28 + 24 * depth                 // ширина біля рамки (з плечима)
    readonly property real notchD: 18 * depth                      // глибина під рамкою
    readonly property real dotY: band + 18 * 0.5 + dotFall           // центр крапки
    implicitWidth: 60
    implicitHeight: band + 18 + 4

    Shape {
        id: shape
        anchors.fill: parent
        visible: root.depth > 0.01
        preferredRendererType: Shape.CurveRenderer
        readonly property real cx: width / 2
        readonly property real hw: root.notchW / 2
        readonly property real b: root.band
        readonly property real d: root.band + root.notchD
        ShapePath {
            fillColor: root.color
            strokeColor: "transparent"
            strokeWidth: 0
            // від рамки — пологе плече, круті боки, кругле дно (і дзеркально назад)
            // починаємо від внутрішнього краю рамки (з напуском 2 px у її товщу): вертикальні стінки в товщі рамки
            // дали б помітні шви — колір рамки градієнтний
            startX: shape.cx - shape.hw; startY: Math.max(0, shape.b - 2)
            PathCubic {
                x: shape.cx; y: shape.d
                control1X: shape.cx - shape.hw + root.notchW * 0.32; control1Y: shape.b
                control2X: shape.cx - root.notchW * 0.2; control2Y: shape.d
            }
            PathCubic {
                x: shape.cx + shape.hw; y: shape.b
                control1X: shape.cx + root.notchW * 0.2; control1Y: shape.d
                control2X: shape.cx + shape.hw - root.notchW * 0.32; control2Y: shape.b
            }
        }
    }
    // крапка — «камера» у виїмці
    Rectangle {
        width: 7; height: 7; radius: 3.5
        x: root.width / 2 - 3.5
        y: root.dotY - 3.5
        color: Theme.accentInk
        opacity: root.dotOpacity
        Rectangle { x: 1.5; y: 1.5; width: 2; height: 2; radius: 1; color: Qt.rgba(1, 1, 1, 0.5) }
    }
}
