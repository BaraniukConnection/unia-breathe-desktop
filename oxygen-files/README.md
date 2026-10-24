# Oxygen Files [loaf fm fork]

The file manager for Unia Breathe Desktop and the Oxygen Theme family: a fork of [Loaf](https://github.com/m-uvex/loaf-fm)
(Rust + Qt6 Quick/QML, Material 3 Expressive) by m_uvex. The author agreed to the fork (in a conversation on Reddit).
The original has no separate license file, but its README states MIT; the original README is `UPSTREAM-README.md`,
and `UPSTREAM` records where and at which commit the code was taken.

The code comes from the original's `dev` branch: the author merges every change there, while `main` sits at the v0.1.0 release.
`dev` already fixes the ties to the author's own system that we found in v0.1.0: standard folders with English
names instead of XDG, "Home" pointing at `/home/m_uvex`, the terminal and system icons only from NixOS paths, "Projects"
and `~/Projects/loaf` among frequent folders.

## Install

It is built from this code against the system Qt 6.11 (the same one Quickshell uses). The ready packages from the Loaf
release do not start on Fedora 44: the tarball, .deb and .pkg are built against a non-system Qt (`Qt_6_PRIVATE_API`),
and the Qt inside the AppImage needs glibc 2.44 (Fedora 44 has 2.43).

```bash
sudo dnf install cargo rust cmake ninja-build gcc-c++ pkgconf-pkg-config qt6-qtbase-devel qt6-qtbase-private-devel qt6-qtdeclarative-devel qt6-qtsvg-devel qt6-qtwayland-devel
./install.sh        # builds if not built yet; installs the oxygen-files command and an "Oxygen Files" menu entry
```

## Changes for Unia Breathe Desktop

- **The "Unia" palette** (the default): the dark one comes from the shell (`quickshell/theme/Theme.qml`: ground `#0b2a26`,
  accent `#10b981`), the light one from Vision DesignSystem. `qml/Theme.qml`, palette `unia`.
- **Glass**: the window ground and the panels are translucent, and Hyprland blurs what is behind the window. Settings → Interface →
  Transparency (Off · Low · Medium · Unia = 0.35, as in the shell). Menus and dialogs stay solid: the blur only acts
  on what is behind the window, not on the content under a menu. `cpp/native.cpp` turns on the alpha buffer. The glass relies
  on blur: when blur is off in Hyprland (in Unia: Theme → Blur), the window goes solid, like the shell's panels.
  Oxygen Files asks Hyprland (`decoration:blur:enabled`, `src/theme.rs`) every 2 s.
- **Manrope** (per Vision DesignSystem) is bundled and set as the application font in `cpp/native.cpp`.
- **The Oxygen Files mark** from Vision DesignSystem (`assets/oxygen-files.svg`): the sidebar header, About, the menu entry.
  The window's `app_id` is `oxygen-files`.
- **Disks** on the This PC page, between Places and Frequent: a card per disk (`qml/components/DiskCard.qml`) with
  a large icon, the name, free space, used / total and a bar. A click opens the disk (or mounts it), right-click opens the disk menu.
  The old Internal / External Storage sections are hidden by default.
- **Custom icons** (as in Kando): right-click a folder, a sidebar item or a disk → Change Icon…
  Sets: the system icon theme, Simple Icons (plain or in brand colours), Material Symbols, emoji,
  your own themes (folders of SVG/PNG in `~/.config/loaf/icon-themes/<theme>/`) and any image by path, URL
  or data: URI. A folder's icon shows in the grid, the list and the sidebar. The sets are bundled (`assets/icon-sets/`), and the choice
  is saved in the settings (`customIcons`).
- The decorative blobs on the ground show only without glass (Transparency: Off).
- The View menu opens under its button: its position was measured from the arrow, not the button (an upstream bug).
- Disks are read right at startup (`src/core.rs`); upstream only reads them after a device change,
  so This PC had no disks after start.


The interface is QML in `qml/` (`Theme.qml` holds colours and tokens, `main.qml` the window, plus `Sidebar.qml`, `FilePane.qml`,
and `components/` for buttons, menus and dialogs); the logic is in `src/` (Rust) and `cpp/`. The QML is compiled into the binary,
so rebuild after changes:

```bash
./build.sh
```

To update the code from upstream: take a fresh `dev` branch, carry the files over and record the commit in `UPSTREAM`.

## Possible upstream contributions

Loaf bugs fixed here that the author may want too. First check that nobody has fixed them on the `dev` branch already
(the user opens a discussion); if not, prepare a PR.

- **Disks are not read at startup** (found on `dev` 8877dc1). `drives_json` starts as `"[]"`, and only two things call
  `load_drives()`: the DeviceWatcher (`src/watcher.rs`) and the end of a disk action (mount, unmount, eject,
  rename: `drive_job` → `reload_drives` in `qml/main.qml`). The DeviceWatcher fires only on an event: a node appeared in or
  vanished from `/dev/disk/by-uuid` (a device was plugged in or removed) or the mount table changed
  (`/proc/self/mountinfo`). There is no initial read, so until one of these happens during the session,
  This PC shows 0 disks: the Internal / External Storage sections do not appear at all, and the System Drive Pool
  is empty. Any mount in the system (a USB stick, a snap, a network drive) and the disks suddenly appear, which looks
  random. The fix is one call, `self.as_mut().load_drives();`, in `initialize()` in `src/core.rs`.
- **Dragging in Customize Sidebar does not work** (`dev` 8877dc1). The ListView takes the motion for scrolling
  (no `preventStealing`), and every `move_place` rebuilds the model's JS array and destroys the row under the mouse. The fix is
  a ListModel with a live `move()` and saving the order on release (`qml/main.qml`, `customizePlaces`).
- **A submenu covers its menu** (`dev` 8877dc1). When there is no room on the right, `LoafPopup.reposition()` shifts the submenu
  by its own width from the row's right edge, that is, onto the parent menu. The fix is `flipRightEdge`: flip it to the left
  of the row's left edge (`openRightOf`).
- **The View menu drifts sideways** (`dev` 8877dc1). In `qml/main.qml` the position is computed with `mapToItem` from the arrow's
  MouseArea instead of `viewDropdownButton`, so the menu is offset by the distance from the button's edge to the arrow. The fix is
  `viewDropdownButton.mapToItem(...)`.
