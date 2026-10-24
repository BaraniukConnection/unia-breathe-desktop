# Scenarios

Save a Hyprland desk and open it again. A Quickshell component from [Unia Breathe Desktop](https://github.com/BaraniukConnection/unia-breathe-desktop).

<img src="https://raw.githubusercontent.com/BaraniukConnection/unia-breathe-desktop/main/docs/screenshots/desks.png" alt="Desks and scenarios">

- A scenario remembers which apps were on a desk and where they were.
- Open it and the apps launch and fall back into the same split layout.
- A bubble on the bar shows the current desk's scenario. The wheel scrolls through names and a click opens the chosen one, so a stray scroll never launches anything.
- Scenario cards show a thumbnail of each layout. Click to open, right-click to delete, Save Scenario to keep the current desk.

## Use it

It ships with Unia Breathe Desktop in `quickshell/components/scenarios`.

The work is done by `bin/unia-scenario`, a Python 3 script that also works on its own:

```bash
unia-scenario save Dev       # save the windows on the visible desks
unia-scenario load Dev       # launch the apps and lay them out as they were
unia-scenario list           # all scenarios as JSON
unia-scenario delete Dev
```

Scenarios are stored in `~/.config/hypr/scenarios/<name>.json`. Edit a scenario's `cmd` field by hand if an app needs to be launched differently.

To use the QML part in your own Quickshell config, put this folder at `components/scenarios`, link `bin/unia-scenario` into your `PATH`, and take `theme/`, `popups/Section.qml` and `services/` (Popups, Windows) from Unia Breathe Desktop. Then put `ScenarioBubble { screen: … }` on your bar and `ScenarioSection { screen: … }` in a popup.

## Files

| | |
|---|---|
| `Scenarios.qml` | The list, which scenario is open on which desk, open / save / delete |
| `ScenarioBubble.qml` | The bar bubble |
| `ScenarioSection.qml` | The cards with thumbnails |
| `bin/unia-scenario` | Saving and restoring layouts |

Requires Hyprland 0.56+ and Quickshell 0.2.1+. Licensed under the [Mozilla Public License 2.0](LICENSE).
