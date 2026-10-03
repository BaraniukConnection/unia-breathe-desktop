pragma Singleton
import QtQuick
import Quickshell

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

    function launch(id) {
        if (id === "unia-settings") { Settings.open(); return }
        const e = byId(id)
        if (e) e.execute()
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
