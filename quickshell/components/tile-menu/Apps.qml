pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../settings-box"
import "../../services"

// Installed apps (from .desktop files), search and launching. The shell's Settings is an app too.
Singleton {
    id: root
    readonly property var settingsEntry: ({ id: "unia-settings", name: "Settings", genericName: "Unia Breathe Desktop",
                                            icon: "preferences-system", categories: ["Settings"], keywords: ["settings", "preferences"] })
    readonly property var list: [settingsEntry, ...DesktopEntries.applications.values.filter(e => !e.noDisplay)]
        .sort((a, b) => a.name.localeCompare(b.name))
    readonly property var ids: list.map(e => e.id)

    function byId(id) { return id === "unia-settings" ? settingsEntry : list.find(e => e.id === id) ?? null }
    function icon(e) { return e ? Quickshell.iconPath(e.icon, "application-x-executable") : "" }

    // apps that keep one main window: if already open, go straight to it
    readonly property var singleKeys: ["claude", "steam", "telegram", "discord", "spotify", "heroic", "lutris", "obsidian", "slack", "signal"]
    function single(e) { return singleKeys.some(k => e.id.toLowerCase().includes(k)) }

    function launch(id) {
        if (id === "unia-settings") { Settings.open(); return }
        const e = byId(id)
        if (!e) return
        const open = Windows.ofEntry(e)
        if (open.length && single(e)) { Windows.focus(open[0]); return }
        e.execute()
        // the rest: if no new window shows up within 2.5 s (the app only woke up), show the existing one
        if (open.length) { pending = { e: e, before: open.map(w => w.address) }; noNewWindow.restart() }
    }
    property var pending: null
    Timer {
        id: noNewWindow
        interval: 2500
        onTriggered: {
            const p = root.pending
            root.pending = null
            if (!p) return
            const now = Windows.ofEntry(p.e)
            if (!now.some(w => !p.before.includes(w.address)) && now.length) Windows.focus(now[0])
        }
    }

    // search: a match at the start of the name weighs most, then at the start of a word, then anywhere (name, description, keywords)
    function search(q) {
        q = q.trim().toLowerCase()
        if (!q) return []
        const scored = []
        for (const e of list) {
            const name = e.name.toLowerCase()
            const extra = [e.genericName ?? "", ...(e.keywords ?? []), ...(e.categories ?? []), e.id].join(" ").toLowerCase()
            let s = name.startsWith(q) ? 3 : name.split(/[\s\-_.]+/).some(w => w.startsWith(q)) ? 2
                  : name.includes(q) ? 1.5 : extra.includes(q) ? 1 : 0
            if (s > 0) scored.push({ e: e, s: s })
        }
        return scored.sort((a, b) => b.s - a.s || a.e.name.localeCompare(b.e.name)).map(x => x.e)
    }

    // a live tile: what to show instead of the icon
    function liveKind(e) {
        if (!e || !e.categories) return ""
        const c = e.categories
        if (c.includes("Calendar")) return "calendar"
        if (c.includes("Clock")) return "clock"
        if (Media.entry && Media.entry.id === e.id) return "media"
        return ""
    }
}
