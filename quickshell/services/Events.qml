pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Google Calendar events: every 15 min runs unia-calendar and reads ~/.cache/unia-breathe/events.json.
Singleton {
    id: root
    readonly property string home: Quickshell.env("HOME")
    property bool configured: false
    property var list: []          // [{ start: Date, allDay, title }]
    // the next event that has not ended yet (an all-day event lasts until the end of the day)
    readonly property var next: list.find(e => (e.allDay ? e.start.getTime() + 864e5 : e.start.getTime()) > clock.date.getTime()) ?? null

    function onDay(d) { return list.filter(e => e.start.toDateString() === d.toDateString()) }

    SystemClock { id: clock; precision: SystemClock.Minutes }

    FileView {
        path: root.home + "/.config/unia-breathe/calendar.url"
        watchChanges: true
        printErrors: false
        onLoaded: { root.configured = text().trim() !== ""; fetch.running = true }
        onLoadFailed: root.configured = false
        onFileChanged: reload()
    }

    FileView {
        id: cache
        path: root.home + "/.cache/unia-breathe/events.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try { root.list = JSON.parse(text()).map(e => ({ start: new Date(e.start), allDay: e.allDay, title: e.title })) }
            catch (e) { root.list = [] }
        }
    }

    Process { id: fetch; command: [root.home + "/.local/bin/unia-calendar"] }
    Timer { interval: 15 * 60 * 1000; repeat: true; running: root.configured; onTriggered: fetch.running = true }
}
