pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

// Сценарії: список (unia-scenario list), який відкрито на якому столі, запуск/збереження/видалення.
Singleton {
    id: root
    readonly property string home: Quickshell.env("HOME")
    readonly property string bin: home + "/.local/bin/unia-scenario"
    property var list: []              // [{ name, windows: [{ class, workspace, monitor, floating, at, size }] }]
    property var state: ({})           // "1" → "OxygenDev"
    property string loading: ""        // сценарій, що зараз відкривається

    function refresh() { lister.running = true }
    function nameFor(wsId) { return state[String(wsId)] ?? "" }
    function find(name) { return list.find(s => s.name === name) ?? null }

    function load(name) {
        loading = name
        Quickshell.execDetached(["sh", "-c", `"${bin}" load "$1"`, "sh", name])
    }
    function save(name) { runner.command = [bin, "save", name]; runner.running = true }
    function remove(name) { runner.command = [bin, "delete", name]; runner.running = true }

    // чи змінився набір вікон на столі відносно сценарію (порівнюємо класи вікон)
    function modified(wsId) {
        const sc = find(nameFor(wsId))
        if (!sc) return false
        const want = sc.windows.filter(w => w.workspace === String(wsId)).map(w => w.class.toLowerCase()).sort()
        const have = Hyprland.toplevels.values
            .filter(t => t.workspace && t.workspace.id === wsId && t.lastIpcObject && t.lastIpcObject.class)
            .map(t => t.lastIpcObject.class.toLowerCase()).sort()
        return want.join() !== have.join()
    }

    Component.onCompleted: { refresh(); Hyprland.refreshToplevels() }

    Process {
        id: lister
        command: [root.bin, "list"]
        stdout: StdioCollector { onStreamFinished: { try { root.list = JSON.parse(text) } catch (e) {} } }
    }
    Process {
        id: runner
        onExited: root.refresh()
    }

    FileView {
        path: root.home + "/.cache/unia-breathe/scenario-state.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: { try { root.state = JSON.parse(text()) } catch (e) { root.state = {} } root.loading = "" }
    }

    // класи вікон (lastIpcObject) оновлюються лише на запит — просимо після змін вікон
    Connections {
        target: Hyprland
        function onRawEvent(ev) {
            if (["openwindow", "closewindow", "movewindowv2"].includes(ev.name)) refreshTimer.restart()
        }
    }
    Timer { id: refreshTimer; interval: 300; onTriggered: Hyprland.refreshToplevels() }
}
