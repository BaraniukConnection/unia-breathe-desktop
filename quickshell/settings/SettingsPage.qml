import QtQuick
import Quickshell
import "../theme"
import "../services"
import "pages"

// Власна сторінка налаштування (праворуч від панелі): час, розкладка, прозорість, вікна, мишка.
FloatingWindow {
    id: win
    title: "Unia · Сторінка"
    color: "transparent"
    visible: !!Settings.current && Settings.current.kind === "own"
    implicitWidth: 900
    implicitHeight: 800

    Component { id: pTime; TimePage {} }
    Component { id: pLayout; LayoutPage {} }
    Component { id: pOpacity; OpacityPage {} }
    Component { id: pBorders; BordersPage {} }
    Component { id: pMouse; MousePage {} }

    Glass {
        anchors.fill: parent
        radius: 26

        Loader {
            anchors.fill: parent
            anchors.margins: 6
            active: win.visible
            sourceComponent: {
                switch (Settings.sel) {
                case "time": return pTime
                case "layout": case "kb-layout": return pLayout
                case "opacity": return pOpacity
                case "borders": return pBorders
                case "mouse": return pMouse
                }
                return null
            }
        }
    }
}
