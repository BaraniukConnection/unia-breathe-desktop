import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Hyprland
import "../../theme"
import "../../services"
import "../../popups"

// Сценарії: картки з мініатюрою розкладки. Клік — відкрити, права кнопка — видалити,
// «Зберегти сценарій» — назва прямо тут.
Section {
    id: root
    required property var screen
    readonly property var monitor: Hyprland.monitorFor(screen)
    readonly property int wsId: monitor && monitor.activeWorkspace ? monitor.activeWorkspace.id : 0
    property string deleting: ""
    readonly property var marks: [Theme.blue, Theme.amber, Theme.mint, Theme.purple, Theme.red, Theme.emerald]

    Component.onCompleted: Scenarios.refresh()

    Item {
        width: parent.width
        height: 40
        Label { anchors.verticalCenter: parent.verticalCenter; text: "Сценарії"; weight: Font.Bold }
        Pill {
            visible: !form.visible
            anchors.right: parent.right
            anchors.rightMargin: -6
            anchors.verticalCenter: parent.verticalCenter
            width: saveRow.implicitWidth + 24
            hovered: saveArea.containsMouse
            color: hovered ? Theme.paneHover : "transparent"
            border.width: 0
            Row {
                id: saveRow
                anchors.centerIn: parent
                spacing: 6
                Icon { name: "save"; font.pixelSize: 18; color: Theme.inkMuted; anchors.verticalCenter: parent.verticalCenter }
                Label { text: "Зберегти сценарій"; size: 13; anchors.verticalCenter: parent.verticalCenter }
            }
            MouseArea {
                id: saveArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    let k = 1
                    while (Scenarios.find("Сценарій " + k)) k++
                    nameField.text = Scenarios.nameFor(root.wsId) || "Сценарій " + k
                    form.visible = true
                    nameField.forceActiveFocus()
                    nameField.selectAll()
                }
            }
        }
    }

    // поле назви
    Row {
        id: form
        visible: false
        width: parent.width
        spacing: 8
        bottomPadding: 6
        TextField {
            id: nameField
            width: parent.width - ok.width - 8
            height: 40
            maximumLength: 14
            placeholderText: "Назва сценарію"
            font.family: Theme.font
            font.pixelSize: 14
            color: Theme.ink
            placeholderTextColor: Theme.inkMuted
            leftPadding: 14
            background: Rectangle { radius: 20; color: Theme.paneHover; border.width: 1; border.color: Theme.accent }
            onAccepted: ok.save()
            Keys.onEscapePressed: form.visible = false
        }
        Rectangle {
            id: ok
            width: okLabel.implicitWidth + 32
            height: 40
            radius: 20
            color: Theme.accent
            function save() {
                const n = nameField.text.trim()
                if (!n) return
                Scenarios.save(n)
                form.visible = false
            }
            Label { id: okLabel; anchors.centerIn: parent; text: "Зберегти"; weight: Font.Bold; color: Theme.accentInk; shadow: false }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: ok.save() }
        }
    }

    ListView {
        id: cards
        width: parent.width
        height: 92
        orientation: ListView.Horizontal
        spacing: 8
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        model: [{ name: "", windows: [] }, ...Scenarios.list]      // перша картка — порожній стіл

        delegate: Rectangle {
            id: card
            required property var modelData
            required property int index
            readonly property bool empty: modelData.name === ""
            readonly property bool on: !empty && Scenarios.nameFor(root.wsId) === modelData.name
            readonly property bool del: root.deleting === modelData.name && !empty
            width: 92
            height: 92
            radius: 16
            color: del ? Qt.rgba(0.95, 0.39, 0.39, 0.3) : cardArea.containsMouse ? Theme.paneHover : "transparent"
            border.width: on ? 2 : 0
            border.color: Theme.accent

            // мініатюра: вікна сценарію, вписані в прямокутник
            Rectangle {
                id: prev
                x: 8; y: 8
                width: 76; height: 46
                radius: 10
                color: Theme.pane
                border.width: card.empty ? 1 : 0
                border.color: Theme.inkMuted
                Icon { visible: card.empty; anchors.centerIn: parent; name: "add"; color: Theme.inkMuted }
                Repeater {
                    model: {
                        const w = card.modelData.windows
                        if (!w.length) return []
                        const x0 = Math.min(...w.map(v => v.at[0])), y0 = Math.min(...w.map(v => v.at[1]))
                        const x1 = Math.max(...w.map(v => v.at[0] + v.size[0])), y1 = Math.max(...w.map(v => v.at[1] + v.size[1]))
                        const sx = (prev.width - 6) / (x1 - x0), sy = (prev.height - 6) / (y1 - y0)
                        return w.map((v, i) => ({ x: 3 + (v.at[0] - x0) * sx, y: 3 + (v.at[1] - y0) * sy, w: v.size[0] * sx - 2, h: v.size[1] * sy - 2, i: i }))
                    }
                    Rectangle {
                        required property var modelData
                        x: modelData.x; y: modelData.y
                        width: Math.max(2, modelData.w); height: Math.max(2, modelData.h)
                        radius: 3
                        color: root.marks[modelData.i % root.marks.length]
                        opacity: 0.85
                    }
                }
            }
            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                y: 60
                width: parent.width - 8
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                text: card.del ? "Видалити?" : card.empty ? "Порожній" : Scenarios.loading === card.modelData.name ? "Відкриваю…" : card.modelData.name
                size: 12
                weight: Font.Bold
                color: card.del ? Theme.red : Theme.ink
            }
            MouseArea {
                id: cardArea
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                cursorShape: Qt.PointingHandCursor
                onClicked: m => {
                    if (m.button === Qt.RightButton) { if (!card.empty) { root.deleting = card.modelData.name; undel.restart() } return }
                    if (card.del) { Scenarios.remove(card.modelData.name); root.deleting = ""; return }
                    Popups.close()
                    if (card.empty) { Hyprland.dispatch(`focusmonitor ${root.monitor.name}`); Hyprland.dispatch("workspace empty") }
                    else Scenarios.load(card.modelData.name)
                }
            }
        }
    }
    Label {
        visible: Scenarios.list.length === 0
        text: "Розстав вікна і збережи їх як сценарій"
        size: 12
        muted: true
        bottomPadding: 6
    }
    Timer { id: undel; interval: 3000; onTriggered: root.deleting = "" }
}
