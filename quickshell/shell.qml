import QtQuick
import Quickshell
import Quickshell.Io
import "services"
import "bar"
import "popups"
import "notifications"

// Unia Breathe — корінь оболонки.
ShellRoot {
    // qs -c unia ipc call popups toggle cal|media|power|ws|nc
    IpcHandler {
        target: "popups"
        function toggle(name: string): void { Popups.request(name) }
        function close(): void { Popups.close() }
    }

    Variants {
        model: Quickshell.screens
        Bar {}
    }
    Variants {
        model: Quickshell.screens
        PopupLayer {}
    }
    Variants {
        model: Quickshell.screens
        Toasts {}
    }
}
