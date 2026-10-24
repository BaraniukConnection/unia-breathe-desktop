import QtQuick
import Quickshell
import "../../theme"
import "../../services"
import "pages"

// Власна сторінка налаштування (праворуч від панелі): час, розкладка, тема, вікна, мишка.
FloatingWindow {
    id: win
    title: "Unia · Сторінка"
    color: "transparent"
    visible: !!Settings.current && Settings.current.kind === "own"
    implicitWidth: 900
    implicitHeight: 800

    // закрили ззовні (Super+C) — закриваємо налаштування; прив'язку видимості повертаємо,
    // лише коли налаштування знову відкриють (інакше нове вікно саме показало б їх)
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

    // Tab з панелі — фокус на перший елемент сторінки
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
    // елемент у фокусі має бути видно — прокручуємо сторінку до нього
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
            Keys.onEscapePressed: Settings.focusPanel()       // назад до списку категорій
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
