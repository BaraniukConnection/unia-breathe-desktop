# Unia Breathe Desktop components

Parts planned as standalone components (not only inside Unia Breathe Desktop).
They are developed on the `components` branch, and the shell uses them on `main`.

| Component | What it is | Scripts | Takes from the shell |
|---|---|---|---|
| `tile-menu/` | **TileMenu**: the app menu with search, folders of tiles, All Apps and favourites (`Apps`, `Menu`) | none | `theme/`, `services/` (Popups, Media, Events, Prefs, Windows), `settings-box` |
| `settings-box/` | **SettingsBox**: settings with a category panel, apps on the right and built-in pages (`Settings`, `HyprOpts`) | none | `theme/`, `services/` (Prefs, Popups), `popups/` |
| `window-drop/` | **WindowDrop**: a drop notch in the middle of a window's top border that grows as the cursor nears. Drag it or use Super+LMB (the window becomes a square, neighbours make room, and a translucent place shows where it will land); its menu minimizes, goes fullscreen, floats, closes, resizes or moves the window to another desk (`Drops`) | none | `theme/`, `services/` (Windows) |
| `scenarios/` | **Scenarios**: desk scenarios that save and reopen window layouts (`Scenarios`) | `bin/unia-scenario` | `theme/`, `services/` (Popups, Windows), `popups/` |

To take a component out on its own, it only needs `theme/` and the services in the right-hand column.
