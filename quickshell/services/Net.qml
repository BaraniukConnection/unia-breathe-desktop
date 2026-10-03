pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Networking

// Wi-Fi: увімкнено, назва мережі, сила сигналу.
Singleton {
    id: root
    readonly property bool enabled: Networking.wifiEnabled
    readonly property var wifi: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var network: wifi ? wifi.networks.values.find(n => n.connected) ?? null : null
    readonly property string name: network ? network.name : ""
    readonly property int signal: network ? Math.round(network.signalStrength * 100) : 0
    readonly property bool wired: Networking.devices.values.some(d => d.type === DeviceType.Wired && d.connected)
}
