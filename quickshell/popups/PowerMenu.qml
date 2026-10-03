import QtQuick
import Quickshell
import "../theme"
import "../services"

// Меню живлення. Вимкнення й перезавантаження просять другий клік для підтвердження.
Glass {
    id: root
    strong: true
    radius: 16
    width: 232
    height: col.implicitHeight + 12
    property string armed: ""

    readonly property var items: [
        { id: "off", label: "Вимкнути", icon: "power_settings_new", confirm: true, cmd: ["systemctl", "poweroff"] },
        { id: "reboot", label: "Перезавантажити", icon: "restart_alt", confirm: true, cmd: ["systemctl", "reboot"] },
        { id: "sleep", label: "Сон", icon: "bedtime", confirm: false, cmd: ["systemctl", "suspend"] },
        { id: "logout", label: "Вийти з сеансу", icon: "logout", confirm: true, cmd: ["sh", "-c", "systemctl --user stop hyprland-session.target; hyprctl dispatch exit"] },
    ]

    Column {
        id: col
        x: 6; y: 6
        width: parent.width - 12
        Repeater {
            model: root.items
            Rectangle {
                required property var modelData
                readonly property bool isArmed: root.armed === modelData.id
                width: col.width
                height: 40
                radius: 10
                color: isArmed ? Qt.rgba(0.95, 0.39, 0.39, 0.85) : area.containsMouse ? Theme.paneHover : "transparent"
                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    x: 10
                    spacing: 12
                    Icon { name: modelData.icon; color: isArmed ? Theme.ink : Theme.inkMuted; anchors.verticalCenter: parent.verticalCenter }
                    Label { text: isArmed ? "Точно? Клацніть ще раз" : modelData.label; weight: Font.Medium; anchors.verticalCenter: parent.verticalCenter }
                }
                MouseArea {
                    id: area
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (modelData.confirm && !isArmed) { root.armed = modelData.id; return }
                        Popups.close()
                        Quickshell.execDetached(modelData.cmd)
                    }
                }
            }
        }
    }
}
