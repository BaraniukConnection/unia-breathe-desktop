pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland

// Talking to Hyprland 0.57+, whose config and dispatchers are Lua: `hyprctl dispatch` takes a dispatcher
// expression (hl.dsp.window.close()), and options change through `hyprctl eval 'hl.config({...})'`
// (`hyprctl keyword` is gone). Reading options is unchanged: `hyprctl getoption <key> -j`.
// Windows are picked by a selector string: "address:0x…", "title:^(…)$", "class:…".
Singleton {
    id: root

    // ---------- Lua literals ----------
    function str(s) { return JSON.stringify(String(s)) }            // a JSON string is a valid Lua string
    function lua(v) {
        if (v === null || v === undefined) return "nil"
        if (typeof v === "boolean" || typeof v === "number") return String(v)
        if (typeof v === "string") return str(v)
        if (Array.isArray(v)) return `{ ${v.map(lua).join(", ")} }`
        return `{ ${Object.keys(v).map(k => `${/^[A-Za-z_][A-Za-z0-9_]*$/.test(k) ? k : `[${str(k)}]`} = ${lua(v[k])}`).join(", ")} }`
    }
    // a desk: a number, or a selector ("special:…", "name:…", "m+1", "empty"); a bare name gets "name:"
    function ws(w) {
        const s = String(w)
        if (/^-?\d+$/.test(s)) return s
        return str(/^(special:|name:|[mre][+-]|empty|previous)/.test(s) ? s : "name:" + s)
    }

    // ---------- options ----------
    // "a:b:c" (and "general:col.active_border") → { a = { b = { c = … } } }; a gradient string ("rgba(…) rgba(…) 45deg") becomes { colors, angle }
    function value(key, v) {
        const s = String(v)
        if (/(^|:)col\./.test(key) && /^\s*(rgba?\([^)]*\)\s*)+(-?\d+deg)?\s*$/.test(s)) {
            const colors = s.match(/rgba?\([^)]*\)/g)
            const angle = s.match(/(-?\d+)deg/)
            return colors.length === 1 && !angle ? colors[0] : { colors: colors, angle: angle ? Number(angle[1]) : 0 }
        }
        return v
    }
    function nest(map) {
        const out = {}
        for (const key of Object.keys(map)) {
            const path = key.split(/[:.]/)
            let t = out
            for (const p of path.slice(0, -1)) t = t[p] = t[p] ?? {}
            t[path[path.length - 1]] = value(key, map[key])
        }
        return out
    }
    function configLua(map) { return `hl.config(${lua(nest(map))})` }
    // change options live (not saved: Prefs writes them into the config Hyprland loads)
    function config(map) { evaluate(configLua(map)) }

    // ---------- dispatching ----------
    function dispatch(expr) { Hyprland.dispatch(expr) }
    // several steps in one go, in order: dispatcher expressions and plain Lua statements (hl.config…, hl.bind…)
    function run(steps) { evaluate(steps.map(s => s.startsWith("hl.dsp.") ? `hl.dispatch(${s})` : s).join("\n")) }
    function evaluate(code) { Quickshell.execDetached(["hyprctl", "eval", code]) }

    // dispatcher expressions, for dispatch() or run()
    function focusWindowDsp(sel) { return `hl.dsp.focus({ window = ${str(sel)} })` }
    function moveToWorkspaceDsp(sel, w, follow) { return `hl.dsp.window.move({ window = ${str(sel)}, workspace = ${ws(w)}, follow = ${!!follow} })` }
    function moveDsp(sel, x, y, relative) { return `hl.dsp.window.move({ window = ${str(sel)}, x = ${Math.round(x)}, y = ${Math.round(y)}, relative = ${!!relative} })` }
    function resizeDsp(sel, w, h, relative) { return `hl.dsp.window.resize({ window = ${str(sel)}, x = ${Math.round(w)}, y = ${Math.round(h)}, relative = ${!!relative} })` }
    function floatDsp(sel, action) { return `hl.dsp.window.float({ window = ${str(sel)}, action = ${str(action)} })` }   // enable | disable | toggle (set / unset would toggle!)
    function fullscreenDsp(sel, action) { return `hl.dsp.window.fullscreen({ window = ${str(sel)}, action = ${str(action)} })` }
    function closeDsp(sel) { return `hl.dsp.window.close({ window = ${str(sel)} })` }
    function setPropDsp(sel, prop, v) { return `hl.dsp.window.set_prop({ window = ${str(sel)}, prop = ${str(prop)}, value = ${str(v)} })` }   // value "unset" clears it

    function focusWindow(sel) { dispatch(focusWindowDsp(sel)) }
    function moveToWorkspace(sel, w, follow) { dispatch(moveToWorkspaceDsp(sel, w, follow)) }
    function move(sel, x, y, relative) { dispatch(moveDsp(sel, x, y, relative)) }
    function resize(sel, w, h, relative) { dispatch(resizeDsp(sel, w, h, relative)) }
    function float(sel, action) { dispatch(floatDsp(sel, action)) }
    function fullscreen(sel, action) { dispatch(fullscreenDsp(sel, action)) }
    function close(sel) { dispatch(closeDsp(sel)) }
    function setProp(sel, prop, v) { dispatch(setPropDsp(sel, prop, v)) }
    function toggleSpecial(name) { dispatch(`hl.dsp.workspace.toggle_special(${str(name.replace(/^special:/, ""))})`) }
    function workspace(w) { dispatch(`hl.dsp.focus({ workspace = ${ws(w)} })`) }   // a number, "m+1", "empty", "name:…"
    function focusMonitor(name) { dispatch(`hl.dsp.focus({ monitor = ${str(name)} })`) }
    function cycleNext() { dispatch("hl.dsp.window.cycle_next()") }
    function layout(msg) { dispatch(`hl.dsp.layout(${str(msg)})`) }
}
