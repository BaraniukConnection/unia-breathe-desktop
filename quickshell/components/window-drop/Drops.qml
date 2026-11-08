pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "../../services"

// WindowDrop: a drop notch in the middle of a window's top border (like a front-camera cut-out).
// As the cursor nears, the notch grows out of the border; press and drag (or Super+LMB anywhere in the window)
// and the window shrinks to a square that follows the cursor, while room opens where it will land (DropPlace);
// a click opens the window menu.
// State and actions live here; each monitor draws its own layer (WindowDrop.qml).
Singleton {
    id: root
    readonly property string dragWs: Windows.dragWs      // where the window waits while it is dragged
    // service desks whose windows get no notch
    readonly property var skipWs: ["special:settings", "special:unia-stash", Windows.minimizedWs, Windows.dragWs]

    property var clients: []
    property var monitors: []
    property int border: 1                    // general:border_size

    property string hovered: ""               // address of the window whose border is under the cursor
    property string menuFor: ""               // address of the window whose menu is open
    property var drag: null                   // { address, floating, wsId, rect, mon, offX, offY, grab } while dragging
    property real dragX: 0                    // cursor while dragging (global coordinates)
    property real dragY: 0
    property var resizing: null               // { address, floating, quad, rect, sent }: resize mode
    readonly property bool busy: menuFor !== "" || drag !== null || resizing !== null
    readonly property string current: drag ? drag.address : menuFor || hovered   // the window that has the notch

    function client(a) { return clients.find(c => c.address === a) ?? null }
    // window border width: a fullscreen window (not just maximized) has none, so the notch grows from the screen edge
    function bandOf(c) { return c && c.fullscreen >= 2 ? 0 : border }
    function monitorAt(x, y) {
        return monitors.find(m => x >= m.x && x < m.x + m.width / m.scale && y >= m.y && y < m.y + m.height / m.scale) ?? null
    }

    // windows visible on a monitor, bottom to top: tiled first, then floating; older focus lower.
    // With a fullscreen window only that one is visible (the rest are under it).
    function visibleOn(m) {
        if (!m) return []
        const ws = m.specialWorkspace.name || m.activeWorkspace.name
        if (skipWs.includes(ws)) return []
        const list = clients.filter(c => c.mapped && !c.hidden && c.workspace.name === ws && c.class !== "org.quickshell")
        const full = list.filter(c => c.fullscreen).sort((a, b) => a.focusHistoryID - b.focusHistoryID)
        if (full.length) return [full[0]]
        return list.sort((a, b) => (a.floating - b.floating) || (b.focusHistoryID - a.focusHistoryID))
    }
    // the top window under a point (except the given one)
    function windowAt(m, x, y, except) {
        const ws = visibleOn(m).filter(c => c.address !== except)
        for (let i = ws.length - 1; i >= 0; i--) {
            const c = ws[i]
            if (x >= c.at[0] && x < c.at[0] + c.size[0] && y >= c.at[1] && y < c.at[1] + c.size[1]) return c
        }
        return null
    }

    // ---------- Hyprland state: windows, monitors, border width ----------
    // Hyprland sends no events for size changes, so besides events we re-read every 0.7 s
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
                    // these options are swapped while dragging: remember only the real ones
                    // (booleans come as "bool" since Hyprland 0.57)
                    const on = o => "bool" in o ? o.bool : !!o.int
                    if (!root.drag && !restore.running) root.opts = { ua: on(ua), ss: on(ss), nw: on(nw) }
                } catch (e) {}
                if (root.menuFor && !root.client(root.menuFor)) root.closeMenu()
                // the window closed or left the visible desk: resize mode has nothing left to act on
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

    // ---------- hover ----------
    // with a 0 (or 1 px) border the notch has nothing to grow from: while it is shown the border is 3 px
    property string thick: ""
    onCurrentChanged: {
        if (thick && thick !== current) { Hypr.setProp(`address:${thick}`, "border_size", "unset"); thick = "" }
        if (current && border < 2 && client(current) && !client(current).fullscreen) { Hypr.setProp(`address:${current}`, "border_size", "3"); thick = current }
    }

    // ---------- menu ----------
    function openMenu(a) { hovered = a; menuFor = a }
    function closeMenu() { menuFor = ""; hovered = "" }    // the cursor is still on the hook: the next move brings the notch back
    function act(what) {
        const c = client(menuFor)
        closeMenu()
        if (!c) return
        const a = c.address
        if (what === "minimize")
            Windows.minimize({ address: a, wsId: c.workspace.id ?? 0, wsName: c.workspace.name })
        else if (what === "fullscreen") {
            Hypr.focusWindow(`address:${a}`)
            Hypr.fullscreen(`address:${a}`, "toggle")
        } else if (what === "float")
            Hypr.float(`address:${a}`, "toggle")
        else if (what === "close")
            Hypr.close(`address:${a}`)
        soon.restart()
    }
    function moveTo(wsId) {
        const c = client(menuFor)
        closeMenu()
        if (c) Hypr.moveToWorkspace(`address:${c.address}`, wsId)
        soon.restart()
    }

    // ---------- resizing (like Super+RMB) ----------
    // A dashed cross splits the window into quarters: dragging in a quarter moves the two sides next to it
    // (top right: the right and top sides), in the direction you drag.
    // A floating window is resized exactly. A tiled one shares its edge with a neighbour, and on "grow wider"
    // Hyprland always moves the right (bottom) edge. So the left or top edge is moved by resizing the neighbour on
    // that side, the right or bottom one by resizing the window itself; an edge at the screen border stays put.
    function startResize(a) {
        const c = client(a)
        closeMenu()
        if (!c) return
        resizing = { address: a, floating: c.floating, quad: "", rect: null }
    }
    function stopResize() { resizing = null }
    // the tiled window next to side ("l", "r", "t", "b") of window c; if there are several,
    // the one facing the press point (px, py)
    function neighbour(c, side, px, py) {
        const L = c.at[0], T = c.at[1], R = L + c.size[0], B = T + c.size[1], tol = 40
        const across = (a0, a1, b0, b1) => Math.min(a1, b1) - Math.max(a0, b0) > 0
        const near = clients.filter(o => o.address !== c.address && !o.floating && o.mapped && !o.hidden
                                         && o.workspace.name === c.workspace.name).filter(o => {
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
    // pressed in quarter quad ("lt", "rt", "lb", "rb") at (px, py): remember what to measure from
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
    // the cursor moved by (dx, dy) since the press
    function moveResize(dx, dy) {
        const r = resizing
        if (!r || !r.rect) return
        const left = r.quad[0] === "l", top = r.quad[1] === "t"
        const clamp = (v, lo, hi) => Math.max(lo, Math.min(hi, v))
        if (r.floating) {
            const w = Math.max(160, r.rect.w + (left ? -dx : dx)), h = Math.max(120, r.rect.h + (top ? -dy : dy))
            const x = left ? r.rect.x + r.rect.w - w : r.rect.x, y = top ? r.rect.y + r.rect.h - h : r.rect.y
            Hypr.resize(`address:${r.address}`, w, h)
            Hypr.move(`address:${r.address}`, x, y)
            soon.restart()
            return
        }
        // how far the edge moves (towards dx, dy) without shrinking either window below 160×120
        const ex = !r.nx ? 0 : Math.round(left ? clamp(dx, 160 - r.nx.w, r.rect.w - 160) : clamp(dx, 160 - r.rect.w, r.nx.w - 160))
        const ey = !r.ny ? 0 : Math.round(top ? clamp(dy, 120 - r.ny.h, r.rect.h - 120) : clamp(dy, 120 - r.rect.h, r.ny.h - 120))
        const sx = ex - r.sent.x, sy = ey - r.sent.y
        if (!sx && !sy) return
        r.sent = { x: ex, y: ey }
        // the left/top edge is the neighbour's right/bottom edge; the right/bottom one is the window's own
        const tx = left ? (r.nx ? r.nx.address : null) : r.address
        const ty = top ? (r.ny ? r.ny.address : null) : r.address
        if (sx && sy && tx === ty) Hypr.resize(`address:${tx}`, sx, sy, true)
        else {
            if (sx && tx) Hypr.resize(`address:${tx}`, sx, 0, true)
            if (sy && ty) Hypr.resize(`address:${ty}`, 0, sy, true)
        }
        soon.restart()
    }
    function endResize() { if (resizing) resizing = Object.assign({}, resizing, { quad: "", rect: null, nx: null, ny: null }) }

    // ---------- dragging ----------
    // The dragged window waits on a hidden desk while its square follows the cursor. A tiled window
    // is stood in for by a "place" (DropPlace), a translucent empty window that Hyprland tiles like any other:
    // neighbours make room and you see where the window will land. Hyprland itself picks the spot from the cursor
    // (dwindle smart_split: the side of the window under the cursor), so these options are swapped while dragging.
    readonly property string placeTitle: "unia-drop-place"
    property string placeAddr: ""             // address of the place window while it is open
    // the place lives a little after the drop, while Hyprland puts the window on it (if it vanished earlier, the
    // "remove the place" command would not find it and would hit the active window instead)
    readonly property bool placeWanted: !!drag && !drag.floating || placeHold.running
    property string placeKey: ""              // where the place is now: "address:side" or "ws:N"
    property var opts: ({ ua: true, ss: false, nw: false })   // the real dwindle:use_active_for_splits, smart_split, cursor:no_warps

    // steps run in one go, in order (see Hypr.run): dispatchers and hl.config / hl.bind statements
    function hypr(steps) { Hypr.run(steps) }
    function setOpts(ua, ss, nw) { return Hypr.configLua({ "dwindle:use_active_for_splits": ua, "dwindle:smart_split": ss, "cursor:no_warps": nw }) }
    function restoreOpts() { return [setOpts(opts.ua, opts.ss, opts.nw)] }
    function at(a) { return `address:${a}` }
    Timer { id: restore; interval: 400 }      // options were just restored: a poll may still have read the swapped ones
    Timer { id: placeHold; interval: 500 }

    function startDrag(a, x, y, grab) {
        const c = client(a)
        if (!c) return
        dragX = x; dragY = y
        const cmds = []
        // a fullscreen window goes back to normal first: it is dragged as a square and dropped as a normal window
        if (c.fullscreen) cmds.push(Hypr.fullscreenDsp(at(a), "unset"))
        // special desks have no id since Hyprland 0.57: keep their name instead
        drag = { address: a, floating: c.floating, wsId: c.workspace.id ?? c.workspace.name, mon: c.monitor, grab: !!grab,
                 rect: { x: c.at[0], y: c.at[1], w: c.size[0], h: c.size[1] },
                 // where exactly the window is held (so a floating one lands the same way under the cursor)
                 offX: Math.max(0, Math.min(c.size[0], x - c.at[0])), offY: Math.max(0, Math.min(c.size[1], y - c.at[1])) }
        placeKey = ""
        Windows.remember(a, c.workspace.id ?? c.workspace.name)
        Windows.moving = true
        if (!c.floating) cmds.push(setOpts(false, true, true))
        // Hyprland catches the button release (not our layer: while windows jump around, the layer can lose the cursor)
        cmds.push(`hl.bind("mouse:272", hl.dsp.exec_cmd("qs -c unia ipc call drop release"), { release = true, non_consuming = true })`)
        // while dragging, the window itself waits on a hidden desk (on the bar it shows as minimized; the scenario keeps it).
        // It must not get focus: focusing a window on a hidden desk reveals the whole desk
        cmds.push(Hypr.setPropDsp(at(a), "no_focus", "1"), Hypr.moveToWorkspaceDsp(at(a), dragWs))
        hypr(cmds)
    }
    function moveDrag(x, y) {
        dragX = x; dragY = y
        if (!placeWanted) return
        const k = placeKeyAt(x, y)
        if (k !== null && k !== placeKey) { placeKey = k; reloc.restart() }
    }
    // where the window would land if dropped here; null keeps things as they are (cursor on the place itself or in a gap)
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
    // move the place under the cursor: remove it and insert it again (Hyprland picks the side)
    function relocate() {
        const m = monitorAt(dragX, dragY)
        if (!placeAddr || !m || !placeWanted) return
        hypr([Hypr.moveToWorkspaceDsp(at(placeAddr), dragWs), Hypr.moveToWorkspaceDsp(at(placeAddr), m.activeWorkspace.id)])
        soon.restart()
    }

    function endDrag() {
        const d = drag
        if (!d) return
        const m = monitorAt(dragX, dragY) ?? monitors.find(m => m.id === d.mon)
        if (!m) { cancelDrag(); return }
        const a = d.address, ws = m.activeWorkspace.id
        const back = Hypr.setPropDsp(at(a), "no_focus", "unset")
        const p = client(placeAddr)
        let cmds
        if (d.floating) {
            // floating: to where it was dropped, with the same point under the cursor it was held by
            const mw = m.width / m.scale, mh = m.height / m.scale
            const x = Math.round(Math.max(m.x, Math.min(dragX - d.offX, m.x + mw - d.rect.w)))
            const y = Math.round(Math.max(m.y, Math.min(dragY - d.offY, m.y + mh - d.rect.h)))
            cmds = [Hypr.moveToWorkspaceDsp(at(a), ws), Hypr.moveDsp(at(a), x, y), back, Hypr.focusWindowDsp(at(a))]
        } else if (p && p.workspace.id === ws) {
            // tiled: exactly onto the place: it splits the place (which has focus), then the place goes and the window takes its whole space
            cmds = [Hypr.setPropDsp(at(placeAddr), "no_focus", "0"), Hypr.focusWindowDsp(at(placeAddr)),
                    Hypr.configLua({ "dwindle:use_active_for_splits": true }),
                    Hypr.moveToWorkspaceDsp(at(a), ws),
                    Hypr.moveToWorkspaceDsp(at(placeAddr), dragWs),
                    back, Hypr.focusWindowDsp(at(a)), ...restoreOpts()]
        } else {
            cmds = [...(p ? [Hypr.moveToWorkspaceDsp(at(placeAddr), dragWs)] : []),
                    Hypr.moveToWorkspaceDsp(at(a), ws), back, Hypr.focusWindowDsp(at(a)), ...restoreOpts()]
        }
        finish(cmds)
    }
    function cancelDrag() {
        const d = drag
        if (!d) return
        const cmds = []
        if (client(placeAddr)) cmds.push(Hypr.moveToWorkspaceDsp(at(placeAddr), dragWs))
        cmds.push(Hypr.moveToWorkspaceDsp(at(d.address), d.wsId), Hypr.setPropDsp(at(d.address), "no_focus", "unset"))
        if (d.floating) cmds.push(Hypr.moveDsp(at(d.address), d.rect.x, d.rect.y))
        else cmds.push(...restoreOpts())
        finish(cmds)
    }
    function finish(cmds) {
        if (!drag.floating) { restore.restart(); placeHold.restart() }
        drag = null                           // the place (DropPlace) goes away by itself once placeHold passes
        hypr([...cmds, `hl.unbind("mouse:272")`])
        Windows.moving = false
        hovered = ""
        placeKey = ""
        soon.restart()
    }

    // the cursor while dragging comes straight from Hyprland's socket: while the button is held (Super+LMB is taken
    // by Hyprland) or windows jump around, our layer may not get cursor motion at all
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

    // Super+LMB: pick up the window under the cursor (instead of Hyprland's own drag); release to drop it
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
                root.hovered = t.address           // a snapshot of the window for the square
                grabStart.pos = p
                grabStart.restart()
            }
        }
    }
    Timer {
        id: grabStart
        property var pos
        interval: 90                          // let the window snapshot appear while the window is still visible
        onTriggered: {
            root.grabbing = false
            root.startDrag(root.hovered, pos.x, pos.y, true)
            if (root.releaseEarly) root.endDrag()
        }
    }
}
