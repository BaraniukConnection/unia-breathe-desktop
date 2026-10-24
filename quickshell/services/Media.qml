pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Mpris

// The active MPRIS player: the one playing, or the first available.
Singleton {
    readonly property var players: Mpris.players.values
    readonly property var player: players.find(p => p.isPlaying) ?? players[0] ?? null
    readonly property string title: player ? (player.trackTitle || player.identity) : ""
    readonly property string artist: player ? player.trackArtist : ""
    readonly property string art: player ? player.trackArtUrl : ""
    readonly property string source: player ? player.identity : ""
    // the source app's icon: from the player's desktopEntry, or by its name when there is none (Vivaldi does not report it)
    readonly property var entry: player ? DesktopEntries.heuristicLookup(player.desktopEntry || player.identity) : null
    readonly property string sourceIcon: entry ? Quickshell.iconPath(entry.icon, true) : ""
}
