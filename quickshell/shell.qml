//@ pragma IconTheme Mint-Breeze-Calm-Green-Icons
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "services"
import "bar"
import "popups"
import "notifications"
import "components/settings-box"
import "components/tile-menu"
import "components/window-drop"
import "dock"
import "screenshot"

// Unia Breathe Desktop: the root of the shell.
ShellRoot {
    // qs -c unia ipc call popups toggle cal|media|power|ws|nc|menu
    // qs -c unia ipc call settings toggle | open <id>
    IpcHandler {
        target: "settings"
        function toggle(): void { Settings.toggle() }
        function open(id: string): void { Settings.open(id) }
        // Super+Tab: in Settings, give the keyboard back to the panel; elsewhere, the next window
        function back(): void { if (Settings.shown) Settings.focusPanel(); else Hyprland.dispatch("cyclenext") }
    }

    // qs -c unia ipc call apps launch <.desktop id>: like a click in the menu (an open single-window app is focused instead)
    IpcHandler {
        target: "apps"
        function launch(id: string): void { Apps.launch(id) }
    }

    // qs -c unia ipc call windows minimize: minimize the active window (Super+M)
    IpcHandler {
        target: "windows"
        function minimize(): void { const w = Windows.list.find(w => w.active && !w.minimized); if (w) Windows.minimize(w) }
    }

    // screenshots: qs -c unia ipc call shot open | screen | window | stop
    IpcHandler {
        target: "shot"
        function open(): void { Shot.open() }
        function screen(): void { Shot.open("screen") }
        function window(): void { Shot.open("window") }
        function stop(): void { if (Shot.recording) Shot.stopRecording() }
        function close(): void { Shot.close() }
    }
    Variants {
        model: Quickshell.screens
        ShotOverlay {}
    }

    // the drop notch on a window's border: drag, minimize, fullscreen, close, move to another desk
    // qs -c unia ipc call drop menu | close: the notch menu for the active window; resize: its resize mode;
    // grab | release: Super+LMB
    Variants {
        model: Quickshell.screens
        WindowDrop {}
    }
    DropPlace {}
    IpcHandler {
        target: "drop"
        function menu(): void { const w = Windows.list.find(w => w.active && !w.minimized); if (w) Drops.openMenu(w.address) }
        function close(): void { Drops.closeMenu() }
        function resize(): void { if (Drops.resizing) { Drops.stopResize(); return } const w = Windows.list.find(w => w.active && !w.minimized); if (w) Drops.startResize(w.address) }
        // Super+LMB (hyprland.conf): pick up the window under the cursor and drop it on release
        function grab(): void { Drops.grab() }
        function release(): void { Drops.release() }
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

    // While a popup is open the bars and the popup stay clickable; a click anywhere else closes it
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
