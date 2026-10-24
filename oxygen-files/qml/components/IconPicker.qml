import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import app.loaf

// IconPicker -- picks a custom icon for a folder, a sidebar place or a disk
// (Theme.customIcons). Sets as in Kando: the system icon theme, Simple Icons
// (plain or in brand colours), Material Symbols, emoji, the user's own icon
// themes (~/.config/loaf/icon-themes/<theme>/*.svg) and any image by path,
// URL or data: URI.
LoafDialog {
    id: picker

    property string targetKey: ""
    property string selectedSpec: ""
    property string source: "material"
    property bool brandColors: false
    property string query: ""

    // Set data, loaded on first use.
    property var systemNames: null
    property var materialNames: null
    property var emojiRows: null
    property var userThemes: null

    title: qsTr("Change Icon")
    dialogWidth: 580
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    function openFor(key) {
        picker.targetKey = key;
        picker.selectedSpec = theme.customIcon(key);
        picker.query = "";
        searchField.text = "";
        imageField.text = picker.selectedSpec.indexOf("image:") === 0 ? picker.selectedSpec.slice(6) : "";
        picker.open();
    }

    function load() {
        if (picker.source === "system" && picker.systemNames === null)
            picker.systemNames = JSON.parse(core.icon_set_json("system"));
        else if (picker.source === "material" && picker.materialNames === null)
            picker.materialNames = JSON.parse(core.icon_set_json("material"));
        else if (picker.source === "emoji" && picker.emojiRows === null)
            picker.emojiRows = JSON.parse(core.icon_set_json("emoji"));
        else if (picker.source === "user" && picker.userThemes === null)
            picker.userThemes = JSON.parse(core.icon_set_json("user"));
        else if (picker.source === "simple")
            theme.loadSimpleIcons();
    }

    // [{ spec, label }] for the grid, filtered by the search words.
    readonly property var entries: {
        var q = picker.query.trim().toLowerCase();
        var match = function(text) { return q.length === 0 || text.toLowerCase().indexOf(q) !== -1; };
        var out = [];
        var i;
        if (!picker.visible)
            return out;
        if (picker.source === "system" && picker.systemNames) {
            for (i = 0; i < picker.systemNames.length; ++i)
                if (match(picker.systemNames[i]))
                    out.push({ spec: "system:" + picker.systemNames[i], label: picker.systemNames[i] });
        } else if (picker.source === "simple" && theme.simpleIconRows) {
            var prefix = picker.brandColors ? "simple-color:" : "simple:";
            for (i = 0; i < theme.simpleIconRows.length; ++i) {
                var r = theme.simpleIconRows[i];
                if (match(r[1]) || match(r[0]))
                    out.push({ spec: prefix + r[0], label: r[1] });
            }
        } else if (picker.source === "material" && picker.materialNames) {
            for (i = 0; i < picker.materialNames.length; ++i)
                if (match(picker.materialNames[i].replace(/_/g, " ")))
                    out.push({ spec: "material:" + picker.materialNames[i], label: picker.materialNames[i].replace(/_/g, " ") });
        } else if (picker.source === "emoji" && picker.emojiRows) {
            for (i = 0; i < picker.emojiRows.length; ++i) {
                var e = picker.emojiRows[i];
                if (match(e[1]) || match(e[2]))
                    out.push({ spec: "emoji:" + e[0], label: e[1] });
            }
        } else if (picker.source === "user" && picker.userThemes) {
            for (i = 0; i < picker.userThemes.length; ++i) {
                var t = picker.userThemes[i];
                for (var j = 0; j < t.icons.length; ++j)
                    if (match(t.icons[j].name) || match(t.name))
                        out.push({ spec: "user:" + t.icons[j].url, label: t.name + " / " + t.icons[j].name });
            }
        }
        return out;
    }

    onSourceChanged: picker.load()
    onOpened: picker.load()

    LoafSegmented {
        Layout.fillWidth: true
        options: [
            { value: "system", label: qsTr("System") },
            { value: "simple", label: qsTr("Simple Icons") },
            { value: "material", label: qsTr("Material") },
            { value: "emoji", label: qsTr("Emoji") },
            { value: "user", label: qsTr("Themes") },
            { value: "image", label: qsTr("Image") }
        ]
        value: picker.source
        onSelected: function(v) { picker.source = v; }
    }

    RowLayout {
        Layout.fillWidth: true
        visible: picker.source !== "image"
        spacing: 12

        LoafTextField {
            id: searchField
            Layout.fillWidth: true
            placeholderText: qsTr("Search icons...")
            onTextChanged: searchTimer.restart()
        }

        LoafSwitch {
            visible: picker.source === "simple"
            label: qsTr("Brand colors")
            checked: picker.brandColors
            onToggled: function(c) { picker.brandColors = c; }
        }
    }

    // Typing in a 4000-entry list: filter once the user pauses.
    Timer {
        id: searchTimer
        interval: 160
        onTriggered: picker.query = searchField.text
    }

    Item {
        Layout.fillWidth: true
        Layout.preferredHeight: 312
        visible: picker.source !== "image"

        GridView {
            id: grid
            anchors.fill: parent
            clip: true
            cellWidth: Math.floor(width / Math.max(1, Math.floor(width / 56)))
            cellHeight: 56
            model: picker.entries
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded; width: 6 }

            delegate: Item {
                required property var modelData
                width: grid.cellWidth
                height: grid.cellHeight

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 3
                    radius: theme.radiusM
                    color: picker.selectedSpec === modelData.spec ? theme.primaryContainer
                        : (cellMouse.containsMouse ? theme.hoverOverlay : "transparent")
                    border.width: picker.selectedSpec === modelData.spec ? 2 : 0
                    border.color: theme.primary
                    Behavior on color { enabled: theme.animate; ColorAnimation { duration: theme.durationFast } }
                }

                CustomIcon {
                    anchors.centerIn: parent
                    spec: modelData.spec
                    size: 26
                    color: picker.selectedSpec === modelData.spec ? theme.primaryContainerFg : theme.textMain
                }

                MouseArea {
                    id: cellMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: picker.selectedSpec = modelData.spec
                    onDoubleClicked: picker.apply()
                }

                ToolTip.visible: cellMouse.containsMouse
                ToolTip.text: modelData.label
                ToolTip.delay: 400
            }
        }

        Text {
            anchors.centerIn: parent
            visible: grid.count === 0
            width: parent.width - 48
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            text: picker.source === "user" && picker.query.length === 0
                ? qsTr("No icon themes yet. Put folders of SVG or PNG icons in ~/.config/loaf/icon-themes and reopen this dialog.")
                : qsTr("No icons match your search.")
            color: theme.textMuted
            font.pixelSize: theme.fs(12)
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        visible: picker.source === "image"
        spacing: 12

        LoafTextField {
            id: imageField
            Layout.fillWidth: true
            placeholderText: qsTr("File path, URL or data: URI")
            onTextChanged: {
                var t = text.trim();
                if (picker.source === "image")
                    picker.selectedSpec = t.length > 0 ? "image:" + t : "";
            }
        }

        RowLayout {
            spacing: 16
            Rectangle {
                Layout.preferredWidth: 72
                Layout.preferredHeight: 72
                radius: theme.radiusL
                color: theme.surfaceContainerHighest
                CustomIcon {
                    anchors.centerIn: parent
                    spec: picker.source === "image" ? picker.selectedSpec : ""
                    size: 48
                }
            }
            Text {
                Layout.fillWidth: true
                text: qsTr("SVG, PNG, JPEG or WebP. A local file is read from its path every time, so keep it where it is.")
                color: theme.textMuted
                font.pixelSize: theme.fs(12)
                wrapMode: Text.WordWrap
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        LoafButton {
            text: qsTr("Reset")
            icon: "arrow-counter-clockwise"
            variant: "text"
            enabled: theme.customIcon(picker.targetKey).length > 0
            onClicked: {
                theme.setCustomIcon(picker.targetKey, "");
                picker.close();
            }
        }
        Item { Layout.fillWidth: true }
        LoafButton {
            text: qsTr("Cancel")
            variant: "text"
            onClicked: picker.close()
        }
        LoafButton {
            text: qsTr("Apply")
            variant: "filled"
            enabled: picker.selectedSpec.length > 0
            onClicked: picker.apply()
        }
    }

    function apply() {
        if (picker.selectedSpec.length > 0)
            theme.setCustomIcon(picker.targetKey, picker.selectedSpec);
        picker.close();
    }
}
