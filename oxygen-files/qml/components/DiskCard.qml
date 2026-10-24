import QtQuick
import QtQuick.Layouts
import app.loaf

// DiskCard -- one disk on the PC dashboard's Disks section: a large drive icon on
// the left; name, free space, used / total and a usage bar on the right.
// drive: an entry of core.drives_json ({ name, device, is_external, is_mounted,
//        is_locked, total_bytes, used_bytes, free_bytes, percent, ... }).
Item {
    id: root

    Layout.fillWidth: true
    Layout.preferredHeight: 104
    implicitHeight: 104
    implicitWidth: 320

    property var drive: ({})

    signal contextRequested(real x, real y)
    signal activated()

    readonly property bool isMounted: {
        var d = root.drive || {};
        if (d.mounted !== undefined)
            return d.mounted === true;
        return d.is_mounted === true;
    }
    readonly property real totalBytes: Number((root.drive || {}).total_bytes) || 0
    readonly property real usedBytes: Number((root.drive || {}).used_bytes) || 0
    readonly property real freeBytes: {
        var d = root.drive || {};
        if (d.free_bytes !== undefined)
            return Number(d.free_bytes) || 0;
        return Math.max(0, root.totalBytes - root.usedBytes);
    }
    readonly property real usage: root.totalBytes > 0 ? root.usedBytes / root.totalBytes : 0

    function formatBytes(bytes) {
        var b = Number(bytes) || 0;
        var gb = 1024 * 1024 * 1024;
        var tb = 1024 * gb;
        var mb = 1024 * 1024;
        if (b >= tb)
            return (b / tb).toFixed(1) + " TB";
        if (b >= gb)
            return (b / gb).toFixed(1) + " GB";
        if (b >= mb)
            return (b / mb).toFixed(1) + " MB";
        if (b > 0)
            return (b / 1024).toFixed(0) + " KB";
        return "0 B";
    }

    function driveIcon() {
        var d = root.drive || {};
        if (d.is_locked === true)
            return "lock-simple";
        return d.is_external === true ? "usb" : "hard-drive";
    }

    scale: cardMouse.pressed ? 0.97 : (cardMouse.containsMouse ? 1.01 : 1.0)
    Behavior on scale { enabled: theme.animate; SpringAnimation { spring: 3.5; damping: 0.32 } }

    Rectangle {
        anchors.fill: parent
        radius: theme.radiusL
        color: theme.surfaceContainerLow
        Behavior on color { enabled: theme.animate; ColorAnimation { duration: theme.durationFast } }
    }

    Rectangle {
        anchors.fill: parent
        radius: theme.radiusL
        color: cardMouse.containsMouse ? theme.hoverOverlay : "transparent"
        Behavior on color { enabled: theme.animate; ColorAnimation { duration: 100 } }
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 16

        Rectangle {
            Layout.preferredWidth: 72
            Layout.preferredHeight: 72
            radius: theme.radiusL
            color: root.isMounted ? theme.primaryContainer : theme.surfaceContainerHigh

            LoafIcon {
                anchors.centerIn: parent
                name: root.driveIcon()
                size: 38
                color: root.isMounted ? theme.primaryContainerFg : theme.textMuted
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.preferredWidth: 0
            spacing: 3

            Text {
                text: (root.drive && root.drive.name) ? root.drive.name : ""
                color: theme.textMain
                font.pixelSize: theme.fs(15)
                font.bold: true
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Text {
                text: root.isMounted ? qsTr("Free %1").arg(root.formatBytes(root.freeBytes))
                                     : qsTr("Not mounted, click to mount")
                color: root.isMounted ? theme.textMain : theme.textMuted
                font.pixelSize: theme.fs(12)
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Text {
                visible: root.isMounted
                text: qsTr("Used %1 / %2").arg(root.formatBytes(root.usedBytes)).arg(root.formatBytes(root.totalBytes))
                color: theme.textMuted
                font.pixelSize: theme.fs(12)
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            UsageBar {
                visible: root.isMounted
                Layout.fillWidth: true
                Layout.topMargin: 4
                value: root.usage
                barColor: root.usage >= 0.9 ? theme.danger : theme.primary
            }
        }
    }

    MouseArea {
        id: cardMouse
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onClicked: function (mouse) {
            if (mouse.button === Qt.RightButton)
                root.contextRequested(mouse.x + root.x, mouse.y + root.y);
            else
                root.activated();
        }
    }
}
