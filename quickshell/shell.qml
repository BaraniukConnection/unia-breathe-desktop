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

// Unia Breathe — корінь оболонки.
ShellRoot {
    // qs -c unia ipc call popups toggle cal|media|power|ws|nc|menu
    // qs -c unia ipc call settings toggle | open <id>
    IpcHandler {
        target: "settings"
        function toggle(): void { Settings.toggle() }
        function open(id: string): void { Settings.open(id) }
        // Super+Tab: у налаштуваннях — повернути клавіатуру в панель; поза ними — наступне вікно
        function back(): void { if (Settings.shown) Settings.focusPanel(); else Hyprland.dispatch("cyclenext") }
    }

    // qs -c unia ipc call apps launch <id .desktop> — як клік у меню (відкрита «одновіконна» програма — перехід до неї)
    IpcHandler {
        target: "apps"
        function launch(id: string): void { Apps.launch(id) }
    }

    // qs -c unia ipc call windows minimize — згорнути активне вікно (Super+M)
    IpcHandler {
        target: "windows"
        function minimize(): void { const w = Windows.list.find(w => w.active && !w.minimized); if (w) Windows.minimize(w) }
    }

    // знімки екрана: qs -c unia ipc call shot open | screen | window | stop
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

    // виїмка-«крапля» на рамці вікна: тягнути, згорнути, на весь екран, закрити, на інший стіл
    // qs -c unia ipc call drop menu | close — меню виїмки для активного вікна; grab | release — Super+ЛКМ
    Variants {
        model: Quickshell.screens
        WindowDrop {}
    }
    DropPlace {}
    IpcHandler {
        target: "drop"
        function menu(): void { const w = Windows.list.find(w => w.active && !w.minimized); if (w) Drops.openMenu(w.address) }
        function close(): void { Drops.closeMenu() }
        // Super+ЛКМ (hyprland.conf): узяти вікно під курсором і поставити, відпустивши
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
