import QtQuick
import QtQuick.Shapes
import "../../theme"

// A notch growing down out of the border, like a front-camera drop.
// y = 0 is the outer edge of the border (band px thick), in the middle of the width; from y = band down is the window.
// depth: 0…1, deeper as the cursor gets closer; at full depth a dot appears inside.
// dotFall: how many px the dot has dropped (as it breaks off into the menu).
Item {
    id: root
    property real depth: 1
    property real band: 3
    property real dotFall: 0
    property real dotOpacity: Math.max(0, Math.min(1, (depth - 0.75) / 0.25))
    property color color: Theme.accent
    readonly property real notchW: 28 + 24 * depth                 // width at the border (with shoulders)
    readonly property real notchD: 18 * depth                      // depth below the border
    readonly property real dotY: band + 18 * 0.5 + dotFall           // centre of the dot
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
            // from the border: a gentle shoulder, steep sides, a round bottom (and mirrored back)
            // start at the inner edge of the border (overlapping 2 px into it): vertical walls inside the border
            // would leave visible seams, since the border colour is a gradient
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
    // the dot in the notch: white, no highlight
    Rectangle {
        width: 7; height: 7; radius: 3.5
        x: root.width / 2 - 3.5
        y: root.dotY - 3.5
        color: "white"
        opacity: root.dotOpacity
    }
}
