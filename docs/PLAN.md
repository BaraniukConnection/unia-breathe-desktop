# Unia Breathe Desktop: the transition plan

Mockup: [`design/unia-breathe.html`](../design/unia-breathe.html) (opens in any browser).
The previous working setup stays in `~/.config` (with its own git) as a fallback until Unia Breathe Desktop is ready.

---

## 0. The idea

| | Before (`~/.config`) | Unia Breathe Desktop |
|---|---|---|
| Top of the screen | one solid waybar strip | separate glass bubbles: left, centre, right, with the wallpaper between them |
| Bottom of the screen | nothing | a dock: 5 round favourite apps + the menu arrow |
| App menu | rofi (a list) | a glass panel of tiles in folders, above the dock |
| Notifications and controls | SwayNC | our own panel under the status bubble |
| Settings | buttons in SwayNC, each opening its own floating window | a separate special workspace: the category panel on the left + the app on the right |
| Scenarios | a rofi menu on Super+S | a "Desks and scenarios" window with layout thumbnails |
| Colours | grey-greens `#8CC1AD` / `#08583A` | deep emerald: ground `#0b2a26`, accent `#10b981`, text `#eaf6f0` |
| Font / icons | Roboto + Nerd Font | **Manrope**; real app icons, **Material Symbols Outlined** for interface icons |

**The glass is the same everywhere:** `rgba(8,30,25,.35)` + blur, a thin light outline `rgba(255,255,255,.14)`, a soft shadow.
Menus and tooltips are denser, `.62`. Corners: bubbles are fully round, windows and panels 20–28 px.

### Decisions made (3 Oct 2026)

1. The base is **Quickshell**.
2. RAM/VRAM readouts: **remove entirely**.
3. Power buttons as in the mockup (shut down, restart, sleep, log out), no "switch user".
4. Icons: **real app icons** (the mockup had placeholders).
5. Search in the menu: **add it**.
6. Calendar: **Google Calendar**.
7. Devices: Logitech Lift gets only the general mouse settings; Logitech G915 backlight through OpenRGB;
   Wacom Intuos S (CTL-4100) through OpenTabletDriver.

### What to build on

Waybar + SwayNC + rofi cannot carry this mockup: it needs popups with a calendar and a track cover,
draggable tiles, and the shell's own settings pages. It needs a shell construction kit:

| | **Quickshell** (recommended) | AGS / Astal |
|---|---|---|
| Source | the official Fedora repository | Copr `sdegler/hyprland` |
| Language | QML (+ a little JS) | TypeScript/TSX + GTK4 CSS |
| Animations, dragging tiles | a strong point | possible, but more manual work |
| Hyprland, MPRIS, PipeWire, notifications, Bluetooth | built-in modules | built-in services |
| Closeness to the mockup (HTML/CSS) | styles are rewritten in QML | GTK CSS is very close to the mockup's CSS |

**Quickshell** is recommended: an official package (updated with the system), smooth animations as in the mockup,
tile dragging out of the box. One program replaces waybar, SwayNC, the rofi menu and the dock.

