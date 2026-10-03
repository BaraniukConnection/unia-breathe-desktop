pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Налаштування оболонки (~/.config/unia-breathe/settings.json) і згенерований з них конфіг Hyprland
// (~/.config/unia-breathe/hyprland.conf — його підключає hypr/unia.conf останнім, тож він перекриває основний).
Singleton {
    id: root
    readonly property string dir: Quickshell.env("HOME") + "/.config/unia-breathe"
    property var data: ({ pins: [], clock24: true, hypr: {} })
    property bool ready: false

    function set(key, value) {
        const d = Object.assign({}, data)
        d[key] = value
        data = d
        saveTimer.restart()
    }
    function setHypr(key, value) {
        const h = Object.assign({}, data.hypr ?? {})
        h[key] = value
        set("hypr", h)
    }

    function save() {
        store.setText(JSON.stringify(data, null, 2) + "\n")
        const h = data.hypr ?? {}
        const lines = Object.keys(h).sort().map(k => `${k} = ${h[k]}`)
        conf.setText("# Згенеровано налаштуваннями Unia Breathe — зміни краще робити там\n" + lines.join("\n") + "\n")
    }
    Timer { id: saveTimer; interval: 500; onTriggered: root.save() }

    FileView {
        id: store
        path: root.dir + "/settings.json"
        printErrors: false
        onLoaded: {
            try { root.data = Object.assign({ pins: [], clock24: true, hypr: {} }, JSON.parse(text())) } catch (e) {}
            root.ready = true
        }
        onLoadFailed: root.ready = true
    }
    FileView { id: conf; path: root.dir + "/hyprland.conf"; printErrors: false }
}
