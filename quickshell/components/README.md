# Unia Breathe Desktop components

Parts that also live as standalone repositories. They are developed here, and `dev/split-components`
splits each folder, with its history, into its own repository:

- [unia-tile-menu](https://github.com/BaraniukConnection/unia-tile-menu)
- [unia-settings-box](https://github.com/BaraniukConnection/unia-settings-box)
- [unia-window-drop](https://github.com/BaraniukConnection/unia-window-drop)
- [unia-scenarios](https://github.com/BaraniukConnection/unia-scenarios)

| Component | What it is | Scripts | Takes from the shell |
|---|---|---|---|
| `tile-menu/` | **TileMenu**: the app menu with search, folders of tiles, All Apps and favourites (`Apps`, `Menu`) | none | `theme/`, `services/` (Popups, Media, Events, Prefs, Windows), `settings-box` |
| `settings-box/` | **SettingsBox**: settings with a category panel, apps on the right and built-in pages (`Settings`, `HyprOpts`) | none | `theme/`, `services/` (Prefs) |
| `window-drop/` | **WindowDrop**: a drop notch in the middle of a window's top border that grows as the cursor nears. Drag it or use Super+LMB (the window becomes a square, neighbours make room, and a translucent place shows where it will land); its menu minimizes, goes fullscreen, floats, closes, resizes or moves the window to another desk (`Drops`) | none | `theme/`, `services/` (Windows) |
| `scenarios/` | **Scenarios**: desk scenarios that save and reopen window layouts (`Scenarios`) | `bin/unia-scenario` | `theme/`, `services/` (Popups, Windows), `popups/Section.qml` |

To take a component out on its own, it only needs what the right-hand column lists.

To publish changes to the component repositories, run from the repository root:

```bash
dev/split-components          # updates ~/unia-components/unia-<component>, fast-forward
cd ~/unia-components/unia-window-drop && git push
```

The same script replays `oxygen-files/` on top of the Loaf commit named in `oxygen-files/UPSTREAM` and updates
`~/unia-components/oxygen-files`, a clone of the [Oxygen Files fork](https://github.com/BaraniukConnection/OxygenFiles).
