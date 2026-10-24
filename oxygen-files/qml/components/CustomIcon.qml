import QtQuick
import QtQuick.Shapes
import app.loaf

// CustomIcon -- draws a user-picked icon from a "<set>:<value>" spec (see
// Theme.customIcons): a system theme icon, a Simple Icons brand (plain, in
// `color`, or in its brand colour), a Material Symbol, an emoji, or an image
// from a file, a URL or a data: URI.
Item {
    id: root

    property string spec: ""
    property real size: 24
    property color color: theme.textMain

    implicitWidth: size
    implicitHeight: size

    readonly property string kind: spec.indexOf(":") > 0 ? spec.slice(0, spec.indexOf(":")) : ""
    readonly property string value: spec.indexOf(":") > 0 ? spec.slice(spec.indexOf(":") + 1) : ""
    readonly property var simple: (kind === "simple" || kind === "simple-color") ? theme.simpleIcon(value) : null

    function imageUrl() {
        if (kind === "system")
            return core.icon_theme.length > 0 ? core.resolve_icon("system", value) : "";
        if (kind === "user")
            return value;
        if (kind === "image")
            return value.charAt(0) === "/" ? "file://" + value : value;
        return "";
    }

    Image {
        visible: root.kind === "system" || root.kind === "image" || root.kind === "user"
        anchors.fill: parent
        source: visible ? root.imageUrl() : ""
        sourceSize.width: root.size * 2
        sourceSize.height: root.size * 2
        fillMode: Image.PreserveAspectFit
        asynchronous: true
        smooth: true
    }

    // Simple Icons are single 24x24 paths.
    Shape {
        visible: root.simple !== null
        anchors.centerIn: parent
        width: 24
        height: 24
        scale: root.size / 24
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeWidth: -1
            fillColor: root.simple && root.kind === "simple-color" ? "#" + root.simple[2] : root.color
            PathSvg { path: root.simple ? root.simple[3] : "" }
        }
    }

    Text {
        visible: root.kind === "material" || root.kind === "emoji"
        anchors.centerIn: parent
        text: root.value
        color: root.color
        font.family: root.kind === "material" ? theme.materialFamily : ""
        font.pixelSize: root.kind === "emoji" ? root.size * 0.85 : root.size
        renderType: Text.QtRendering
    }
}
