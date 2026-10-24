# TileMenu

An app menu of tiles in folders for Quickshell. A component from [Unia Breathe Desktop](https://github.com/BaraniukConnection/unia-breathe-desktop).

<img src="https://raw.githubusercontent.com/BaraniukConnection/unia-breathe-desktop/main/docs/screenshots/menu.png" alt="TileMenu open above the dock">

- Folders of tiles in two columns (one on a narrow screen). Tiles come in four sizes: small, medium, wide and large.
- **Live tiles** show the time, the next calendar event or what is playing.
- Drag tiles between folders, drag whole folders, drop between folders to start a new one. Click a folder's name to rename it.
- New apps land in **Other** by themselves; uninstalled ones disappear.
- Start typing to search, or switch to **All Apps** for the alphabetical list. Five favourites go to the dock.

## Use it

It ships with Unia Breathe Desktop in `quickshell/components/tile-menu`, where the menu opens from the dock or with `qs -c unia ipc call popups toggle menu`.

To use it in your own Quickshell config, put this folder at `components/tile-menu` and take `theme/` and these from Unia Breathe Desktop: `services/` (Popups, Media, Events, Prefs, Windows) and `components/settings-box` (the Settings tile opens it). Then place a `MenuPanel` in a layer-shell window of your own:

```qml
import "components/tile-menu"

MenuPanel { screen: myScreen; maxWidth: 1200; maxHeight: 700 }
```

`Apps` lists the installed apps from their `.desktop` files, and `Menu` keeps the layout and the dock favourites in `~/.config/unia-breathe/menu.json`.

## Files

| | |
|---|---|
| `Apps.qml` | Installed apps, search, launching |
| `Menu.qml` | Folders, tiles, favourites and the grid logic |
| `MenuPanel.qml` | The panel: search, folders, All Apps, the context menu |
| `Folder.qml`, `Tile.qml`, `AppIcon.qml` | A folder, a tile, an app icon |

Requires Quickshell 0.2.1+. Licensed under the [Mozilla Public License 2.0](LICENSE).
