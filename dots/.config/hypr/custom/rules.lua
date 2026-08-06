-- This file will not be overwritten across dots-hyprland updates.
-- The file name is for the sake of organization and does not matter
-- See the corresponding files in ~/.config/hypr/hyprland for examples

-- Disable shadows for tiled windows
-- hl.window_rule({ match = { float = 0 }, no_shadow = true })

-- Disable blur for every windows
-- hl.window_rule({ match = { class = ".*" }, no_blur = true })

-- Enable float mode for every window
-- hl.window_rule({ match = { class = ".*" }, max_size = { "(monitor_w*0.9)", "(monitor_h*0.9)" }, focus_on_activate = true })

hl.window_rule({ match = { class = "org.nomacs.ImageLounge" }, float = true })
hl.window_rule({ match = { class = "^(.*)(blueman)(.*)$" }, float = true })
hl.window_rule({ match = { class = "^(org.gnome)(.*)$" }, float = true })
hl.window_rule({ match = { class = "Mojosetup" }, float = true })
hl.window_rule({ match = { class = "swappy" }, float = true })
hl.window_rule({ match = { class = "anki" }, float = true })
hl.window_rule({ match = { class = "feh" }, float = true })

hl.layer_rule({ match = { class = "vicinae" }, no_anim = true })

hl.window_rule({ match = { class = "^(kitty)$" }, size = { "820", "500" } })
hl.window_rule({ match = { class = "nwg-look" }, size = { "1000", "700" }, float = true })
hl.window_rule({ match = { class = "org.kde.easyeffects" }, size = { "840", "550" }, float = true })
hl.window_rule({ match = { title = "Home — Dolphin" }, size = { "840", "550" }, float = true })
hl.window_rule({ match = { title = "^(Add Non-Steam Game)$" }, size = { "840", "550" }, float = true })

hl.window_rule({ match = { class = "org.kde.dolphin" }, max_size = { "(monitor_w*0.8)", "(monitor_h*0.8)" }, float = true })
hl.window_rule({ match = { class = "mpv" }, max_size = {"(monitor_w*0.8)", "(monitor_h*0.8)"}, float = true })

-- Chrome
hl.window_rule({ match = { class = "^(.*)(chrome)(.*)$", title = "^(Untitled)(.*)$" }, float = true })
hl.window_rule({ match = { class = "^(.*)(chrome)(.*)$", title = "^(_)(.*)$" }, float = true })

-- Helium
hl.window_rule({ match = { class = "^(.*)(helium)(.*)$", title = "^(Untitled)(.*)$" }, float = true })
hl.window_rule({ match = { class = "^(.*)(helium)(.*)$", title = "^(_)(.*)$" }, float = true })
