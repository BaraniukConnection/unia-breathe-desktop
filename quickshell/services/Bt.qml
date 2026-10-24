pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Bluetooth

// Bluetooth: power, connected and paired devices.
Singleton {
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool enabled: !!adapter && adapter.enabled
    readonly property var paired: adapter ? adapter.devices.values.filter(d => d.paired) : []
    readonly property var connected: paired.filter(d => d.connected)
    readonly property string name: connected.length ? connected[0].name : ""
}
