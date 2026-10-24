pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "../../services"

// Scenarios: the list (unia-scenario list), which one is open on which desk, open / save / delete.
Singleton {
    id: root
    readonly property string home: Quickshell.env("HOME")
    readonly property string bin: home + "/.local/bin/unia-scenario"
    property var list: []              // [{ name, windows: [{ class, workspace, monitor, floating, at, size }] }]
    property var state: ({})           // "1" → "OxygenDev"
    property string loading: ""        // the scenario being opened right now

    function refresh() { lister.running = true }
    function nameFor(wsId) { return state[String(wsId)] ?? "" }
    function find(name) { return list.find(s => s.name === name) ?? null }

    function load(name) {
        loading = name
        Quickshell.execDetached(["sh", "-c", `"${bin}" load "$1"`, "sh", name])
    }
    function save(name) { runner.command = [bin, "save", name]; runner.running = true }
    function remove(name) { runner.command = [bin, "delete", name]; runner.running = true }

    // whether the desk's set of apps differs from the scenario (window classes; positions do not matter,
    // a minimized window counts as on its desk)
    function modified(wsId) {
        const sc = find(nameFor(wsId))
        if (!sc) return false
        const want = sc.windows.filter(w => w.workspace === String(wsId)).map(w => w.class.toLowerCase()).sort()
        const have = Windows.list
            .filter(w => w.minimized ? Windows.origin[w.address] === wsId : w.wsId === wsId)
            .map(w => w.cls.toLowerCase()).sort()
        return want.join() !== have.join()
    }

    // an app on the desk changed: the scenario no longer applies there ("Empty")
    function dropChanged() {
        // while a window is dragged (WindowDrop) the desk's apps differ only for a moment
        if (loading !== "" || !settled || Windows.list.length === 0 || Windows.moving) return
        const s = Object.assign({}, state)
        let changed = false
        for (const k of Object.keys(s)) {
            const id = Number(k)
            if (Number.isInteger(id) && modified(id)) { delete s[k]; changed = true }
        }
        if (changed) { state = s; stateFile.setText(JSON.stringify(s)) }
    }
    // in the first seconds after start the window list is incomplete: leave the state alone so it is not reset by mistake
    property bool settled: false
    Timer { running: true; interval: 4000; onTriggered: { root.settled = true; root.dropChanged() } }
    Connections { target: Windows; function onListChanged() { dropCheck.restart() } function onMovingChanged() { dropCheck.restart() } }
    Timer { id: dropCheck; interval: 800; onTriggered: root.dropChanged() }

    Component.onCompleted: refresh()

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
        id: stateFile
        path: root.home + "/.cache/unia-breathe/scenario-state.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: { try { root.state = JSON.parse(text()) } catch (e) { root.state = {} } root.loading = "" }
    }

}
