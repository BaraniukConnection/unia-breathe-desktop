pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

// Власний сервер сповіщень (замість SwayNC): історія для панелі й спливаючі картки.
Singleton {
    id: root
    property bool dnd: false
    property var history: []          // [{ n: Notification, time: Date }], нові зверху
    property var toasts: []           // ті, що зараз показані у кутку
    readonly property int count: history.length

    function remove(n) {
        history = history.filter(e => e.n !== n)
        toasts = toasts.filter(e => e.n !== n)
    }
    function hideToast(e) { toasts = toasts.filter(x => x !== e) }
    function dismiss(e) { e.n.dismiss() }               // далі спрацює closed → remove
    function clear() { for (const e of history.slice()) e.n.dismiss() }
    function activate(e) {
        const def = e.n.actions.find(a => a.identifier === "default")
        if (def) def.invoke()
        else if (e.n.desktopEntry) {
            const app = DesktopEntries.byId(e.n.desktopEntry)
            if (app) app.execute()
        }
        hideToast(e)
    }
    function icon(n) {
        if (n.appIcon) return n.appIcon.startsWith("/") || n.appIcon.startsWith("file:") ? n.appIcon : Quickshell.iconPath(n.appIcon, true)
        const app = n.desktopEntry ? DesktopEntries.byId(n.desktopEntry) : DesktopEntries.heuristicLookup(n.appName)
        return app ? Quickshell.iconPath(app.icon, true) : ""
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
