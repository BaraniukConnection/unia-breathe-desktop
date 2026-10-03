import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Networking
import "../theme"
import "../services"

// Панель керування й сповіщень: Wi-Fi, Bluetooth, закріплені налаштування, гучність, сповіщення, живлення.
Glass {
    id: root
    width: 448
    height: col.implicitHeight + 24
    property string sub: ""          // "wifi" | "bt" — розгорнутий список під плитками
    property string armed: ""        // кнопка живлення, що чекає підтвердження

    component Tile: Rectangle {
        id: tile
        property string icon
        property string name
        property string subText
        property bool on: false
        property bool expanded: false
        signal toggled()
        signal expand()
        height: 76
        radius: Theme.radiusTile
        color: on ? Theme.accent : tileArea.containsMouse ? Qt.rgba(1, 1, 1, 0.2) : Theme.paneHover
        border.width: on ? 0 : 1
        border.color: Theme.paneLine
        MouseArea { id: tileArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: tile.toggled() }
        Icon { x: 10; y: 10; name: tile.icon; font.pixelSize: 22; color: tile.on ? Theme.accentInk : Theme.ink }
        IconButton {
            x: parent.width - width - 6; y: 6
            implicitWidth: 30; implicitHeight: 30
            icon: tile.expanded ? "expand_less" : "chevron_right"
            onClicked: tile.expand()
        }
        Column {
            x: 10
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 8
            width: parent.width - 20
            Label { text: tile.name; size: 13; weight: Font.Bold; color: tile.on ? Theme.accentInk : Theme.ink; shadow: !tile.on }
            Label { width: parent.width; text: tile.subText; size: 12; weight: Font.Medium; elide: Text.ElideRight; color: tile.on ? Theme.accentInk : Theme.inkMuted; shadow: !tile.on; opacity: tile.on ? 0.8 : 1 }
        }
    }

    // рядок списку мереж / пристроїв
    component ListRow: Rectangle {
        id: lr
        property string icon
        property string text
        property string subText
        property bool current: false
        signal clicked()
        width: parent ? parent.width : 0
        height: 40
        radius: 12
        color: lrArea.containsMouse ? Theme.paneHover : "transparent"
        Row {
            x: 10
            anchors.verticalCenter: parent.verticalCenter
            spacing: 10
            Icon { name: lr.icon; font.pixelSize: 18; color: lr.current ? Theme.accent : Theme.inkMuted; anchors.verticalCenter: parent.verticalCenter }
            Label { text: lr.text; size: 13; weight: lr.current ? Font.Bold : Font.DemiBold; anchors.verticalCenter: parent.verticalCenter }
        }
        Label { anchors.right: parent.right; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter; text: lr.subText; size: 12; muted: true }
        MouseArea { id: lrArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: lr.clicked() }
    }

    Column {
        id: col
        x: 12; y: 12
        width: parent.width - 24
        spacing: 12

        // ---------- швидкі налаштування ----------
        Section {
            width: parent.width
            pad: 12
            Row {
                width: parent.width
                spacing: 8
                readonly property int tileW: (width - pins.width - 16) / 2
                Tile {
                    width: parent.tileW
                    icon: Net.wired ? "lan" : Net.enabled ? "wifi" : "wifi_off"
                    name: "Wi-Fi"
                    subText: !Net.enabled ? "Вимкнено" : Net.name || "Не під'єднано"
                    on: Net.enabled
                    expanded: root.sub === "wifi"
                    onToggled: Networking.wifiEnabled = !Networking.wifiEnabled
                    onExpand: root.sub = root.sub === "wifi" ? "" : "wifi"
                }
                Tile {
                    width: parent.tileW
                    icon: Bt.enabled ? "bluetooth" : "bluetooth_disabled"
                    name: "Bluetooth"
                    subText: !Bt.enabled ? "Вимкнено" : Bt.name || "Не під'єднано"
                    on: Bt.enabled
                    expanded: root.sub === "bt"
                    onToggled: if (Bt.adapter) Bt.adapter.enabled = !Bt.adapter.enabled
                    onExpand: root.sub = root.sub === "bt" ? "" : "bt"
                }
                Grid {
                    id: pins
                    columns: 3
                    spacing: 4
                    Repeater {
                        model: 6
                        Rectangle {   // місця для закріплених налаштувань (етап 5)
                            width: 36; height: 36; radius: 18
                            color: Theme.pane
                            border.width: 1
                            border.color: Theme.paneLine
                            Icon { anchors.centerIn: parent; name: "push_pin"; font.pixelSize: 18; color: Theme.inkMuted; opacity: 0.6 }
                        }
                    }
                }
            }

            // розгорнутий список мереж Wi-Fi
            Column {
                width: parent.width
                visible: root.sub === "wifi"
                topPadding: 6
                property var wifi: Net.wifi
                onVisibleChanged: if (wifi) wifi.scannerEnabled = visible
                Repeater {
                    model: Net.wifi ? Net.wifi.networks.values.filter(n => n.name).sort((a, b) => b.connected - a.connected || b.signalStrength - a.signalStrength).slice(0, 8) : []
                    ListRow {
                        required property var modelData
                        readonly property bool secure: modelData.security !== WifiSecurityType.Open
                        icon: modelData.signalStrength > 0.75 ? "network_wifi" : modelData.signalStrength > 0.5 ? "network_wifi_3_bar" : modelData.signalStrength > 0.25 ? "network_wifi_2_bar" : "network_wifi_1_bar"
                        text: modelData.name
                        subText: modelData.connected ? "під'єднано" : secure && !modelData.known ? "🔒" : ""
                        current: modelData.connected
                        onClicked: {
                            if (modelData.connected) modelData.disconnect()
                            else if (modelData.known || !secure) modelData.connect()
                            else { pass.ssid = modelData.name; pass.visible = true; pass.forceActiveFocus() }
                        }
                    }
                }
                // пароль для нової захищеної мережі
                TextField {
                    id: pass
                    property string ssid
                    visible: false
                    width: parent.width
                    height: 40
                    echoMode: TextInput.Password
                    placeholderText: `Пароль для «${ssid}»`
                    font.family: Theme.font
                    color: Theme.ink
                    placeholderTextColor: Theme.inkMuted
                    background: Rectangle { radius: 12; color: Theme.paneHover; border.width: 1; border.color: Theme.accent }
                    onAccepted: {
                        Quickshell.execDetached(["nmcli", "dev", "wifi", "connect", ssid, "password", text])
                        text = ""
                        visible = false
                    }
                    Keys.onEscapePressed: { text = ""; visible = false }
                }
                ListRow { icon: "settings"; text: "Параметри мереж…"; onClicked: { Popups.close(); Quickshell.execDetached(["nm-connection-editor"]) } }
            }

            // розгорнутий список Bluetooth-пристроїв
            Column {
                width: parent.width
                visible: root.sub === "bt"
                topPadding: 6
                Repeater {
                    model: Bt.paired
                    ListRow {
                        required property var modelData
                        icon: modelData.icon && modelData.icon.indexOf("audio") >= 0 ? "headphones" : modelData.icon && modelData.icon.indexOf("input") >= 0 ? "mouse" : "bluetooth"
                        text: modelData.name
                        subText: modelData.connected ? (modelData.batteryAvailable ? `${Math.round(modelData.battery * 100)}% · ` : "") + "під'єднано" : ""
                        current: modelData.connected
                        onClicked: modelData.connected ? modelData.disconnect() : modelData.connect()
                    }
                }
                ListRow { icon: "add"; text: "Додати пристрій…"; onClicked: { Popups.close(); Quickshell.execDetached(["flatpak", "run", "io.github.kaii_lb.Overskride"]) } }
            }

            // гучність: смуга-заливка, клік/перетягування задає значення
            Rectangle {
                width: parent.width
                height: 44
                radius: 22
                color: Theme.paneHover
                border.width: 1
                border.color: Theme.paneLine
                clip: true
                Rectangle {
                    width: Math.max(height, parent.width * (Audio.muted ? 0 : Audio.volume) / 100)
                    height: parent.height
                    radius: 22
                    color: Theme.accent
                    opacity: Audio.muted ? 0 : 0.85
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    function set(x) { Audio.setVolume(Math.round(x / width * 100)) }
                    onPressed: m => set(m.x)
                    onPositionChanged: m => set(m.x)
                    onWheel: w => Audio.setVolume(Audio.volume + (w.angleDelta.y > 0 ? 2 : -2))
                }
                IconButton {
                    x: 6; anchors.verticalCenter: parent.verticalCenter
                    implicitWidth: 32; implicitHeight: 32
                    icon: Audio.icon
                    onClicked: Audio.toggleMute()
                }
                Label {
                    anchors.right: parent.right; anchors.rightMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    text: Audio.muted ? "вимк." : `${Audio.volume}%`
                    weight: Font.Bold
                }
            }
        }

        // ---------- сповіщення ----------
        Section {
            width: parent.width
            Item {
                width: parent.width
                height: 40
                Label { anchors.verticalCenter: parent.verticalCenter; text: "Сповіщення"; weight: Font.Bold }
                Row {
                    anchors.right: parent.right
                    anchors.rightMargin: -6
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6
                    Pill {
                        visible: Notifs.count > 0
                        width: clr.implicitWidth + 24
                        hovered: clrArea.containsMouse
                        Label { id: clr; anchors.centerIn: parent; text: "Очистити"; size: 12; weight: Font.Bold }
                        MouseArea { id: clrArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Notifs.clear() }
                    }
                    Pill {
                        width: dndRow.implicitWidth + 24
                        on: Notifs.dnd
                        hovered: dndArea.containsMouse
                        Row {
                            id: dndRow
                            anchors.centerIn: parent
                            spacing: 6
                            Icon { name: "do_not_disturb_on"; font.pixelSize: 16; color: Notifs.dnd ? Theme.accentInk : Theme.ink; anchors.verticalCenter: parent.verticalCenter }
                            Label { text: "Не турбувати"; size: 12; weight: Font.Bold; color: Notifs.dnd ? Theme.accentInk : Theme.ink; shadow: !Notifs.dnd; anchors.verticalCenter: parent.verticalCenter }
                        }
                        MouseArea { id: dndArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Notifs.dnd = !Notifs.dnd }
                    }
                }
            }
            Label {
                visible: Notifs.count === 0
                width: parent.width
                height: 60
                horizontalAlignment: Text.AlignHCenter
                text: "Нових сповіщень немає"
                muted: true
            }
            ListView {
                visible: Notifs.count > 0
                width: parent.width
                height: Math.min(contentHeight, 340)
                clip: true
                spacing: 6
                bottomMargin: 6
                model: Notifs.history
                boundsBehavior: Flickable.StopAtBounds
                delegate: NotificationCard {
                    required property var modelData
                    entry: modelData
                    width: ListView.view.width
                }
            }
        }

        // ---------- живлення й налаштування ----------
        Item {
            width: parent.width
            height: 40
            Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6
                Repeater {
                    model: Power.items
                    Rectangle {
                        required property var modelData
                        readonly property bool isArmed: root.armed === modelData.id
                        width: 36; height: 36; radius: 18
                        color: isArmed ? Theme.red : pwArea.containsMouse ? Qt.rgba(1, 1, 1, 0.22) : Theme.paneHover
                        border.width: 1
                        border.color: Theme.paneLine
                        Icon { anchors.centerIn: parent; name: modelData.icon }
                        MouseArea {
                            id: pwArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (modelData.confirm && !parent.isArmed) { root.armed = modelData.id; disarm.restart(); return }
                                Popups.close()
                                Power.run(modelData)
                            }
                        }
                    }
                }
                Label {
                    visible: root.armed !== ""
                    anchors.verticalCenter: parent.verticalCenter
                    leftPadding: 4
                    text: "Ще раз — підтвердити"
                    size: 12
                    muted: true
                }
            }
            Pill {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                height: 36
                width: setRow.implicitWidth + 28
                hovered: setArea.containsMouse
                opacity: 0.55               // налаштування з'являться на етапі 5
                Row {
                    id: setRow
                    anchors.centerIn: parent
                    spacing: 8
                    Icon { name: "settings"; anchors.verticalCenter: parent.verticalCenter }
                    Label { text: "Відкрити налаштування"; size: 13; weight: Font.Bold; anchors.verticalCenter: parent.verticalCenter }
                }
                MouseArea { id: setArea; anchors.fill: parent; hoverEnabled: true }
            }
        }
    }
    Timer { id: disarm; interval: 3000; onTriggered: root.armed = "" }
}
