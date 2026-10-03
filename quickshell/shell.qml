import QtQuick
import Quickshell
import Quickshell.Io
import "services"
import "bar"
import "popups"

// Unia Breathe — корінь оболонки.
ShellRoot {
    // qs -c unia ipc call popups toggle cal|media|power|ws
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
}
