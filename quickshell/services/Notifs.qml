pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

// Our own notification server (instead of SwayNC): history for the panel and pop-up cards.
Singleton {
    id: root
    property bool dnd: false
    property var history: []          // [{ n: Notification, time: Date }], newest first
    property var toasts: []           // the ones shown in the corner right now
    readonly property int count: history.length

    function remove(n) {
        history = history.filter(e => e.n !== n)
        toasts = toasts.filter(e => e.n !== n)
    }
    // entries reach delegates as copies, so compare by the notification itself
    function hideToast(e) { toasts = toasts.filter(x => x.n !== e.n) }
    function dismiss(e) { e.n.dismiss() }               // closed → remove follows
    function clear() { for (const e of history.slice()) e.n.dismiss() }
    function activate(e) {
        const def = Array.from(e.n.actions).find(a => a.identifier === "default")
        if (def) def.invoke()
        else if (e.n.desktopEntry) {
            const app = DesktopEntries.byId(e.n.desktopEntry)
            if (app) app.execute()
        }
        hideToast(e)
    }
    function icon(n) {
        if (n.appIcon) return n.appIcon.startsWith("/") || n.appIcon.startsWith("file:") ? n.appIcon : Quickshell.iconPath(n.appIcon, true) || ""
        const app = n.desktopEntry ? DesktopEntries.byId(n.desktopEntry) : DesktopEntries.heuristicLookup(n.appName)
        return app ? Quickshell.iconPath(app.icon, true) || "" : ""
    }

    NotificationServer {
        keepOnReload: true
        persistenceSupported: true
        actionsSupported: true
        imageSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        onNotification: n => {
            n.tracked = true
            const e = { n: n, time: new Date() }
            root.history = [e, ...root.history]
            n.closed.connect(() => root.remove(n))
            if (!root.dnd || n.urgency === NotificationUrgency.Critical)
                root.toasts = [e, ...root.toasts].slice(0, 3)
        }
    }
}
