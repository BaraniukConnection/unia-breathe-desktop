# SettingsBox

Settings for a Hyprland desktop, in their own space. A Quickshell component from [Unia Breathe Desktop](https://github.com/BaraniukConnection/unia-breathe-desktop).

<img src="https://raw.githubusercontent.com/BaraniukConnection/unia-breathe-desktop/main/docs/screenshots/settings.png" alt="SettingsBox on the Theme page">

- Settings live on a special workspace, `special:settings`, that slides over your desk: a category panel on the left and the right app on the right, laid out as one window.
- Apps you already have open in place (network, Bluetooth, sound, displays, wallpaper, printers…) and hide again when you pick another category.
- **Built-in pages** for what has no app: Date & Time, Keyboard Layout, Theme (accent and secondary colours, window opacity, blur), Windows & Borders, Mouse. Hyprland options change live and are saved to a config Hyprland sources.
- Fully usable from the keyboard: Tab, arrows, Enter, P to pin a category to the control centre, Esc to close.

## Use it

It ships with Unia Breathe Desktop in `quickshell/components/settings-box`.

To use it in your own Quickshell config, put this folder at `components/settings-box` and take `theme/` and `services/Prefs.qml` from Unia Breathe Desktop. Then in `shell.qml`:

```qml
import "components/settings-box"

SettingsPanel {}
SettingsPage {}
IpcHandler {
    target: "settings"
    function toggle(): void { Settings.toggle() }
    function open(id: string): void { Settings.open(id) }
    function back(): void { Settings.focusPanel() }
}
```

Hyprland needs the rules for its windows (the `Unia · …` block in [`hypr/unia.conf`](https://github.com/BaraniukConnection/unia-breathe-desktop/blob/main/hypr/unia.conf)), a line that sources the generated options last:

```ini
source = ~/.config/unia-breathe/hyprland.conf
```

and a key to open it (`unia` is the config name; use yours):

```ini
bind = SUPER, I, exec, qs -c unia ipc call settings toggle
```

The categories and the apps behind them are listed at the top of `Settings.qml`; edit that list to fit your system.

## Files

| | |
|---|---|
| `Settings.qml` | Categories, opening and closing, placing the windows |
| `HyprOpts.qml` | Reads Hyprland options and changes them live |
| `SettingsPanel.qml` | The category panel |
| `SettingsPage.qml` | The window that holds the built-in pages |
| `pages/` | The built-in pages and their controls |

Requires Hyprland 0.56+ and Quickshell 0.2.1+. Licensed under the [Mozilla Public License 2.0](LICENSE).
