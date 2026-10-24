pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "../../services"

// Налаштування: спецворкспейс special:settings, панель категорій зліва, програма праворуч.
// Клік по категорії показує її програму (запускає, якщо треба) і ховає попередню в special:unia-stash.
Singleton {
    id: root

    readonly property var tabs: [
        { id: "main", label: "Основні" },
        { id: "custom", label: "Кастомізація" },
        { id: "devices", label: "Девайси" },
    ]
    // kind "app" — готова програма (classes — класи її вікна; порожньо — перше нове вікно),
    // kind "own" — власна сторінка оболонки
    readonly property var items: [
        { id: "net", tab: "main", label: "Інтернет", icon: "wifi", kind: "app", tool: "Редактор мереж", cmd: ["nm-connection-editor"], classes: ["nm-connection-editor"] },
        { id: "bt", tab: "main", label: "Блютуз", icon: "bluetooth", kind: "app", tool: "Overskride", cmd: ["flatpak", "run", "io.github.kaii_lb.Overskride"], classes: ["io.github.kaii_lb.overskride"] },
        { id: "time", tab: "main", label: "Час і дата", icon: "schedule", kind: "own", what: "Часовий пояс, синхронізація часу, 24-годинний формат" },
        { id: "sound", tab: "main", label: "Звук", icon: "volume_up", kind: "app", tool: "pavucontrol", cmd: ["pavucontrol"], classes: ["pavucontrol", "org.pulseaudio.pavucontrol"] },
        { id: "display", tab: "main", label: "Дисплей", icon: "monitor", kind: "app", tool: "nwg-displays", cmd: ["nwg-displays"], classes: ["nwg-displays"] },
        { id: "layout", tab: "main", label: "Розкладка", icon: "keyboard", kind: "own", what: "Мови та клавіша перемикання розкладок" },
        { id: "wall", tab: "custom", label: "Шпалери", icon: "wallpaper", kind: "app", tool: "Waypaper", cmd: ["waypaper"], classes: ["waypaper"] },
        { id: "colors", tab: "custom", label: "Кольори", icon: "palette", kind: "app", tool: "nwg-look", cmd: ["nwg-look"], classes: ["nwg-look"] },
        { id: "theme", tab: "custom", label: "Тема", icon: "format_paint", kind: "own", what: "Головний і другорядні кольори, прозорість вікон, розмиття" },
        { id: "borders", tab: "custom", label: "Вікна й межі", icon: "border_style", kind: "own", what: "Відступи між вікнами, рамки, заокруглення" },
        { id: "mouse", tab: "devices", label: "Мишка", icon: "mouse", kind: "own", what: "Швидкість, прискорення, природне прокручування, режим для лівої руки" },
        { id: "kb-layout", tab: "devices", parent: "keyboard", label: "Мова та розкладка", icon: "keyboard", kind: "own", what: "Мови та клавіша перемикання розкладок" },
        { id: "kb-rgb", tab: "devices", parent: "keyboard", label: "Підсвітка", icon: "keyboard", kind: "app", tool: "OpenRGB", cmd: ["openrgb"], classes: ["openrgb", "org.openrgb.openrgb"] },
        { id: "printers", tab: "devices", label: "Принтери", icon: "print", kind: "app", tool: "system-config-printer", cmd: ["system-config-printer"], classes: ["system-config-printer"] },
        { id: "tablet", tab: "devices", label: "Графічний планшет", icon: "draw", kind: "app", tool: "OpenTabletDriver", cmd: ["otd-gui"], classes: ["opentabletdriver.ux"] },
    ]
    readonly property var groups: ({ keyboard: { label: "Клавіатура", icon: "keyboard" } })

    property string tab: "main"
    property string sel: "net"
    readonly property var current: find(sel)
    property bool shown: false                 // спецворкспейс settings зараз видно
    property string monitorName: ""           // на якому моніторі його показано
    property var addrs: ({})                   // id → адреса вікна програми
    property var pending: null                 // { id, classes, until } — чекаємо на нове вікно
    readonly property var pins: Prefs.data.pins ?? []      // закріплені в панелі керування (до 6)

    function find(id) { return items.find(i => i.id === id) ?? null }

    // ---------- відкриття / закриття ----------
    function toggle() {
        if (!shown && panelGone) { restorePanel(); return }
        Hyprland.dispatch("togglespecialworkspace settings")
    }
    function open(id) {
        if (id) select(id)
        if (!shown) toggle()
    }
    function close() { if (shown) toggle() }

    // панель закрили ззовні (Super+C) — не створюємо її одразу (нове вікно знову показало б налаштування),
    // а лише при наступному відкритті; поява вікна на спецворкспейсі сама його показує
    property bool panelGone: false
    signal panelRestoreRequested()
    function restorePanel() {
        panelGone = false
        panelRestoreRequested()
        ensureShown.restart()
    }
    Timer { id: ensureShown; interval: 400; onTriggered: if (!root.shown) Hyprland.dispatch("togglespecialworkspace settings") }

    // ---------- геометрія: панель 304 px зліва, програма — решта ----------
    readonly property int panelW: 304
    function area() {
        const m = Hyprland.monitors.values.find(m => m.name === monitorName) ?? Hyprland.focusedMonitor
        if (!m) return null
        const w = m.width / m.scale, h = m.height / m.scale
        const top = 72, side = 20, bottom = 20
        return { x: m.x + side, y: m.y + top, h: h - top - bottom,
                 toolX: m.x + side + panelW + 10, toolW: w - 2 * side - panelW - 10 }
    }
    // чи є вікно під селектором: для неіснуючого вікна Hyprland застосовує movetoworkspace/setfloating
    // до АКТИВНОГО вікна — так у налаштування затягувало браузер
    function exists(sel) {
        const ts = Hyprland.toplevels.values
        if (sel.startsWith("address:")) {
            const a = sel.slice(8).replace(/^0x/, "")
            return ts.some(t => t.address.replace(/^0x/, "") === a)
        }
        const re = new RegExp(sel.replace(/^title:/, ""))
        return ts.some(t => re.test(t.title))
    }
    function place(sel, x, y, w, h) {
        if (!exists(sel)) return
        Hyprland.dispatch(`movetoworkspacesilent special:settings,${sel}`)
        Hyprland.dispatch(`setfloating ${sel}`)
        Hyprland.dispatch(`resizewindowpixel exact ${Math.round(w)} ${Math.round(h)},${sel}`)
        Hyprland.dispatch(`movewindowpixel exact ${Math.round(x)} ${Math.round(y)},${sel}`)
    }
    // refocus — повернути клавіатуру панелі (при відкритті, виборі категорії); при простому перерозставленні
    // (Hyprland перечитав конфіг) — ні: focuswindow ще й переносить курсор у середину панелі
    function layout(refocus) {
        const a = area()
        if (!a) return
        place("title:^(Unia · Налаштування)$", a.x, a.y, panelW, a.h)
        const it = current
        if (!it) return
        if (it.kind === "own") place("title:^(Unia · Сторінка)$", a.toolX, a.y, a.toolW, a.h)
        else if (addrs[it.id]) place(`address:${addrs[it.id]}`, a.toolX, a.y, a.toolW, a.h)
        // фокус — лише коли налаштування відкриті: фокус на вікні схованого спецворкспейсу показує його
        // (так налаштування вискакували при кожному запуску оболонки, коли з'являлось вікно панелі)
        if (!shown || refocus === false) return
        focusPanel()        // клавіатура лишається в панелі: Tab — перейти до програми
        refocus.restart()   // щойно відкрите вікно програми забирає фокус собі — повертаємо його панелі
    }
    Timer { id: refocus; interval: 350; onTriggered: if (root.shown) root.focusPanel() }

    // ---------- фокус клавіатури: панель ↔ програма праворуч ----------
    signal pageFocusRequested()        // власній сторінці — поставити фокус на перший елемент
    function focusPanel() { Hyprland.dispatch("focuswindow title:^(Unia · Налаштування)$") }
    function focusTool() {
        const it = current
        if (!it) return
        if (it.kind === "own") { Hyprland.dispatch("focuswindow title:^(Unia · Сторінка)$"); pageFocusRequested() }
        else if (addrs[it.id]) Hyprland.dispatch(`focuswindow address:${addrs[it.id]}`)
    }

    // ---------- вибір категорії ----------
    function select(id) {
        const it = find(id)
        if (!it) return
        const prev = current
        if (prev && prev.id !== id && prev.kind === "app" && addrs[prev.id] && exists(`address:${addrs[prev.id]}`))
            Hyprland.dispatch(`movetoworkspacesilent special:unia-stash,address:${addrs[prev.id]}`)
        sel = id
        tab = it.tab
        if (it.kind === "app" && !addrs[id]) adoptOrLaunch(it)
        layout()
    }

    function adoptOrLaunch(it) {
        // уже відкрита деінде? забираємо її вікно
        const c = clients.find(c => it.classes.includes(c.class.toLowerCase()))
        if (c) { setAddr(it.id, c.address.replace(/^0x/, "")); return }
        pending = { id: it.id, classes: it.classes, until: Date.now() + 30000 }
        Quickshell.execDetached(it.cmd)
    }
    function setAddr(id, a) {
        const m = Object.assign({}, addrs)
        m[id] = "0x" + a
        addrs = m
    }

    // ---------- закріплення в панелі керування ----------
    function togglePin(id) {
        Prefs.set("pins", pins.includes(id) ? pins.filter(x => x !== id) : [...pins, id].slice(0, 6))
    }

    // ---------- стан Hyprland ----------
    property var clients: []                   // [{ address, class }] — оновлюємо через hyprctl
    Process {
        id: clientsProc
        command: ["hyprctl", "clients", "-j"]
        stdout: StdioCollector { onStreamFinished: { try { root.clients = JSON.parse(text) } catch (e) {} } }
    }
    Component.onCompleted: clientsProc.running = true

    Connections {
        target: Hyprland
        function onRawEvent(ev) {
            // Hyprland перечитав конфіг (напр. Apply у nwg-displays) або змінились монітори —
            // правила вікон могли пересунути програму під панель, тож розставляємо заново
            if (["configreloaded", "monitoradded", "monitorremoved"].includes(ev.name)) {
                if (root.shown) relayout.restart()
            } else if (ev.name === "activespecial") {
                const [ws, mon] = ev.data.split(",")
                root.shown = ws === "special:settings"
                if (root.shown) { root.monitorName = mon; root.layout() }
            } else if (ev.name === "openwindow") {
                const [addr, ws, cls, ...t] = ev.data.split(",")
                clientsProc.running = true
                // власні вікна (панель, сторінка) з'являються вже після select() — розставляємо ще раз
                if (t.join(",").startsWith("Unia · ")) { root.layout(); return }
                const p = root.pending
                // своє вікно впізнаємо за класом; запасний варіант — перше нове вікно на спецворкспейсі
                if (p && Date.now() < p.until && (p.classes.includes(cls.toLowerCase()) || ws === "special:settings" && !cls.startsWith("org.quickshell"))) {
                    root.pending = null
                    root.setAddr(p.id, addr)
                    if (root.sel === p.id) root.layout()
                    else Hyprland.dispatch(`movetoworkspacesilent special:unia-stash,address:0x${addr}`)
                }
            } else if (ev.name === "closewindow") {
                const a = "0x" + ev.data
                const m = Object.assign({}, root.addrs)
                for (const k in m) if (m[k] === a) delete m[k]
                root.addrs = m
                clientsProc.running = true
            }
        }
    }

    Timer { id: relayout; interval: 400; onTriggered: root.layout(false) }

}
