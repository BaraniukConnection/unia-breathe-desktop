import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../theme"
import "../services"

// Док одного монітора: 5 обраних програм і стрілка меню. Схований; виїжджає, коли курсор торкається
// нижнього краю екрана (як в Ubuntu), ховається, коли курсор пішов, а меню закрите.
Scope {
    id: root
    required property var modelData
    readonly property var screen: modelData
    readonly property bool menuOpen: Popups.isOpen("menu", screen)
    property bool peek: false
    onMenuOpenChanged: if (!menuOpen) hide.restart()
    // зсув доку вниз (126 — повністю схований); анімуємо окремо, щоб видимість вікна не залежала від анімації y
    property real offset: 126
    onShownChanged: { slide.to = shown ? 0 : 126; slide.restart() }
    NumberAnimation { id: slide; target: root; property: "offset"; duration: 220; easing.type: Easing.OutCubic }
    readonly property bool shown: peek || menuOpen
    readonly property alias window: win

    // відкриття меню з клавіатури (Super+R) — на моніторі з фокусом
    Connections {
        target: Popups
        function onRequest(name) {
            if (name !== "menu" || !Hyprland.focusedMonitor || Hyprland.focusedMonitor.name !== root.screen.name) return
            Popups.toggle("menu", root.screen, arrow)
        }
    }

    // тонка смужка біля нижнього краю — «гачок» для курсора
    PanelWindow {
        screen: root.screen
        WlrLayershell.namespace: "unia-dock-edge"
        exclusionMode: ExclusionMode.Ignore
        anchors { bottom: true; left: true; right: true }
        implicitHeight: 2
        color: "transparent"
        MouseArea { id: edge; anchors.fill: parent; hoverEnabled: true; onContainsMouseChanged: if (containsMouse) { root.peek = true; hide.restart() } }
    }

    PanelWindow {
        id: win
        screen: root.screen
        visible: root.shown || root.offset < 126
        WlrLayershell.namespace: "unia-dock"
        exclusionMode: ExclusionMode.Ignore
        anchors.bottom: true
        implicitWidth: 376
        implicitHeight: 126
        color: "transparent"

        HoverHandler {
            id: hover
            onHoveredChanged: hovered ? hide.stop() : hide.restart()
        }

        Item {
            id: body
            width: parent.width
            height: parent.height
            y: root.offset

            Row {
                id: favs
                anchors.horizontalCenter: parent.horizontalCenter
                y: 6
                spacing: 12
                Repeater {
                    model: Menu.maxFavs
                    Rectangle {
                        id: fav
                        required property int index
                        readonly property string app: Menu.data.favs[index] ?? ""
                        width: 64; height: 64; radius: 32
                        color: app ? (favArea.containsMouse ? Qt.rgba(1, 1, 1, 0.2) : Theme.glass) : "transparent"
                        border.width: 1
                        border.color: app ? Theme.paneLine : Qt.rgba(1, 1, 1, 0.08)
                        scale: favArea.pressed ? 0.94 : 1
                        Behavior on scale { NumberAnimation { duration: 100 } }
                        AppIcon { anchors.centerIn: parent; app: fav.app; implicitSize: 40; visible: fav.app !== "" }
                        MouseArea {
                            id: favArea
                            anchors.fill: parent
                            enabled: fav.app !== ""
                            hoverEnabled: true
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            cursorShape: Qt.PointingHandCursor
                            onClicked: m => {
                                if (m.button === Qt.RightButton) { Menu.toggleFav(fav.app); return }
                                Apps.launch(fav.app)
                                Popups.close()
                            }
                        }
                    }
                }
            }

            // стрілка меню
            Glass {
                id: arrow
                anchors.horizontalCenter: parent.horizontalCenter
                y: 78
                width: 88; height: 28
                radius: 14
                border.width: root.menuOpen ? 2 : 1
                border.color: root.menuOpen ? Theme.accent : Theme.paneLine
                Icon { anchors.centerIn: parent; name: "keyboard_arrow_up"; font.pixelSize: 24; rotation: root.menuOpen ? 180 : 0
                       Behavior on rotation { NumberAnimation { duration: 200 } } }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Popups.toggle("menu", root.screen, arrow) }
            }
        }
    }

    // ховаємо, коли курсор не на доці й не на краю; інакше перевіряємо знову трохи пізніше
    Timer { id: hide; interval: 900; onTriggered: if (hover.hovered || edge.containsMouse) restart(); else root.peek = false }
}
