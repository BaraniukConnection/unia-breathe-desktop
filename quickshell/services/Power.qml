pragma Singleton
import QtQuick
import Quickshell

// Дії живлення — спільні для меню ⏻ і панелі керування.
Singleton {
    readonly property var items: [
        { id: "off", label: "Вимкнути", icon: "power_settings_new", confirm: true, cmd: ["systemctl", "poweroff"] },
        { id: "reboot", label: "Перезавантажити", icon: "restart_alt", confirm: true, cmd: ["systemctl", "reboot"] },
        { id: "sleep", label: "Сон", icon: "bedtime", confirm: false, cmd: ["systemctl", "suspend"] },
        { id: "logout", label: "Вийти з сеансу", icon: "logout", confirm: true, cmd: ["sh", "-c", "systemctl --user stop hyprland-session.target; hyprctl dispatch exit"] },
    ]
    function run(item) { Quickshell.execDetached(item.cmd) }
}
