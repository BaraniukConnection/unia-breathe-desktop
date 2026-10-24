pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "../../services"

// WindowDrop: виїмка-«крапля» посередині верхньої рамки вікна (як виріз під фронтальну камеру).
// Наближення курсора — виїмка росте з рамки; затиснути й тягнути (або Super+ЛКМ будь-де у вікні) —
// вікно стискається в квадрат і їде за курсором, а там, куди воно стане, вже розсувається місце (DropPlace);
// клік — меню вікна.
// Тут стан і дії; малює кожен монітор свій шар (WindowDrop.qml).
Singleton {
    id: root
    readonly property string dragWs: Windows.dragWs      // де вікно чекає, поки його тягнуть
    // службові столи, на вікнах яких виїмки немає
    readonly property var skipWs: ["special:settings", "special:unia-stash", Windows.minimizedWs, Windows.dragWs]

    property var clients: []
    property var monitors: []
    property int border: 1                    // general:border_size

    property string hovered: ""               // адреса вікна, на рамці якого курсор
    property string menuFor: ""               // адреса вікна з відкритим меню
    property var drag: null                   // { address, floating, wsId, rect, mon, offX, offY, grab } — поки тягнемо
    property real dragX: 0                    // курсор під час перетягування (глобальні координати)
    property real dragY: 0
    property var resizing: null               // { address, floating, quad, rect, sent } — режим зміни розміру
    readonly property bool busy: menuFor !== "" || drag !== null || resizing !== null
    readonly property string current: drag ? drag.address : menuFor || hovered   // вікно з виїмкою

    function client(a) { return clients.find(c => c.address === a) ?? null }
    // товщина рамки вікна: у повноекранного (не просто розгорнутого) рамки немає — виїмка росте з краю екрана
    function bandOf(c) { return c && c.fullscreen >= 2 ? 0 : border }
    function monitorAt(x, y) {
        return monitors.find(m => x >= m.x && x < m.x + m.width / m.scale && y >= m.y && y < m.y + m.height / m.scale) ?? null
    }

    // вікна, які видно на моніторі, знизу вгору: спершу розкладені, потім плаваючі; давніший фокус — нижче.
    // Є повноекранне вікно — видно лише його (решта під ним).
    function visibleOn(m) {
        if (!m) return []
        const ws = m.specialWorkspace.name || m.activeWorkspace.name
        if (skipWs.includes(ws)) return []
        const list = clients.filter(c => c.mapped && !c.hidden && c.workspace.name === ws && c.class !== "org.quickshell")
        const full = list.filter(c => c.fullscreen).sort((a, b) => a.focusHistoryID - b.focusHistoryID)
        if (full.length) return [full[0]]
        return list.sort((a, b) => (a.floating - b.floating) || (b.focusHistoryID - a.focusHistoryID))
    }
    // верхнє вікно під точкою (крім указаного)
    function windowAt(m, x, y, except) {
        const ws = visibleOn(m).filter(c => c.address !== except)
        for (let i = ws.length - 1; i >= 0; i--) {
            const c = ws[i]
            if (x >= c.at[0] && x < c.at[0] + c.size[0] && y >= c.at[1] && y < c.at[1] + c.size[1]) return c
        }
        return null
    }

    // ---------- стан Hyprland: вікна, монітори, товщина рамки ----------
    // подій про зміну розмірів Hyprland не шле, тож, крім подій, перечитуємо раз на 0,7 с
    Process {
        id: poll
        command: ["hyprctl", "--batch", "j/clients;j/monitors;j/getoption general:border_size;" +
                  "j/getoption dwindle:use_active_for_splits;j/getoption dwindle:smart_split;j/getoption cursor:no_warps"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const [c, m, b, ua, ss, nw] = text.split(/\n\n\n/).map(s => JSON.parse(s))
                    root.clients = c
                    root.monitors = m
                    root.border = b.int ?? 1
                    // поки тягнемо, ці опції підмінені — пам'ятаємо лише справжні
                    if (!root.drag && !restore.running) root.opts = { ua: ua.int, ss: ss.int, nw: nw.int }
                } catch (e) {}
                if (root.menuFor && !root.client(root.menuFor)) root.closeMenu()
                // вікно закрили чи воно пішло з видимого столу — режим зміни розміру більше нема до чого застосовувати
                if (root.resizing && !root.visibleOn(root.monitors.find(m => m.id === (root.client(root.resizing.address) ?? {}).monitor))
                        .some(c => c.address === root.resizing.address)) root.stopResize()
            }
        }
    }
    function refresh() { if (!poll.running) poll.running = true }
    Timer { interval: root.drag || root.resizing ? 120 : 700; running: true; repeat: true; onTriggered: root.refresh() }
    Timer { id: soon; interval: 60; onTriggered: root.refresh() }
    Connections {
        target: Hyprland
        function onRawEvent(ev) {
            if (ev.name === "openwindow") {
                const [addr, , , ...t] = ev.data.split(",")
                if (t.join(",") === root.placeTitle) { root.placeAddr = "0x" + addr; if (root.drag) root.relocate() }
            }
            if (["openwindow", "closewindow", "movewindowv2", "changefloatingmode", "fullscreen", "workspacev2",
                 "activespecial", "focusedmonv2", "activewindowv2", "monitoraddedv2", "monitorremoved", "configreloaded"].includes(ev.name))
                soon.restart()
        }
    }
    Component.onCompleted: refresh()

    // ---------- наведення ----------
    // з нульовою (чи 1 px) рамкою виїмці нема з чого рости — поки вона є, рамка вікна 3 px
    property string thick: ""
    onCurrentChanged: {
        if (thick && thick !== current) { Hyprland.dispatch(`setprop address:${thick} border_size unset`); thick = "" }
        if (current && border < 2 && client(current) && !client(current).fullscreen) { Hyprland.dispatch(`setprop address:${current} border_size 3`); thick = current }
    }

    // ---------- меню ----------
    function openMenu(a) { hovered = a; menuFor = a }
    function closeMenu() { menuFor = ""; hovered = "" }    // курсор ще на гачку — наступний рух поверне виїмку
    function act(what) {
        const c = client(menuFor)
        closeMenu()
        if (!c) return
        const a = c.address
        if (what === "minimize")
            Windows.minimize({ address: a, wsId: c.workspace.id, wsName: c.workspace.name })
        else if (what === "fullscreen") {
            Hyprland.dispatch(`focuswindow address:${a}`)
            Hyprland.dispatch("fullscreen 0")
        } else if (what === "float")
            Hyprland.dispatch(`togglefloating address:${a}`)
        else if (what === "close")
            Hyprland.dispatch(`closewindow address:${a}`)
        soon.restart()
    }
    // режим фокусу — для всієї оболонки (Theme.focusMode), зберігається в налаштуваннях
    function toggleFocus() { Prefs.set("focusMode", !(Prefs.data.focusMode ?? false)) }
    function moveTo(wsId) {
        const c = client(menuFor)
        closeMenu()
        if (c) Hyprland.dispatch(`movetoworkspacesilent ${wsId},address:${c.address}`)
        soon.restart()
    }

    // ---------- зміна розміру (як Super+ПКМ) ----------
    // Вікно ділить пунктирний хрест на чверті: тягнеш у чверті — рухаються дві сторони, що до неї прилягають
    // (у правій верхній — права й верхня), і саме в той бік, куди тягнеш.
    // Плаваюче вікно змінюємо точно. У розкладеного межа спільна із сусідом, а Hyprland на «стань ширшим»
    // завжди зсуває праву (нижню) межу. Тож ліву чи верхню межу рухаємо розміром сусіда з того боку, праву чи
    // нижню — розміром самого вікна; там, де замість сусіда край екрана, межа стоїть.
    function startResize(a) {
        const c = client(a)
        closeMenu()
        if (!c) return
        resizing = { address: a, floating: c.floating, quad: "", rect: null }
    }
    function stopResize() { resizing = null }
    // розкладене вікно, що прилягає до сторони side ("l", "r", "t", "b") вікна c; якщо таких кілька —
    // те, що навпроти точки натиску (px, py)
    function neighbour(c, side, px, py) {
        const L = c.at[0], T = c.at[1], R = L + c.size[0], B = T + c.size[1], tol = 40
        const across = (a0, a1, b0, b1) => Math.min(a1, b1) - Math.max(a0, b0) > 0
        const near = clients.filter(o => o.address !== c.address && !o.floating && o.mapped && !o.hidden
                                         && o.workspace.id === c.workspace.id).filter(o => {
            const oL = o.at[0], oT = o.at[1], oR = oL + o.size[0], oB = oT + o.size[1]
            if (side === "l") return oR <= L + 2 && L - oR <= tol && across(T, B, oT, oB)
            if (side === "r") return oL >= R - 2 && oL - R <= tol && across(T, B, oT, oB)
            if (side === "t") return oB <= T + 2 && T - oB <= tol && across(L, R, oL, oR)
            return oT >= B - 2 && oT - B <= tol && across(L, R, oL, oR)
        })
        const facing = near.find(o => side === "l" || side === "r" ? py >= o.at[1] && py < o.at[1] + o.size[1]
                                                                     : px >= o.at[0] && px < o.at[0] + o.size[0])
        return facing ?? near[0] ?? null
    }
    // натиснули в чверті quad ("lt", "rt", "lb", "rb") у точці (px, py) — запам'ятати, від чого рахувати
    function beginResize(quad, px, py) {
        const c = resizing ? client(resizing.address) : null
        if (!c) return
        const nx = c.floating ? null : neighbour(c, quad[0], px, py)
        const ny = c.floating ? null : neighbour(c, quad[1], px, py)
        resizing = Object.assign({}, resizing, {
            quad: quad, rect: { x: c.at[0], y: c.at[1], w: c.size[0], h: c.size[1] },
            nx: nx ? { address: nx.address, w: nx.size[0] } : null,
            ny: ny ? { address: ny.address, h: ny.size[1] } : null,
            sent: { x: 0, y: 0 } })
    }
    // курсор зсунувся на (dx, dy) від натиску
    function moveResize(dx, dy) {
        const r = resizing
        if (!r || !r.rect) return
        const left = r.quad[0] === "l", top = r.quad[1] === "t"
        const clamp = (v, lo, hi) => Math.max(lo, Math.min(hi, v))
        if (r.floating) {
            const w = Math.max(160, r.rect.w + (left ? -dx : dx)), h = Math.max(120, r.rect.h + (top ? -dy : dy))
            const x = left ? r.rect.x + r.rect.w - w : r.rect.x, y = top ? r.rect.y + r.rect.h - h : r.rect.y
            Hyprland.dispatch(`resizewindowpixel exact ${Math.round(w)} ${Math.round(h)},address:${r.address}`)
            Hyprland.dispatch(`movewindowpixel exact ${Math.round(x)} ${Math.round(y)},address:${r.address}`)
            soon.restart()
            return
        }
        // наскільки зсувається межа (у бік dx, dy), не стискаючи жодне з двох вікон нижче 160×120
        const ex = !r.nx ? 0 : Math.round(left ? clamp(dx, 160 - r.nx.w, r.rect.w - 160) : clamp(dx, 160 - r.rect.w, r.nx.w - 160))
        const ey = !r.ny ? 0 : Math.round(top ? clamp(dy, 120 - r.ny.h, r.rect.h - 120) : clamp(dy, 120 - r.rect.h, r.ny.h - 120))
        const sx = ex - r.sent.x, sy = ey - r.sent.y
        if (!sx && !sy) return
        r.sent = { x: ex, y: ey }
        // ліва/верхня межа — правий/нижній край сусіда; права/нижня — край самого вікна
        const tx = left ? (r.nx ? r.nx.address : null) : r.address
        const ty = top ? (r.ny ? r.ny.address : null) : r.address
        if (sx && sy && tx === ty) Hyprland.dispatch(`resizewindowpixel ${sx} ${sy},address:${tx}`)
        else {
            if (sx && tx) Hyprland.dispatch(`resizewindowpixel ${sx} 0,address:${tx}`)
            if (sy && ty) Hyprland.dispatch(`resizewindowpixel 0 ${sy},address:${ty}`)
        }
        soon.restart()
    }
    function endResize() { if (resizing) resizing = Object.assign({}, resizing, { quad: "", rect: null, nx: null, ny: null }) }

    // ---------- перетягування ----------
    // Вікно, яке тягнуть, чекає на схованому столі, а за курсором їде його квадрат. Розкладене вікно
    // заступає «місце» (DropPlace) — напівпрозоре порожнє вікно, яке Hyprland розкладає як звичайне:
    // сусіди розсуваються, і видно, куди стане вікно. Місце для нього вибирає сам Hyprland — за курсором
    // (dwindle smart_split: бік вікна під курсором), тож на час перетягування ці опції підмінюємо.
    readonly property string placeTitle: "unia-drop-place"
    property string placeAddr: ""             // адреса вікна-місця, коли воно відкрите
    // місце живе й трохи після кидка — поки Hyprland ставить на нього вікно (зникни воно раніше, команда
    // «прибрати місце» не знайшла б його й спрацювала б на активному вікні)
    readonly property bool placeWanted: !!drag && !drag.floating || placeHold.running
    property string placeKey: ""              // куди зараз поставлене місце: «адреса:бік» або «ws:N»
    property var opts: ({ ua: 1, ss: 0, nw: 0 })   // справжні dwindle:use_active_for_splits, smart_split, cursor:no_warps

    function hypr(cmds) { Quickshell.execDetached(["hyprctl", "--batch", cmds.join(" ; ")]) }
    function restoreOpts() {
        return [`keyword dwindle:use_active_for_splits ${opts.ua}`, `keyword dwindle:smart_split ${opts.ss}`,
                `keyword cursor:no_warps ${opts.nw}`]
    }
    Timer { id: restore; interval: 400 }      // щойно повернули опції — опитування ще могло прочитати підмінені
    Timer { id: placeHold; interval: 500 }

    function startDrag(a, x, y, grab) {
        const c = client(a)
        if (!c) return
        dragX = x; dragY = y
        const cmds = []
        // повноекранне спершу повертаємо у звичайне — тягнути його як квадрат, а поставити звичайним вікном
        if (c.fullscreen) cmds.push(`dispatch focuswindow address:${a}`, "dispatch fullscreen 0")
        drag = { address: a, floating: c.floating, wsId: c.workspace.id, mon: c.monitor, grab: !!grab,
                 rect: { x: c.at[0], y: c.at[1], w: c.size[0], h: c.size[1] },
                 // де саме тримаємо вікно (для плаваючого — щоб стало так само під курсором)
                 offX: Math.max(0, Math.min(c.size[0], x - c.at[0])), offY: Math.max(0, Math.min(c.size[1], y - c.at[1])) }
        placeKey = ""
        Windows.remember(a, c.workspace.id)
        Windows.moving = true
        if (!c.floating) cmds.push("keyword dwindle:use_active_for_splits 0", "keyword dwindle:smart_split 1", "keyword cursor:no_warps 1")
        // відпускання кнопки ловить Hyprland (не наш шар: поки вікна перескакують, шар може втратити курсор)
        cmds.push("keyword bindrn ,mouse:272,exec,qs -c unia ipc call drop release")
        // поки тягнемо, саме вікно чекає на схованому столі (у смузі — як згорнуте, сценарій його не втрачає).
        // Фокусу йому не можна: фокус на вікні схованого столу показує весь стіл
        cmds.push(`dispatch setprop address:${a} no_focus 1`, `dispatch movetoworkspacesilent ${dragWs},address:${a}`)
        hypr(cmds)
    }
    function moveDrag(x, y) {
        dragX = x; dragY = y
        if (!placeWanted) return
        const k = placeKeyAt(x, y)
        if (k !== null && k !== placeKey) { placeKey = k; reloc.restart() }
    }
    // куди стало б вікно, якби відпустили тут; null — лишити як є (курсор на самому місці чи в проміжку)
    function placeKeyAt(x, y) {
        const m = monitorAt(x, y)
        if (!m) return null
        const p = client(placeAddr)
        if (p && p.workspace.id === m.activeWorkspace.id && x >= p.at[0] && x < p.at[0] + p.size[0] && y >= p.at[1] && y < p.at[1] + p.size[1])
            return null
        const tiled = visibleOn(m).filter(c => !c.floating && c.address !== drag.address)
        const t = tiled.slice().reverse().find(c => x >= c.at[0] && x < c.at[0] + c.size[0] && y >= c.at[1] && y < c.at[1] + c.size[1])
        if (!t) return tiled.length ? null : `ws:${m.activeWorkspace.id}`
        const dx = (x - (t.at[0] + t.size[0] / 2)) / t.size[0], dy = (y - (t.at[1] + t.size[1] / 2)) / t.size[1]
        return `${t.address}:${Math.abs(dx) > Math.abs(dy) ? (dx < 0 ? "l" : "r") : (dy < 0 ? "u" : "d")}`
    }
    Timer { id: reloc; interval: 70; onTriggered: root.relocate() }
    // переставити місце під курсор: прибрати й вставити знову (Hyprland сам вибере бік)
    function relocate() {
        const m = monitorAt(dragX, dragY)
        if (!placeAddr || !m || !placeWanted) return
        hypr([`dispatch movetoworkspacesilent ${dragWs},address:${placeAddr}`,
              `dispatch movetoworkspacesilent ${m.activeWorkspace.id},address:${placeAddr}`])
        soon.restart()
    }

    function endDrag() {
        const d = drag
        if (!d) return
        const m = monitorAt(dragX, dragY) ?? monitors.find(m => m.id === d.mon)
        if (!m) { cancelDrag(); return }
        const a = d.address, ws = m.activeWorkspace.id
        const back = `dispatch setprop address:${a} no_focus unset`
        const p = client(placeAddr)
        let cmds
        if (d.floating) {
            // плаваюче — туди, де відпустили, тим самим місцем під курсором, що й тримали
            const mw = m.width / m.scale, mh = m.height / m.scale
            const x = Math.round(Math.max(m.x, Math.min(dragX - d.offX, m.x + mw - d.rect.w)))
            const y = Math.round(Math.max(m.y, Math.min(dragY - d.offY, m.y + mh - d.rect.h)))
            cmds = [`dispatch movetoworkspacesilent ${ws},address:${a}`, `dispatch movewindowpixel exact ${x} ${y},address:${a}`,
                    back, `dispatch focuswindow address:${a}`]
        } else if (p && p.workspace.id === ws) {
            // розкладене — рівно на місце: ділить його (воно у фокусі), а потім місце зникає й вікно забирає весь його простір
            cmds = [`dispatch setprop address:${placeAddr} no_focus 0`, `dispatch focuswindow address:${placeAddr}`,
                    "keyword dwindle:use_active_for_splits 1",
                    `dispatch movetoworkspacesilent ${ws},address:${a}`,
                    `dispatch movetoworkspacesilent ${dragWs},address:${placeAddr}`,
                    back, `dispatch focuswindow address:${a}`, ...restoreOpts()]
        } else {
            cmds = [...(p ? [`dispatch movetoworkspacesilent ${dragWs},address:${placeAddr}`] : []),
                    `dispatch movetoworkspacesilent ${ws},address:${a}`, back, `dispatch focuswindow address:${a}`, ...restoreOpts()]
        }
        finish(cmds)
    }
    function cancelDrag() {
        const d = drag
        if (!d) return
        const cmds = []
        if (client(placeAddr)) cmds.push(`dispatch movetoworkspacesilent ${dragWs},address:${placeAddr}`)
        cmds.push(`dispatch movetoworkspacesilent ${d.wsId},address:${d.address}`, `dispatch setprop address:${d.address} no_focus unset`)
        if (d.floating) cmds.push(`dispatch movewindowpixel exact ${d.rect.x} ${d.rect.y},address:${d.address}`)
        else cmds.push(...restoreOpts())
        finish(cmds)
    }
    function finish(cmds) {
        if (!drag.floating) { restore.restart(); placeHold.restart() }
        drag = null                           // місце (DropPlace) зникає саме, щойно мине placeHold
        hypr([...cmds, "keyword unbind ,mouse:272"])
        Windows.moving = false
        hovered = ""
        placeKey = ""
        soon.restart()
    }

    // курсор під час перетягування — прямо з сокета Hyprland: поки кнопку затиснуто (Super+ЛКМ перехопив
    // Hyprland) чи вікна перескакують, наш шар руху курсора може й не отримувати
    Process {
        id: cursorStream
        running: !!root.drag
        command: ["python3", "-u", "-c", `
import os, socket, time
p = os.path.join(os.environ["XDG_RUNTIME_DIR"], "hypr", os.environ["HYPRLAND_INSTANCE_SIGNATURE"], ".socket.sock")
last = None
while True:
    s = socket.socket(socket.AF_UNIX); s.connect(p); s.sendall(b"cursorpos"); d = s.recv(64); s.close()
    if d != last: print(d.decode().strip(), flush=True); last = d
    time.sleep(0.012)
`]
        stdout: SplitParser {
            onRead: line => {
                const [x, y] = line.split(",").map(Number)
                if (root.drag && !isNaN(x) && !isNaN(y)) root.moveDrag(x, y)
            }
        }
    }

    // Super+ЛКМ: узяти вікно під курсором (замість звичайного перетягування Hyprland), Super+відпустити — поставити
    property bool grabbing: false
    property bool releaseEarly: false
    function grab() {
        if (drag || grabbing) return
        closeMenu()
        grabbing = true
        releaseEarly = false
        cursorProc.running = true
    }
    function release() {
        if (grabbing) releaseEarly = true
        else if (drag) endDrag()
    }
    Process {
        id: cursorProc
        command: ["hyprctl", "-j", "cursorpos"]
        stdout: StdioCollector {
            onStreamFinished: {
                let p = null
                try { p = JSON.parse(text) } catch (e) {}
                const m = p ? root.monitorAt(p.x, p.y) : null
                const t = m ? root.windowAt(m, p.x, p.y) : null
                if (!t) { root.grabbing = false; return }
                root.hovered = t.address           // знімок вікна для квадрата
                grabStart.pos = p
                grabStart.restart()
            }
        }
    }
    Timer {
        id: grabStart
        property var pos
        interval: 90                          // дати знімку вікна з'явитись, поки вікно ще видно
        onTriggered: {
            root.grabbing = false
            root.startDrag(root.hovered, pos.x, pos.y, true)
            if (root.releaseEarly) root.endDrag()
        }
    }
}
