import QtQuick
import QtQuick.Layouts
import app.loaf

// LoafSegmented -- Material 3 segmented control.
// options: [{ value, label, icon }]
Item {
    id: root

    Layout.fillWidth: true
    Layout.preferredHeight: 36
    implicitHeight: 36
    implicitWidth: 160

    property var options: []
    property var value
    property string label: ""

    signal selected(var value)

    transform: Translate { id: segTranslate; y: 0 }

    ParallelAnimation {
        id: segPopAnim
        property int delayMs: 0
        SequentialAnimation {
            PauseAnimation { duration: segPopAnim.delayMs }
            ParallelAnimation {
                NumberAnimation { target: segTranslate; property: "y"; from: -10; to: 0; duration: 200; easing.type: Easing.OutCubic }
                NumberAnimation { target: root; property: "scale"; from: 0.90; to: 1.0; duration: 220; easing.type: Easing.OutBack; easing.overshoot: 1.2 }
                NumberAnimation { target: root; property: "opacity"; from: 0.0; to: 1.0; duration: 160; easing.type: Easing.OutCubic }
            }
        }
    }

    function popIn(delayMs) {
        segPopAnim.stop();
        segTranslate.y = -10;
        root.scale = 0.90;
        root.opacity = 0.0;
        segPopAnim.delayMs = delayMs || 0;
        segPopAnim.start();
    }
    function playPop(delayMs) { popIn(delayMs); }
    function reset() {
        segPopAnim.stop();
        segTranslate.y = 0;
        root.scale = 1.0;
        root.opacity = 1.0;
    }

    readonly property int currentIndex: {
        var opts = root.options || [];
        for (var i = 0; i < opts.length; i++) {
            if (opts[i] && opts[i].value === root.value)
                return i;
        }
        return 0;
    }

    RowLayout {
        anchors.fill: parent
        spacing: 10

        Text {
            text: root.label
            color: theme.textMuted
            font.pixelSize: theme.fs(12)
            visible: root.label.length > 0
        }

        Rectangle {
            id: track
            Layout.fillWidth: true
            Layout.preferredHeight: root.height
            radius: theme.radiusFull
            color: theme.surfaceContainerHighest

            readonly property real segW: track.width / Math.max(1, (root.options ? root.options.length : 1))

            Rectangle {
                id: highlight
                height: track.height - 6
                y: 3
                radius: theme.radiusFull
                color: theme.secondaryContainer
                width: Math.max(0, track.segW - 6)
                x: 3 + root.currentIndex * track.segW

                Behavior on x { enabled: theme.animate; NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                Behavior on width { enabled: theme.animate; NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                Behavior on color { enabled: theme.animate; ColorAnimation { duration: theme.durationFast } }
            }

            RowLayout {
                anchors.fill: parent
                spacing: 0

                Repeater {
                    model: root.options

                    delegate: Item {
                        id: segItem
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        readonly property bool isCurrent: index === root.currentIndex

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 6

                            LoafIcon {
                                visible: !!(modelData && modelData.icon && String(modelData.icon).length > 0)
                                name: (modelData && modelData.icon) ? modelData.icon : ""
                                size: 14
                                color: segItem.isCurrent ? theme.secondaryContainerFg : theme.textMuted
                            }

                            Text {
                                text: (modelData && modelData.label) ? modelData.label : ""
                                color: segItem.isCurrent ? theme.secondaryContainerFg : theme.textMuted
                                font.pixelSize: theme.fs(12)
                                font.bold: segItem.isCurrent
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.value = modelData.value;
                                root.selected(modelData.value);
                            }
                        }
                    }
                }
            }
        }
    }
}
