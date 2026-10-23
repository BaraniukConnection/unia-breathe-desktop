pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../settings-box"
import "../../services"

// Встановлені програми (з .desktop-файлів), пошук і запуск. «Налаштування» оболонки — теж програма.
Singleton {
    id: root
    readonly property var settingsEntry: ({ id: "unia-settings", name: "Налаштування", genericName: "Unia Breathe",
                                            icon: "preferences-system", categories: ["Settings"], keywords: ["settings", "параметри"] })
    readonly property var list: [settingsEntry, ...DesktopEntries.applications.values.filter(e => !e.noDisplay)]
        .sort((a, b) => a.name.localeCompare(b.name, "uk"))
    readonly property var ids: list.map(e => e.id)

    function byId(id) { return id === "unia-settings" ? settingsEntry : list.find(e => e.id === id) ?? null }
    function icon(e) { return e ? Quickshell.iconPath(e.icon, "application-x-executable") : "" }

    // програми, що тримають одне головне вікно: якщо вже відкриті — одразу переходимо до них
    readonly property var singleKeys: ["claude", "steam", "telegram", "discord", "spotify", "heroic", "lutris", "obsidian", "slack", "signal"]
    function single(e) { return singleKeys.some(k => e.id.toLowerCase().includes(k)) }

    function launch(id) {
        if (id === "unia-settings") { Settings.open(); return }
        const e = byId(id)
        if (!e) return
        const open = Windows.ofEntry(e)
        if (open.length && single(e)) { Windows.focus(open[0]); return }
        e.execute()
        // решта: якщо за 2,5 с нового вікна не з'явилось (програма лише «прокинулась») — показуємо наявне
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

    // пошук: збіг з початку назви важить найбільше, далі — з початку слова, далі — будь-де (назва, опис, ключові слова)
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
        return scored.sort((a, b) => b.s - a.s || a.e.name.localeCompare(b.e.name, "uk")).map(x => x.e)
    }

    // «жива» плитка: що показувати замість іконки
    function liveKind(e) {
        if (!e || !e.categories) return ""
        const c = e.categories
        if (c.includes("Calendar")) return "calendar"
        if (c.includes("Clock")) return "clock"
        if (Media.entry && Media.entry.id === e.id) return "media"
        return ""
    }
}
