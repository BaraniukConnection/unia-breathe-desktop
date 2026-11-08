pragma Singleton
import QtQuick
import Quickshell

// Power actions, shared by the ⏻ menu and the control centre.
Singleton {
    readonly property var items: [
        { id: "off", label: "Shut Down", icon: "power_settings_new", confirm: true, cmd: ["systemctl", "poweroff"] },
        { id: "reboot", label: "Restart", icon: "restart_alt", confirm: true, cmd: ["systemctl", "reboot"] },
        // lock the screen fully first, then sleep (bin/unia-sleep); the shell's PATH has no ~/.local/bin
        { id: "sleep", label: "Sleep", icon: "bedtime", confirm: false, cmd: [Quickshell.env("HOME") + "/.local/bin/unia-sleep"] },
        { id: "logout", label: "Log Out", icon: "logout", confirm: true, cmd: ["sh", "-c", "systemctl --user stop hyprland-session.target; hyprctl dispatch \"hl.dsp.exit()\""] },
    ]
    function run(item) { Quickshell.execDetached(item.cmd) }
}
