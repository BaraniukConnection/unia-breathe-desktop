-- Unia Breathe Desktop: example key bindings for the shell (Hyprland 0.57+, Lua config).
-- Not loaded automatically, so it never doubles bindings you already have. Copy what you need into
-- ~/.config/hypr/hyprland.lua, or load the whole file from there:
--   dofile(os.getenv("HOME") .. "/unia-breathe/hypr/binds.example.lua")

local mod = "SUPER"
local function qs(call) return hl.dsp.exec_cmd("qs -c unia ipc call " .. call) end

-- App menu (TileMenu), control centre, desks and scenarios, settings
hl.bind(mod .. " + R", qs("popups toggle menu"))
hl.bind(mod .. " + N", qs("popups toggle nc"))
hl.bind(mod .. " + S", qs("popups toggle ws"))
hl.bind(mod .. " + I", qs("settings toggle"))
-- in Settings: back to the category panel; elsewhere: the next window
hl.bind(mod .. " + Tab", qs("settings back"))

-- Windows
hl.bind(mod .. " + M", qs("windows minimize"))          -- restore with a click on the bar
hl.bind(mod .. " + L", hl.dsp.exec_cmd("loginctl lock-session"))
-- WindowDrop: Super+LMB picks up the window under the cursor (it becomes a square and its landing spot
-- shows in advance); Super+RMB keeps Hyprland's own resize
hl.bind(mod .. " + mouse:272", qs("drop grab"))
hl.bind(mod .. " + mouse:272", qs("drop release"), { release = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Screenshots and screen recording (as in Ubuntu): Print opens the picker,
-- Shift+Print takes the whole screen, Alt+Print the window
hl.bind("Print", qs("shot open"))
hl.bind(mod .. " + Print", qs("shot open"))
hl.bind("SHIFT + Print", qs("shot screen"))
hl.bind("ALT + Print", qs("shot window"))
