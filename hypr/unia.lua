-- Unia Breathe Desktop: Hyprland rules for the shell (Hyprland 0.57+, Lua config).
-- Loaded from ~/.config/hypr/hyprland.lua with dofile("…/unia-breathe/hypr/unia.lua"), as install.sh adds it.

-- Glass: blur under every shell surface (the unia-* namespace)
hl.layer_rule({
    name         = "unia-glass",
    match        = { namespace = "^(unia-.*)$" },
    blur         = true,
    ignore_alpha = 0.2,
})

-- The shell's tooltips (xdg-popup) are blurred too
hl.config({ decoration = { blur = { popups = true } } })

-- The shell
hl.on("hyprland.start", function() hl.exec_cmd("qs -c unia") end)

-- Settings: the shell's own windows (titled "Unia · …") live on the settings special workspace
hl.window_rule({
    name      = "unia-settings",
    match     = { title = "^(Unia · .*)$" },
    float     = true,
    workspace = "special:settings silent",
    rounding  = 26,
    no_shadow = true,
})

-- WindowDrop: the "place", a translucent empty window that shows where a dragged window will land.
-- It is tiled like any window (neighbours make room), opens on a hidden desk, takes no focus (focusing a window on
-- a hidden desk would reveal the whole desk), and has no border, shadow or wobble
hl.window_rule({
    name             = "unia-drop-place",
    match            = { title = "^(unia-drop-place)$" },
    tile             = true,
    workspace        = "special:unia-drop silent",
    no_initial_focus = true,
    no_focus         = true,
    border_size      = 0,
    no_shadow        = true,
    no_wobble        = true,
    rounding         = 14,
    opacity          = "1.0 override 1.0 override",
})

-- ---------- Unia Breathe Desktop theme: window borders in the emerald palette (theme colours from Settings override them) ----------
hl.config({
    general = {
        col = {
            active_border   = { colors = { "rgba(10b981ee)", "rgba(13eca499)" }, angle = 45 },
            inactive_border = "rgba(eaf6f01a)",
        },
    },
    decoration = { shadow = { color = "rgba(00000066)" } },
})

-- Changes from the shell's own settings pages: loaded last, so they override the main config
local settings = os.getenv("HOME") .. "/.config/unia-breathe/hyprland.lua"
local f = io.open(settings, "r")
if f then
    f:close()
    dofile(settings)
end