What stays as it is: Hyprland, hyprpaper/waypaper, hyprlock, hypridle, kitty, Thunar, the scenario script
(its logic for saving window geometry is more precise than the mockup's).

---

## 1. The top bar (instead of Waybar)

```
[Scenario · Dev] [Desk · ①]          [ 3 Oct  20:41 ]  [▣ Track title ⏮ ⏸ ⏭]          [⌨ ua 🔊 34% ᛒ Lift 📶 Northtop] [🔔] [⏻]
```

- **No solid strip.** Each group is its own glass pill, 44 px high, 16 px from the top and 20 px from the edge.
  Windows start under the bubbles (about 72 px reserved at the top).
- **Left:** two bubbles, Scenario and Desk (see sections 2–3).
- **Centre:** the clock (section 4) and, a little to the right, media (section 5).
- **Right:** the status bubble (layout, volume, Bluetooth device, Wi-Fi), the bell, the power button.
  - **Hovering** over any part of the status shows a hint: the full layout name / where the sound goes /
    the list of Bluetooth devices / the network and its signal strength.
  - **Mouse wheel:** over volume ±2 %, over the layout switches language, over Bluetooth another device.
  - **A click** on the status or the bell opens the control centre (section 6).
  - The bell: a small mark when there are notifications; struck through in Do Not Disturb.
  - **⏻** opens a menu: Shut Down, Restart, Sleep, Log Out.
- **When space is short** (the narrow 1680 px Dell), labels hide step by step until only icons remain.
- **Only one popup is open at a time**; a click on the desk or Esc closes it.

**What goes away:** waybar entirely, the separate Bluetooth/Wi-Fi modules (now part of the status).

---

## 2. Scenarios

- **The "Scenario · <name>" bubble** shows the current desk's scenario.
  - If you changed the set of windows after opening it, a "changed" mark appears by the name.
  - A desk without a scenario shows "Custom".
- **A click** opens the "Desks and scenarios" window (shared with section 3), its lower half:
  - scenario cards with a **layout thumbnail** (coloured rectangles where the windows sit) and the name;
  - a click on a card opens the scenario on the current desk;
  - right-click offers "Open on This Desk" / "Delete" (with Undo);
  - "Save Scenario" brings up a name field (up to 14 characters) right in the window, no rofi.
- **The "Default" scenario** is an empty desk and cannot be deleted.
- **Under the hood** `scenario.py` stays: it saves exact window geometry and rebuilds the split tree.
  Thumbnails are drawn from the same saved coordinates. Your `OxygenDev.json` moves over unchanged.

⚠️ **A difference from the mockup:** in the mockup the mouse wheel over the bubble switches scenarios. In practice
that would launch and close apps on a stray scroll. Proposal: the wheel only **scrolls through names**,
and a click applies one.

---

## 3. Desks

- **The "Desk · ①" bubble**: the current desk number in a circle.
  - **The mouse wheel** goes to the neighbouring desk (safe, unlike scenarios).
  - **A click** opens the same "Desks and scenarios" window, its upper half: a row of circles numbering the open desks,
    the current one highlighted, "+" for a new desk. A hint over each: its scenario and window count.
- **Rules:** up to 9 desks; an empty desk closes as soon as you leave it (Hyprland does that already);
  two desks always live, one per monitor (1 → DP-2, 2 → HDMI, as set in nwg-displays now).
- **Windows:** up to 6 per desk, sharing space as now (dwindle). 10 px gaps, glass borders, 20 px corners.

---

## 4. Clock and calendar

- **The bubble in the centre:** the date ("3 Oct") + a large time, "20:41".
- **A click** opens a 328 px wide calendar:
  - the month's name, ‹ › arrows to change months, a grid of days, today highlighted;
  - "Next event" at the bottom: the title and when.

**Events come from Google Calendar** through the "Secret address in iCal format" (Google Calendar → Settings for my
calendars → Integrate calendar). A script downloads it every 15 minutes and hands over the upcoming events.
- Read-only: events are not created or edited from the desktop.
- You paste the address into `~/.config/unia-breathe/calendar.url` yourself; this file **never goes into git**
  (the address grants read access to the calendar, like a password).
- Several calendars: one address per line.

---

## 5. Media

- **The bubble next to the clock:** a small round cover, the track title as a scrolling line
  (it slides back and forth if it does not fit), ⏮ ⏸ ⏭ buttons.
- Under the bubble, in small type, **which app is playing** (Vivaldi, Spotify…).
- **A click on the cover or title** opens the media centre: title + artist, a large cover, large controls,
  the audio source.
- The data comes from MPRIS (the same as SwayNC sees now: YouTube in Vivaldi works too).
- Proposal (not in the mockup): when nothing plays, the bubble hides.

---

## 6. Control centre and notifications

It opens under the status bubble, 448 px wide.

1. **Quick tiles** (large, 76 px):
   - **Wi-Fi**: the network name under the label; a click turns it on or off;
   - **Bluetooth**: the connected device (Lift); a click turns it on or off;
   - beside them **6 slots for pinned settings**: any settings category (section 8) can be pinned here.
2. **Volume**: a wide filled slider with a percentage and a mute button.
3. **Notifications**: a list (app icon, title, body, time, ✕) and a Do Not Disturb button.
4. **Bottom:** four round power buttons (shut down, restart, sleep, log out) + an **Open Settings** button.

**What changes from today's SwayNC:**
- the Wi-Fi/Bluetooth/Sound/Displays/Wallpaper/Themes/Printers buttons leave this panel and move into Settings;
- the player moves into the media bubble;
- restart and shut down still ask for confirmation (the mockup does not, but it is safer).

- RAM/VRAM readouts go away entirely (the VRAM script too).
- **Choosing a Wi-Fi network:** in the mockup the tile only turns Wi-Fi on and off. A › arrow on the tile adds the list
  of networks right in the panel.

---

## 7. The app menu (dock + tiles)

**The dock** sits at the bottom centre (376×106 px). **It hides as in Ubuntu:** usually you do not see it; it slides up
when the mouse reaches the bottom edge of the screen (and hides once the mouse leaves and the menu is closed).
- 5 round favourite apps (64 px) in coloured circles;
- under them a ⌃ arrow opens the menu.
- Favourites are added and removed with a right-click on any app.

**The menu panel** rises above the dock, up to 580 px tall:
- **Folders of tiles** in two columns (one on a narrow monitor). Starter folders: Daily, Create, Useful,
  Other (everything unsorted lands there automatically).
- **Tile sizes:** small (just the icon), medium 2×2, wide 4×2, large 4×4; right-click changes the size.
- **Live tiles** (medium and larger): Clock, Calendar, Gallery, Tips show content, not just the icon.
- **Dragging:** tiles between folders and spots, whole folders; dropping in the gap between folders creates a new one;
  a click on a folder's name renames it.
- **Keyboard:** Alt+Shift+arrows move the selected tile.
- At the bottom: "Reset Layout" and the **Tiles / All Apps** switch (the full alphabetical list).
- The app list comes from the system's `.desktop` files, so everything installed shows up by itself.

- **Icons are real app icons** (from the icon theme, as in the `.desktop` files). Material Symbols stay
  only for system interface icons (volume, Wi-Fi, arrows and so on).
- **Search:** open the menu and start typing; a filtered list of apps replaces the tiles,
  Enter launches the first. Super+R opens the menu straight into the search field. Rofi stays for the Wi-Fi script.

---

## 8. Settings (a special workspace)

**How it works:**
- A separate **special workspace, `special:settings`**, slides in over the current desk and hides again.
  It opens with **one key**: Super+I (proposed), "Open Settings" in the control centre, or the Settings tile in the menu.
- **On the left, a fixed-width panel (304 px):** the "Settings" title + ✕, a switch between the sections
  **General / Personalize / Devices**, and the category list (icon, name, which app handles it).
- **On the right, the app takes the rest of the space.** Together with the panel it looks like one window.
- **A click on a category** launches the right app (or shows it if it is already open) and **hides the previous one**.
  Hidden apps are not closed but set aside, so going back to them is instant.

**Categories from the mockup and what opens them:**

| Section | Category | App |
|---|---|---|
| General | Network | nm-connection-editor |
| | Bluetooth | **Overskride** (the mockup has Blueman; we keep your Overskride) |
| | Date & Time | a built-in page (time zone, sync, 24-hour clock) |
| | Sound | pavucontrol |
| | Displays | nwg-displays |
| | Keyboard Layout | a built-in page (languages, the switch key) |
| Personalize | Wallpaper | waypaper |
| | App Theme | nwg-look (GTK); qt6ct for Qt |
| | Theme | a built-in page (window opacity, blur) |
| | Windows & Borders | a built-in page (gaps, borders, rounding) |
| Devices | Mouse (Logitech Lift) | a built-in page: speed, acceleration, natural scrolling, left-handed |
| | Keyboard → language | a built-in page |
| | Keyboard → backlight (G915) | OpenRGB ⬇ |
| | Printers | system-config-printer |
| | Drawing Tablet (Wacom Intuos S) | OpenTabletDriver ⬇ |

⬇: not installed yet. **A built-in page** covers Hyprland's own settings, where no ready app exists:
simple pages with sliders and switches right in the right-hand part, with changes written to a separate
config file. Piper is not needed; the general settings are enough for the Lift.

**OpenTabletDriver and Wacom:** OTD replaces the kernel's `wacom` driver and disables it on install
(otherwise both drivers fight over the tablet). In return it has a GUI: the active area, mapping to a monitor
(DP-2 or HDMI), the pressure curve, the ExpressKeys. It installs from the RPM in its GitHub release (Fedora does not
ship it, and the Flatpak cannot install the udev rules it needs).

---

## 9. Order of work

1. **Base:** Quickshell, the Manrope + Material Symbols fonts, the palette, Hyprland blur rules, the repo layout
   and installation through symlinks into `~/.config` (with a quick way back to the old setup).
2. **The top bar:** bubbles, the status with hints and wheel, the clock, media. Waybar is turned off.
3. **The control centre + notifications.** SwayNC is turned off.
4. **Desks and scenarios** (the window, thumbnails, saving).
5. **Settings** (the special workspace, the category panel, switching apps).
6. **Built-in settings pages.**
7. **The dock and the app menu**, the largest piece: tiles, folders, dragging, live tiles.
8. Repainting the rest to the palette: kitty, Hyprland borders, hyprlock, the GTK theme, Thunar.

Each stage gets its own commits; after each one everything works and is usable.
