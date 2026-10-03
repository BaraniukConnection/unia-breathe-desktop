pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Mpris

// Активний плеєр MPRIS: той, що грає, або перший доступний.
Singleton {
    readonly property var players: Mpris.players.values
    readonly property var player: players.find(p => p.isPlaying) ?? players[0] ?? null
    readonly property string title: player ? (player.trackTitle || player.identity) : ""
    readonly property string artist: player ? player.trackArtist : ""
    readonly property string art: player ? player.trackArtUrl : ""
    readonly property string source: player ? player.identity : ""
    // іконка програми-джерела: за desktopEntry плеєра, а якщо його немає — за назвою (Vivaldi не повідомляє)
    readonly property var entry: player ? DesktopEntries.heuristicLookup(player.desktopEntry || player.identity) : null
    readonly property string sourceIcon: entry ? Quickshell.iconPath(entry.icon, true) : ""
}
