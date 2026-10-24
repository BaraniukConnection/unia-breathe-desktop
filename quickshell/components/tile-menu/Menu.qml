pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// The app menu: dock favourites and folders of tiles (~/.config/unia-breathe/menu.json).
// A folder grid is 8 cells wide; the layout logic (settle/dropInto/freeSlot) comes from the mockup.
Singleton {
    id: root
    readonly property int cols: 8
    readonly property var sizes: ({ small: [1, 1], medium: [2, 2], wide: [4, 2], large: [4, 4] })
    readonly property int maxFavs: 5
    property var data: ({ favs: [], columns: [[], []] })
    property bool ready: false

    // ---------- grid (from the mockup) ----------
    function dims(t) { return sizes[t.size] }
    function stepOf(t) { return t.size === "small" ? 1 : 2 }
    function hit(a, b) {
        const [aw, ah] = dims(a), [bw, bh] = dims(b)
        return a.x < b.x + bw && b.x < a.x + aw && a.y < b.y + bh && b.y < a.y + ah
    }
    function rowsOf(tiles) { return tiles.reduce((m, t) => Math.max(m, t.y + dims(t)[1]), 0) }
    // first stays put, everything it covers slides down, then all tiles float up
    function settle(tiles, first) {
        for (const t of tiles) {
            if (stepOf(t) === 2) { t.x -= t.x % 2; t.y -= t.y % 2 }
            t.x = Math.max(0, Math.min(cols - dims(t)[0], t.x))
            t.y = Math.max(0, t.y)
        }
        const rank = t => (t === first ? 0 : 1)
        const placed = []
        for (const t of tiles.slice().sort((a, b) => rank(a) - rank(b) || a.y - b.y || a.x - b.x)) {
            let moved = true
            while (moved) {
                moved = false
                for (const p of placed) if (hit(t, p)) { t.y = p.y + dims(p)[1]; if (stepOf(t) === 2 && t.y % 2) t.y++; moved = true }
            }
            placed.push(t)
        }
        const done = []
        for (const t of tiles.slice().sort((a, b) => a.y - b.y || rank(a) - rank(b) || a.x - b.x)) {
            const s = stepOf(t)
            while (t.y - s >= 0) { t.y -= s; if (done.some(p => hit(t, p))) { t.y += s; break } }
            done.push(t)
        }
    }
    // tiles that t landed on move to its old spot (if they fit); settle shifts the rest
    function dropInto(tiles, t, origin) {
        if (origin) {
            for (const c of tiles.filter(c => hit(c, t))) {
                const probe = { size: c.size, x: origin.x, y: origin.y }
                if (stepOf(c) === 2 && (probe.x % 2 || probe.y % 2)) continue
                if (probe.x + dims(c)[0] > cols) continue
                if (hit(probe, t) || tiles.some(q => q !== c && hit(probe, q))) continue
                c.x = probe.x; c.y = probe.y
            }
        }
        tiles.push(t)
        settle(tiles, t)
    }
    function freeSlot(tiles, size) {
        const w = sizes[size][0], s = size === "small" ? 1 : 2
        for (let y = 0; ; y += s) for (let x = 0; x + w <= cols; x += s)
            if (!tiles.some(t => hit({ size: size, x: x, y: y }, t))) return { x: x, y: y }
    }
    function uid() { return "i" + Math.random().toString(36).slice(2, 10) }

    // ---------- state ----------
    function clone() { return JSON.parse(JSON.stringify(data)) }
    function all() { return [].concat(...data.columns) }        // all folders as one list
    function groups(d) { return [].concat(...d.columns) }
    function commit(d) {
        data = d
        saveTimer.restart()
    }
    function locate(d, tileId) {
        for (const g of groups(d)) { const t = g.tiles.find(t => t.id === tileId); if (t) return { g: g, t: t } }
        return null
    }

    // every installed app lives on a tile: new ones as small tiles in Other, removed ones go away
    function normalize(d) {
        const have = new Set(Apps.ids)
        for (const g of groups(d)) g.tiles = g.tiles.filter(t => have.has(t.app))
        d.favs = d.favs.filter(a => have.has(a))
        const placed = new Set([].concat(...groups(d).map(g => g.tiles.map(t => t.app))))
        let misc = groups(d).find(g => g.misc)
        if (!misc) { misc = { id: uid(), name: "Other", misc: true, tiles: [] }; d.columns[d.columns.length - 1].push(misc) }
        for (const id of Apps.ids) if (!placed.has(id)) misc.tiles.push(Object.assign({ id: uid(), app: id, size: "small" }, freeSlot(misc.tiles, "small")))
        for (const g of groups(d)) settle(g.tiles)
        return d
    }

    // first run: folders by category, the main apps as medium tiles
    function seed() {
        // the best app for a word: exact id, then an id starting with it, then any match
        const best = k => Apps.list.find(e => e.id.toLowerCase() === k) ?? Apps.list.find(e => e.id.toLowerCase().startsWith(k))
                          ?? Apps.list.find(e => e.id.toLowerCase().includes(k)) ?? null
        const pick = (cats) => Apps.list.filter(e => (e.categories ?? []).some(c => cats.includes(c)))
        const used = new Set()
        const big = ["vivaldi", "thunar", "kitty", "claude", "telegram", "steam", "android", "unia-settings"].map(best).filter(e => e).map(e => e.id)
        const folder = (name, entries) => {
            const g = { id: uid(), name: name, tiles: [] }
            for (const e of entries) {
                if (used.has(e.id)) continue
                used.add(e.id)
                const size = big.includes(e.id) ? "medium" : "small"
                g.tiles.push(Object.assign({ id: uid(), app: e.id, size: size }, freeSlot(g.tiles, size)))
            }
            return g
        }
        const daily = folder("Daily", pick(["Network", "Office", "Utility", "FileManager", "TerminalEmulator"]))
        const create = folder("Create", pick(["Graphics", "AudioVideo", "Audio", "Video"]))
        const dev = folder("Develop", pick(["Development"]))
        const games = folder("Games", pick(["Game"]))
        const sys = folder("System", pick(["Settings", "System"]))
        const favs = ["vivaldi", "thunar", "kitty", "claude", "telegram"].map(best).filter(e => e).map(e => e.id)
        return normalize({ favs: favs, columns: [[daily, create], [dev, games, sys].filter(g => g.tiles.length)] })
    }

    // ---------- actions ----------
    function moveTile(tileId, toGroup, x, y) {
        const d = clone(), from = locate(d, tileId), to = groups(d).find(g => g.id === toGroup)
        if (!from || !to) return
        const origin = { x: from.t.x, y: from.t.y }
        from.g.tiles = from.g.tiles.filter(t => t !== from.t)
        from.t.x = x; from.t.y = y
        dropInto(to.tiles, from.t, from.g === to ? origin : null)
        if (from.g !== to) settle(from.g.tiles)
        commit(d)
    }
    function newFolder(tileId, column, index) {
        const d = clone(), from = locate(d, tileId)
        if (!from) return
        from.g.tiles = from.g.tiles.filter(t => t !== from.t)
        settle(from.g.tiles)
        from.t.x = 0; from.t.y = 0
        d.columns[column].splice(index, 0, { id: uid(), name: "New Folder", tiles: [from.t] })
        commit(d)
    }
    function resize(tileId, size) {
        const d = clone(), at = locate(d, tileId)
        if (!at) return
        at.t.size = size
        const rest = at.g.tiles.filter(t => t !== at.t)
        at.g.tiles = rest
        dropInto(at.g.tiles, at.t, null)
        commit(d)
    }
    function toggleLive(tileId) {
        const d = clone(), at = locate(d, tileId)
        if (!at) return
        if (at.t.live === false) delete at.t.live; else at.t.live = false
        commit(d)
    }
    function toMisc(tileId) {
        const misc = groups(data).find(g => g.misc)
        if (!misc) return
        const d = clone(), at = locate(d, tileId), m = groups(d).find(g => g.misc)
        at.g.tiles = at.g.tiles.filter(t => t !== at.t)
        at.t.size = "small"
        Object.assign(at.t, freeSlot(m.tiles, "small"))
        m.tiles.push(at.t)
        settle(at.g.tiles)
        commit(d)
    }
    function rename(groupId, name) {
        const d = clone(), g = groups(d).find(g => g.id === groupId)
        if (g && name.trim()) { g.name = name.trim().slice(0, 40); commit(d) }
    }
    function toggleFav(app) {
        const d = clone()
        if (d.favs.includes(app)) d.favs = d.favs.filter(a => a !== app)
        else if (d.favs.length < maxFavs) d.favs.push(app)
        else return false
        commit(d)
        return true
    }
    // folders: create (in the shorter column), delete (tiles go to Other), move
    function addFolder() {
        const d = clone()
        const height = c => c.reduce((h, g) => h + Math.max(1, rowsOf(g.tiles)) + 1, 0)
        const col = d.columns.length > 1 && height(d.columns[1]) < height(d.columns[0]) ? 1 : 0
        const g = { id: uid(), name: "New Folder", tiles: [] }
        d.columns[col].push(g)
        commit(d)
        return g.id
    }
    function deleteFolder(id) {
        const d = clone(), g = groups(d).find(g => g.id === id), m = groups(d).find(g => g.misc)
        if (!g || g.misc) return
        for (const t of g.tiles) { t.size = "small"; Object.assign(t, freeSlot(m.tiles, "small")); m.tiles.push(t) }
        d.columns = d.columns.map(c => c.filter(x => x !== g))
        commit(d)
    }
    function moveFolder(id, dir) {        // dir: -1 up, 1 down, "other": to the other column
        const d = clone()
        const ci = d.columns.findIndex(c => c.some(g => g.id === id))
        if (ci < 0) return
        const col = d.columns[ci], i = col.findIndex(g => g.id === id)
        if (dir === "other") {
            if (d.columns.length < 2) return
            const [g] = col.splice(i, 1)
            d.columns[1 - ci].push(g)
        } else {
            const j = i + dir
            if (j < 0 || j >= col.length) return;
            [col[i], col[j]] = [col[j], col[i]]
        }
        commit(d)
    }
    // put a folder into column col at position index (index among the column's other folders)
    function placeFolder(id, col, index) {
        const d = clone()
        let g = null
        d.columns = d.columns.map(c => c.filter(x => { if (x.id === id) { g = x; return false } return true }))
        if (!g) return
        d.columns[col].splice(Math.max(0, Math.min(index, d.columns[col].length)), 0, g)
        commit(d)
    }
    function reset() { data = seed(); saveTimer.restart() }

    // ---------- saving ----------
    Timer { id: saveTimer; interval: 400; onTriggered: store.setText(JSON.stringify(root.data, null, 1) + "\n") }
    FileView {
        id: store
        path: Quickshell.env("HOME") + "/.config/unia-breathe/menu.json"
        printErrors: false
        onLoaded: { try { root.raw = JSON.parse(text()) } catch (e) { root.raw = null } root.fileDone = true; root.sync() }
        onLoadFailed: { root.raw = null; root.fileDone = true; root.sync() }
    }
    // The app list does not arrive at once: reconcile the layout only when both the file and the apps are there,
    // or normalize() would drop every tile as not installed
    property var raw: null
    property bool fileDone: false
    function sync() {
        if (!fileDone || Apps.ids.length < 2) return
        if (!ready) {
            data = raw && raw.columns ? normalize(raw) : seed()
            ready = true
        } else data = normalize(clone())
        saveTimer.restart()
    }
    Connections {
        target: Apps
        function onIdsChanged() { root.sync() }       // an app was installed or removed: update the tiles
    }
}
