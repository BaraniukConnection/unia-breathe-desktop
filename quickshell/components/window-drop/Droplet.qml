import QtQuick
import QtQuick.Shapes
import "../../theme"

// Краплина, що звисає з рамки: верх (y = 0) — лінія рамки, посередині ширини.
// grow — поява (0…1); neck — наскільки тримається за рамку (1 — тримається, 0 — відірвалась);
// fall — на скільки px опустилась кулька.
Item {
    id: root
    property real grow: 1
    property real neck: 1
    property real fall: 0
    property color color: Theme.accent
    readonly property real radius: 8 * grow
    readonly property real ballY: 4 + 16 * grow + fall                          // центр кульки
    readonly property real ballX: width / 2
    implicitWidth: 40
    implicitHeight: 44

    Shape {
        id: shape
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        readonly property real cx: root.ballX
        readonly property real r: root.radius
        readonly property real d: root.ballY
        // «шийка»: біля рамки розтікається (меніск), нижче — вузька талія, далі кулька;
        // відриваючись, звужується до хвостика над кулькою
        readonly property real neckY: (d - r * 2.1) * (1 - root.neck)
        readonly property real neckW: 20 * root.grow * root.neck
        ShapePath {
            fillColor: root.color
            strokeColor: "transparent"
            strokeWidth: 0
            startX: shape.cx - shape.neckW / 2; startY: shape.neckY
            PathCubic {
                x: shape.cx - shape.r; y: shape.d
                control1X: shape.cx - 1.5; control1Y: shape.neckY + 1.5
                control2X: shape.cx - shape.r * 0.85; control2Y: shape.d - shape.r * 1.9
            }
            PathArc { x: shape.cx + shape.r; y: shape.d; radiusX: shape.r; radiusY: shape.r; direction: PathArc.Counterclockwise }
            PathCubic {
                x: shape.cx + shape.neckW / 2; y: shape.neckY
                control1X: shape.cx + shape.r * 0.85; control1Y: shape.d - shape.r * 1.9
                control2X: shape.cx + 1.5; control2Y: shape.neckY + 1.5
            }
        }
    }
    // відблиск на кульці
    Rectangle {
        width: root.radius * 0.7; height: width; radius: width / 2
        x: root.ballX - root.radius * 0.55; y: root.ballY - root.radius * 0.6
        color: Qt.rgba(1, 1, 1, 0.55)
    }
}
