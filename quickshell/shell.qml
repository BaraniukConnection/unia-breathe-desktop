//@ pragma IconTheme Mint-Breeze-Calm-Green-Icons
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "services"
import "bar"
import "popups"
import "notifications"
import "settings"
import "dock"

// Unia Breathe — корінь оболонки.
ShellRoot {
    // qs -c unia ipc call popups toggle cal|media|power|ws|nc|menu
    // qs -c unia ipc call settings toggle | open <id>
    IpcHandler {
        target: "settings"
        function toggle(): void { Settings.toggle() }
        function open(id: string): void { Settings.open(id) }
    }

    SettingsPanel {}
    SettingsPage {}

    IpcHandler {
        target: "popups"
        function toggle(name: string): void { Popups.request(name) }
        function close(): void { Popups.close() }
    }

    Variants {
        id: bars
        model: Quickshell.screens
        Bar {}
    }
    Variants {
        id: docks
        model: Quickshell.screens
        Dock {}
    }
    Variants {
        id: layers
        model: Quickshell.screens
        PopupLayer {}
    }

    // Поки відкрита панель: смуги й панель лишаються клікабельними, клік будь-де ще — закриває її
    HyprlandFocusGrab {
        active: Popups.current !== ""
        windows: [...bars.instances, ...layers.instances, ...docks.instances.map(d => d.window)]
        onCleared: Popups.close()
    }
    Variants {
        model: Quickshell.screens
        Toasts {}
    }
}
