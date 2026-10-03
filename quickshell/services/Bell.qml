pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Кількість сповіщень і «Не турбувати» — поки що від SwayNC (на етапі 3 буде власний сервер сповіщень).
Singleton {
    id: root
    property int count: 0
    property bool dnd: false

    function toggle() { Quickshell.execDetached(["swaync-client", "-t", "-sw"]) }

    Process {
        running: true
        command: ["swaync-client", "-swb"]
        stdout: SplitParser {
            onRead: line => {
                try {
                    const d = JSON.parse(line)
                    root.count = parseInt(d.text) || 0
                    root.dnd = d.alt.startsWith("dnd")
                } catch (e) {}
            }
        }
    }
}
