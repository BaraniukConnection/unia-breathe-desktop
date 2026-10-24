import QtQuick
import QtQuick.Controls
import Quickshell
import "../../theme"
import "../../services"

// Меню програм над доком: пошук, папки з плитками (перетягування, розміри, обрані), «Усі програми».
Glass {
    id: root
    required property var screen
    readonly property int colW: Menu.cols * 48 + (Menu.cols - 1) * 8          // 440
    readonly property int ncols: maxWidth >= 2 * colW + 120 ? 2 : 1
    property real maxWidth: 1200
    property real maxHeight: 580
    property string view: "tiles"           // "tiles" | "apps"
    property bool resetArmed: false
    readonly property string query: search.text.trim()

    width: ncols * colW + (ncols - 1) * 32 + 72
    height: Math.min(580, maxHeight)
    radius: 28

    function launch(app) {
        Popups.close()
        Apps.launch(app)
    }

    // ---------- перетягування плиток ----------
    property string dragTile: ""
    property var dragData: null
    property point grab
    property var dropSlot: null             // { group, x, y, size } або { newFolder: column }
    property var folders: []                // зареєстровані сітки папок

    function beginDrag(tile, grabPoint, p) {
        dragData = tile
        grab = grabPoint
        dragTile = tile.id
        moveDrag(p)
    }
    function targetAt(p) {
        const tl = Qt.point(p.x - grab.x, p.y - grab.y)
        for (const g of folders) {
            if (!g || !g.visible) continue
            const q = g.mapFromItem(root, tl.x, tl.y)
            const c = g.mapFromItem(root, p.x, p.y)
            // трохи нижче останнього рядка теж рахується — так плитку можна покласти в кінець папки
            if (c.x < -16 || c.x > g.width + 16 || c.y < -24 || c.y > g.height + 52) continue
            const d = Menu.sizes[dragData.size], step = dragData.size === "small" ? 1 : 2
            let x = Math.round(q.x / 56), y = Math.round(q.y / 56)
            if (step === 2) { x -= x % 2; y -= y % 2 }
            x = Math.max(0, Math.min(Menu.cols - d[0], x)); y = Math.max(0, y)
            return { group: g.groupId, x: x, y: y, size: dragData.size }
        }
        for (let i = 0; i < newZones.count; i++) {
            const z = newZones.itemAt(i)
            const c = z.mapFromItem(root, p.x, p.y)
            if (c.x >= 0 && c.x <= z.width && c.y >= 0 && c.y <= z.height) {
                const col = root.ncols === 2 ? i : Menu.data.columns.length - 1
                return { zone: i, newFolder: col, index: Menu.data.columns[col].length }
            }
        }
        return null
    }
    function moveDrag(p) {
        ghost.x = p.x - grab.x
        ghost.y = p.y - grab.y
        dropSlot = targetAt(p)
        edgeScroll(p)
    }
    function endDrag(p) {
        const t = targetAt(p)
        if (t && t.newFolder !== undefined) Menu.newFolder(dragTile, t.newFolder, t.index)
        else if (t) Menu.moveTile(dragTile, t.group, t.x, t.y)
        cancelDrag()
    }
    function cancelDrag() { dragTile = ""; dragData = null; dropSlot = null; scrollSpeed = 0 }

    // ---------- автопрокрутка під час перетягування ----------
    // курсор біля верхнього/нижнього краю списку — прокручуємо в той бік (ближче до краю — швидше)
    readonly property int edgeZone: 64
    property real scrollSpeed: 0
    property point lastDrag
    function edgeScroll(p) {
        lastDrag = p
        const y = tilesView.mapFromItem(root, p.x, p.y).y
        if (y < edgeZone) scrollSpeed = -Math.min(1, (edgeZone - y) / edgeZone) * 18
        else if (y > tilesView.height - edgeZone) scrollSpeed = Math.min(1, (y - tilesView.height + edgeZone) / edgeZone) * 18
        else scrollSpeed = 0
    }
    Timer {
        interval: 16
        repeat: true
        running: root.scrollSpeed !== 0 && (root.dragTile !== "" || root.dragFolder !== "")
        onTriggered: {
            const max = Math.max(0, tilesView.contentHeight - tilesView.height)
            const y = Math.max(0, Math.min(max, tilesView.contentY + root.scrollSpeed))
            if (y === tilesView.contentY) return
            tilesView.contentY = y
            // під нерухомим курсором тепер інше місце — оновлюємо ціль
            if (root.dragTile !== "") root.dropSlot = root.targetAt(root.lastDrag)
            else root.folderDrop = root.folderTarget(root.lastDrag)
        }
    }

    // ---------- перетягування папок ----------
    property string dragFolder: ""
    property string dragFolderName: ""
    property var folderDrop: null           // { col, index, x, y } — куди стане папка і де намалювати лінію

    function beginFolderDrag(g, p) { dragFolder = g.id; dragFolderName = g.name; moveFolderDrag(p) }
    function moveFolderDrag(p) {
        folderGhost.x = p.x - 20
        folderGhost.y = p.y - 18
        folderDrop = folderTarget(p)
        edgeScroll(p)
    }
    function endFolderDrag(p) {
        const t = folderTarget(p)
        if (t) Menu.placeFolder(dragFolder, t.col, t.index)
        cancelFolderDrag()
    }
    function cancelFolderDrag() { dragFolder = ""; folderDrop = null; scrollSpeed = 0 }
    function folderTarget(p) {
        // колонка — за x; на вузькому екрані одна видима колонка, яка насправді — дві підряд
        const c0 = cols.mapToItem(root, 0, 0)
        const vcol = ncols === 2 && p.x > c0.x + colW + 16 ? 1 : 0
        const visible = folderItems().filter(f => f.group.id !== dragFolder)
            .map(f => ({ f: f, top: f.mapToItem(root, 0, 0).y, x: f.mapToItem(root, 0, 0).x }))
            .filter(o => ncols === 1 || (o.x > c0.x + colW + 16 ? 1 : 0) === vcol)
            .sort((a, b) => a.top - b.top)
        let i = visible.findIndex(o => p.y < o.top + o.f.height / 2)
        if (i < 0) i = visible.length
        const lineY = i < visible.length ? visible[i].top - 10 : visible.length ? visible[visible.length - 1].top + visible[visible.length - 1].f.height + 10 : p.y
        const lineX = c0.x + vcol * (colW + 32)
        if (ncols === 2) {
            const others = Menu.data.columns[vcol].filter(g => g.id !== dragFolder)
            // індекс серед папок саме цієї колонки (видимих — усі папки колонки, у тому ж порядку)
            return { col: vcol, index: i, x: lineX, y: lineY, n: others.length }
        }
        // одна видима колонка: позиція в загальному списку → (колонка, позиція)
        const c0len = Menu.data.columns[0].filter(g => g.id !== dragFolder).length
        return i <= c0len ? { col: 0, index: i, x: lineX, y: lineY } : { col: 1, index: i - c0len, x: lineX, y: lineY }
    }

    // ---------- контекстне меню ----------
    property var menuItems: []
    function tileMenu(tile, p) {
        const sizes = [["small", "Малий"], ["medium", "Середній"], ["wide", "Широкий"], ["large", "Великий"]]
        const e = Apps.byId(tile.app)
        const items = sizes.map(([s, l]) => ({ label: l, icon: tile.size === s ? "radio_button_checked" : "radio_button_unchecked",
                                               run: () => Menu.resize(tile.id, s) }))
        if (Apps.liveKind(e) && tile.size !== "small")
            items.push({ label: tile.live === false ? "Показувати вміст" : "Лише іконка", icon: "auto_awesome", run: () => Menu.toggleLive(tile.id) })
        items.push(favItem(tile.app))
        const misc = Menu.all().find(g => g.misc)
        if (misc && !misc.tiles.some(t => t.id === tile.id))
            items.push({ label: "Прибрати в «Інше»", icon: "move_down", run: () => Menu.toMisc(tile.id) })
        openMenu(items, p)
    }
    function folderMenu(g, p) {
        const items = [{ label: "Перейменувати", icon: "edit", run: () => { const f = folderItems().find(f => f.group.id === g.id); if (f) f.startEdit() } },
                       { label: "Вище", icon: "arrow_upward", run: () => Menu.moveFolder(g.id, -1) },
                       { label: "Нижче", icon: "arrow_downward", run: () => Menu.moveFolder(g.id, 1) }]
        if (root.ncols === 2) items.push({ label: "В іншу колонку", icon: "swap_horiz", run: () => Menu.moveFolder(g.id, "other") })
        if (!g.misc) items.push({ label: g.tiles.length ? "Видалити (плитки — в «Інше»)" : "Видалити папку", icon: "delete", run: () => Menu.deleteFolder(g.id) })
        openMenu(items, p)
    }
    function folderItems() { return folders.map(g => g ? g.parent : null).filter(f => f && f.group) }
    function newFolder() {
        view = "tiles"
        search.text = ""
        const id = Menu.addFolder()
        // папка з'явиться після перемальовування — тоді й відкриваємо поле назви
        Qt.callLater(() => {
            const f = folderItems().find(f => f.group.id === id)
            if (!f) return
            const y = f.mapToItem(cols, 0, 0).y
            tilesView.contentY = Math.max(0, Math.min(tilesView.contentHeight - tilesView.height, y - 40))
            f.startEdit()
        })
    }
    function favItem(app) {
        const on = Menu.data.favs.includes(app)
        return { label: on ? "Прибрати з доку" : "Додати до доку", icon: "star", run: () => { if (!Menu.toggleFav(app)) toast.show("У доці вже п'ять програм — спершу прибери одну") } }
    }
    function openMenu(items, p) {
        menuItems = items
        ctx.x = Math.min(p.x, root.width - ctx.width - 8)
        ctx.y = Math.min(p.y, root.height - ctx.implicitHeight - 8)
        ctx.visible = true
    }

    Component.onCompleted: search.forceActiveFocus()

    // ---------- пошук ----------
    TextField {
        id: search
        x: 24; y: 18
        width: parent.width - 48
        height: 44
        placeholderText: "Пошук програм…"
        font.family: Theme.font
        font.pixelSize: 15
        color: Theme.ink
        placeholderTextColor: Theme.inkMuted
        leftPadding: 46
        background: Rectangle {
            radius: 22
            color: Theme.paneHover
            border.width: 1
            border.color: search.activeFocus ? Theme.accent : Theme.paneLine
            Icon { x: 16; anchors.verticalCenter: parent.verticalCenter; name: "search"; color: Theme.inkMuted }
        }
        onAccepted: if (results.count > 0) root.launch(results.model[Math.max(0, results.currentIndex)].id)
        Keys.onEscapePressed: { if (text) text = ""; else Popups.close() }
        Keys.onDownPressed: results.incrementCurrentIndex()
        Keys.onUpPressed: results.decrementCurrentIndex()
        onTextChanged: results.currentIndex = 0
    }

    Item {
        id: body
        x: 24
        y: 76
        width: parent.width - 48
        height: parent.height - y - 60

        // плитки
        Flickable {
            id: tilesView
            anchors.fill: parent
            visible: root.query === "" && root.view === "tiles"
            contentHeight: cols.implicitHeight + 16
            clip: true
            interactive: root.dragTile === "" && root.dragFolder === ""
            boundsBehavior: Flickable.StopAtBounds
            Row {
                id: cols
                x: 12
                spacing: 32
                Repeater {
                    // на вузькому екрані друга колонка стає під першою
                    model: root.ncols === 2 ? Menu.data.columns : [Menu.all()]
                    Column {
                        id: column
                        required property var modelData
                        required property int index
                        spacing: 20
                        width: root.colW
                        Repeater {
                            model: column.modelData
                            Folder {
                                required property var modelData
                                group: modelData
                                panel: root
                                Component.onCompleted: root.folders = [...root.folders.filter(g => g && g.groupId !== modelData.id), grid]
                            }
                        }
                    }
                }
            }
            // зони «нова папка» під кожною колонкою (видно лише під час перетягування)
            Repeater {
                id: newZones
                model: root.ncols
                Rectangle {
                    required property int index
                    visible: root.dragTile !== ""
                    x: 12 + index * (root.colW + 32)
                    y: cols.implicitHeight - 4
                    width: root.colW
                    height: 52
                    radius: 16
                    color: root.dropSlot && root.dropSlot.zone === index ? Qt.rgba(0.06, 0.73, 0.51, 0.18) : "transparent"
                    border.width: 2
                    border.color: Theme.accent
                    opacity: 0.8
                    Label { anchors.centerIn: parent; text: "+ Нова папка"; weight: Font.Bold; color: Theme.accent; shadow: false }
                }
            }
        }

        // усі програми (за абеткою)
        ListView {
            id: allApps
            anchors.fill: parent
            visible: root.query === "" && root.view === "apps"
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            model: Apps.list
            delegate: Column {
                required property var modelData
                required property int index
                readonly property string letter: modelData.name.charAt(0).toUpperCase()
                width: ListView.view.width
                Label {   // літера над першою програмою на неї
                    visible: index === 0 || Apps.list[index - 1].name.charAt(0).toUpperCase() !== parent.letter
                    text: parent.letter
                    size: 12; weight: Font.Bold; color: Theme.accent
                    topPadding: 10; bottomPadding: 4; leftPadding: 12
                }
                AppRow { entry: modelData; width: parent.width }
            }
        }

        // результати пошуку
        ListView {
            id: results
            anchors.fill: parent
            visible: root.query !== ""
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            model: Apps.search(root.query)
            currentIndex: 0
            delegate: AppRow { required property var modelData; required property int index; entry: modelData; width: ListView.view.width; current: index === results.currentIndex }
            Label { visible: results.count === 0; anchors.centerIn: parent; text: "Нічого не знайдено"; muted: true }
        }
    }

    component AppRow: Rectangle {
        id: ar
        property var entry
        property bool current: false
        height: 48
        radius: 14
        color: current ? Theme.accent : arArea.containsMouse ? Theme.paneHover : "transparent"
        AppIcon { x: 12; anchors.verticalCenter: parent.verticalCenter; app: ar.entry.id; implicitSize: 32 }
        Column {
            x: 56
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 70
            Label { width: parent.width; text: ar.entry.name; weight: Font.Bold; elide: Text.ElideRight; color: ar.current ? Theme.accentInk : Theme.ink; shadow: !ar.current }
            Label { width: parent.width; visible: text !== ""; text: ar.entry.genericName ?? ""; size: 12; elide: Text.ElideRight; color: ar.current ? Theme.accentInk : Theme.inkMuted; shadow: !ar.current }
        }
        Icon { visible: Menu.data.favs.includes(ar.entry.id); anchors.right: parent.right; anchors.rightMargin: 14; anchors.verticalCenter: parent.verticalCenter; name: "star"; filled: true; font.pixelSize: 16; color: ar.current ? Theme.accentInk : Theme.accent }
        MouseArea {
            id: arArea
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: Qt.PointingHandCursor
            onClicked: m => {
                if (m.button === Qt.RightButton) root.openMenu([root.favItem(ar.entry.id)], mapToItem(root, m.x, m.y))
                else root.launch(ar.entry.id)
            }
        }
    }

    // ---------- низ: скинути розкладку, Плитки / Усі програми ----------
    Item {
        x: 24
        width: parent.width - 48
        height: 40
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 12
        Pill {
            id: newBtn
            anchors.verticalCenter: parent.verticalCenter
            width: newRow.implicitWidth + 24
            height: 36
            color: newArea.containsMouse ? Theme.paneHover : "transparent"
            border.width: 0
            visible: root.view === "tiles" && root.query === ""
            Row {
                id: newRow
                anchors.centerIn: parent
                spacing: 6
                Icon { name: "create_new_folder"; color: Theme.inkMuted; font.pixelSize: 18; anchors.verticalCenter: parent.verticalCenter }
                Label { text: "Нова папка"; size: 13; anchors.verticalCenter: parent.verticalCenter }
            }
            MouseArea { id: newArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.newFolder() }
        }
        Pill {
            anchors.left: newBtn.right
            anchors.leftMargin: 4
            anchors.verticalCenter: parent.verticalCenter
            width: resetRow.implicitWidth + 24
            height: 36
            color: resetArea.containsMouse ? Theme.paneHover : "transparent"
            border.width: 0
            visible: root.view === "tiles" && root.query === ""
            Row {
                id: resetRow
                anchors.centerIn: parent
                spacing: 6
                Icon { name: "restart_alt"; color: Theme.inkMuted; font.pixelSize: 18; anchors.verticalCenter: parent.verticalCenter }
                Label { text: root.resetArmed ? "Точно скинути?" : "Скинути розкладку"; size: 13; anchors.verticalCenter: parent.verticalCenter }
            }
            Timer { id: unarm; interval: 3000; onTriggered: root.resetArmed = false }
            MouseArea {
                id: resetArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: { if (root.resetArmed) { Menu.reset(); root.resetArmed = false } else { root.resetArmed = true; unarm.restart() } }
            }
        }
        Rectangle {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: seg.implicitWidth + 8
            height: 36
            radius: 18
            color: Theme.paneHover
            border.width: 1
            border.color: Theme.paneLine
            Row {
                id: seg
                x: 4; y: 4
                Repeater {
                    model: [{ v: "tiles", l: "Плитки" }, { v: "apps", l: "Усі програми" }]
                    Rectangle {
                        required property var modelData
                        readonly property bool on: root.view === modelData.v
                        width: segLabel.implicitWidth + 28
                        height: 28
                        radius: 14
                        color: on ? Theme.accent : "transparent"
                        Label { id: segLabel; anchors.centerIn: parent; text: modelData.l; size: 13; weight: Font.Bold; color: parent.on ? Theme.accentInk : Theme.ink; shadow: !parent.on }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { root.view = modelData.v; search.text = "" } }
                    }
                }
            }
        }
    }

    // лінія, куди стане папка, і «привид» з її назвою
    Rectangle {
        visible: root.dragFolder !== "" && !!root.folderDrop
        z: 49
        x: root.folderDrop ? root.folderDrop.x : 0
        y: root.folderDrop ? root.folderDrop.y - 2 : 0
        width: root.colW
        height: 4
        radius: 2
        color: Theme.accent
    }
    Glass {
        id: folderGhost
        visible: root.dragFolder !== ""
        z: 50
        color: Theme.tint(Qt.rgba(8 / 255, 30 / 255, 25 / 255, 0.94))
        border.color: Theme.accent
        radius: 18
        width: fgRow.implicitWidth + 28
        height: 36
        Row {
            id: fgRow
            anchors.centerIn: parent
            spacing: 8
            Icon { name: "folder"; color: Theme.accent; font.pixelSize: 18; anchors.verticalCenter: parent.verticalCenter }
            Label { text: root.dragFolderName; weight: Font.Bold; anchors.verticalCenter: parent.verticalCenter }
        }
    }

    // привид плитки під курсором під час перетягування
    Rectangle {
        id: ghost
        visible: root.dragTile !== ""
        z: 50
        readonly property var d: root.dragData ? Menu.sizes[root.dragData.size] : [1, 1]
        width: d[0] * 56 - 8
        height: d[1] * 56 - 8
        radius: Theme.radiusTile
        color: Theme.paneHover
        border.width: 1
        border.color: Theme.accent
        opacity: 0.9
        AppIcon { anchors.centerIn: parent; app: root.dragData ? root.dragData.app : ""; implicitSize: 36 }
    }

    // контекстне меню
    MouseArea {
        anchors.fill: parent
        visible: ctx.visible
        z: 59
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: ctx.visible = false
    }
    Glass {
        id: ctx
        visible: false
        z: 60
        color: Theme.tint(Qt.rgba(8 / 255, 30 / 255, 25 / 255, 0.94))    // під меню — плитки тієї ж панелі, розмиття тут не допоможе
        radius: 16
        width: 232
        implicitHeight: ctxCol.implicitHeight + 12
        height: implicitHeight
        Column {
            id: ctxCol
            x: 6; y: 6
            width: parent.width - 12
            Repeater {
                model: root.menuItems
                Rectangle {
                    required property var modelData
                    width: ctxCol.width
                    height: 40
                    radius: 10
                    color: ia.containsMouse ? Theme.paneHover : "transparent"
                    Row {
                        x: 10
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 12
                        Icon { name: modelData.icon; color: Theme.inkMuted; font.pixelSize: 20; anchors.verticalCenter: parent.verticalCenter }
                        Label { text: modelData.label; weight: Font.Medium; anchors.verticalCenter: parent.verticalCenter }
                    }
                    MouseArea { id: ia; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { ctx.visible = false; modelData.run() } }
                }
            }
        }
    }

    // коротке повідомлення внизу панелі
    Glass {
        id: toast
        z: 70
        strong: true
        radius: 18
        visible: opacity > 0
        opacity: 0
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height - 110
        width: toastLabel.implicitWidth + 32
        height: 36
        function show(t) { toastLabel.text = t; opacity = 1; toastTimer.restart() }
        Behavior on opacity { NumberAnimation { duration: 160 } }
        Label { id: toastLabel; anchors.centerIn: parent; size: 13 }
        Timer { id: toastTimer; interval: 2600; onTriggered: toast.opacity = 0 }
    }
}
