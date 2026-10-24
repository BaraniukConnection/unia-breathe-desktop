import QtQuick
import Quickshell
import "../../theme"
import "../../services"
import "pages"

// The shell's own settings page (right of the panel): time, layout, theme, windows, mouse.
FloatingWindow {
    id: win
    title: "Unia · Page"
    color: "transparent"
    visible: !!Settings.current && Settings.current.kind === "own"
    implicitWidth: 900
    implicitHeight: 800

    // closed from outside (Super+C): close Settings; the visibility binding comes back
    // only when Settings opens again (otherwise the new window would show Settings by itself)
    property bool gone: false
    onClosed: { gone = true; Settings.close() }
    Connections {
        target: Settings
        function onShownChanged() {
            if (!Settings.shown || !win.gone) return
            win.gone = false
            win.visible = false
            win.visible = Qt.binding(() => !!Settings.current && Settings.current.kind === "own")
        }
    }

    Component { id: pTime; TimePage {} }
    Component { id: pLayout; LayoutPage {} }
    Component { id: pTheme; ThemePage {} }
    Component { id: pBorders; BordersPage {} }
    Component { id: pMouse; MousePage {} }

    // Tab from the panel: focus the first control on the page
    Connections {
        target: Settings
        function onPageFocusRequested() {
            Qt.callLater(() => {
                if (!loader.item) return
                const f = loader.item.nextItemInFocusChain(true)
                if (f) f.forceActiveFocus()
            })
        }
    }
    // the focused control must be visible: scroll the page to it
    Item {
        readonly property Item focused: win.contentItem ? win.contentItem.Window.activeFocusItem : null
        onFocusedChanged: {
            const pg = loader.item
            if (!focused || !pg || !pg.contentItem) return
            const y = focused.mapToItem(pg.contentItem, 0, 0).y
            if (y < pg.contentY + 20) pg.contentY = Math.max(0, y - 40)
            else if (y + focused.height > pg.contentY + pg.height - 20)
                pg.contentY = Math.min(pg.contentHeight - pg.height, y + focused.height - pg.height + 40)
        }
    }

    Glass {
        anchors.fill: parent
        radius: 26

        Loader {
            id: loader
            anchors.fill: parent
            anchors.margins: 6
            active: win.visible
            focus: true
            Keys.onEscapePressed: Settings.focusPanel()       // back to the category list
            sourceComponent: {
                switch (Settings.sel) {
                case "time": return pTime
                case "layout": case "kb-layout": return pLayout
                case "theme": return pTheme
                case "borders": return pBorders
                case "mouse": return pMouse
                }
                return null
            }
        }
    }
}
