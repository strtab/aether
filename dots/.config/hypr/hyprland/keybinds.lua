require("hyprland.lib")
require("hyprland.variables")
if is_file_exists(HOME .. "/.config/hypr/custom/variables.lua") then
  require("custom.variables")
end

local qsScripts = "$HOME/.config/quickshell/$qsConfig/scripts"
local hyprScripts = "$HOME/.config/hypr/hyprland/scripts"
local qsIpcCall = "qs -c $qsConfig ipc call"
local qsIsAlive = qsIpcCall .. " TEST_ALIVE"

hl.bind("SUPER_L", hl.dsp.global("quickshell:superDown"), { ignore_mods = true, transparent = true })
hl.bind("SUPER_R", hl.dsp.global("quickshell:superDown"), { ignore_mods = true, transparent = true })
hl.bind(
  "SUPER_L",
  hl.dsp.global("quickshell:superDown"),
  { ignore_mods = true, transparent = true, release = true }
)
hl.bind(
  "SUPER_R",
  hl.dsp.global("quickshell:superDown"),
  { ignore_mods = true, transparent = true, release = true }
)

hl.bind("SUPER + Space", hl.dsp.global("quickshell:searchToggle"), { description = "Shell: Toggle search" })
hl.bind("SUPER + Space", hl.dsp.exec_cmd(qsIsAlive .. " || pkill fuzzel || fuzzel"))

hl.bind("SUPER + CTRL + V", hl.dsp.global("quickshell:searchClipboardToggle"))
hl.bind("SUPER + A", hl.dsp.global("quickshell:sidebarRightToggle"), { description = "Shell: Toggle sidebar" })
hl.bind("SUPER + B", hl.dsp.global("quickshell:sidebarRightToggle"))
hl.bind("SUPER + N", hl.dsp.global("quickshell:notificationsToggle"))
hl.bind("SUPER + Slash", hl.dsp.global("quickshell:cheatsheetToggle"), { description = "Shell: Toggle cheatsheet" })
-- hl.bind("SUPER + M", hl.dsp.global("quickshell:mediaControlsToggle"), { description = "Shell: Toggle media controls" })

hl.bind(
  "SUPER + SHIFT + Escape",
  hl.dsp.global("quickshell:sessionOpen"),
  { description = "Shell: Toggle session menu" }
)
hl.bind("CTRL + ALT + Delete", hl.dsp.global("quickshell:sessionToggle"))
hl.bind("CTRL + ALT + Delete", hl.dsp.exec_cmd(qsIsAlive .. " || pkill wlogout || wlogout -p layer-shell"))

hl.bind(
  "XF86MonBrightnessUp",
  hl.dsp.exec_cmd(qsIpcCall .. " brightness increment || brightnessctl s 1%+"),
  { locked = true, repeating = true }
)
hl.bind(
  "XF86MonBrightnessDown",
  hl.dsp.exec_cmd(qsIpcCall .. " brightness decrement || brightnessctl s 1%-"),
  { locked = true, repeating = true }
)
hl.bind(
  "XF86AudioRaiseVolume",
  hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 1%+ -l 1.5"),
  { locked = true, repeating = true }
)
hl.bind(
  "XF86AudioLowerVolume",
  hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 1%-"),
  { locked = true, repeating = true }
)

hl.bind(
  "CTRL + SUPER + W",
  hl.dsp.global("quickshell:wallpaperSelectorToggle"),
  { description = "Shell: Change wallpaper" }
)
hl.bind(
  "CTRL + SUPER + ALT + W",
  hl.dsp.global("quickshell:wallpaperSelectorRandom"),
  { description = "Shell: Random wallpaper" }
)
hl.bind("CTRL + SUPER + W", hl.dsp.exec_cmd(qsIsAlive .. " || " .. qsScripts .. "/colors/switchwall.sh"))

--##! Utilities
--# Screenshot, Record, OCR, Color picker, Clipboard history
hl.bind(
  "SUPER + CTRL + V",
  hl.dsp.exec_cmd(
    qsIsAlive .. " || pkill fuzzel || cliphist list | fuzzel --match-mode fzf --dmenu | cliphist decode | wl-copy"
  ),
  { description = "Utilities: Clipboard history >> clipboard" }
)
hl.bind("SUPER + CTRL + S", hl.dsp.global("quickshell:regionScreenshot"), { description = "Utilities: Screen snip" })
hl.bind(
  "SUPER + CTRL + S",
  hl.dsp.exec_cmd(qsIsAlive .. " || pidof slurp || hyprshot --freeze --clipboard-only --mode region --silent")
)
hl.bind("SUPER + SHIFT + A", hl.dsp.global("quickshell:regionSearch"), { description = "Utilities: Google Lens" })
hl.bind("SUPER + SHIFT + A", hl.dsp.exec_cmd(qsIsAlive .. " || pidof slurp || " .. hyprScripts .. "/snip_to_search.sh"))
-- hl.bind("SUPER + SHIFT + L", hl.dsp.global("quickshell:regionSearch"))
-- hl.bind("SUPER + SHIFT + L", hl.dsp.exec_cmd(qsIsAlive .. " || pidof slurp || " .. hyprScripts .. "/snip_to_search.sh"))
--# OCR
hl.bind(
  "SUPER + SHIFT + X",
  hl.dsp.global("quickshell:regionOcr"),
  { description = "Utilities: Character recognition >> clipboard" }
)
hl.bind(
  "SUPER + SHIFT + X",
  hl.dsp.exec_cmd(
    qsIsAlive
    ..
    " || pidof slurp || grim -g \"$(slurp $SLURP_ARGS)\" \"/tmp/ocr_image.png\" && tesseract \"/tmp/ocr_image.png\" stdout -l $(tesseract --list-langs | awk 'NR>1{print $1}' | tr '\\\\n' '+' | sed 's/\\\\+$/\\\\n/') | wl-copy && rm \"/tmp/ocr_image.png\""
  )
)
--# Color picker
hl.bind(
  "SUPER + CTRL + C",
  hl.dsp.exec_cmd("hyprpicker -a"),
  { description = "Utilities: Pick color #RRGGBB >> clipboard" }
)
--# Recording stuff
hl.bind(
  "SUPER + SHIFT + CTRL + R",
  hl.dsp.global("quickshell:regionRecord"),
  { locked = true, description = "Utilities: Record region (no sound)" }
)
hl.bind(
  "SUPER + SHIFT + CTRL + R",
  hl.dsp.exec_cmd(qsIsAlive .. " || " .. qsScripts .. "/videos/record.sh"),
  { locked = true }
)

hl.bind(
  "SUPER + CTRL + ALT + R",
  hl.dsp.exec_cmd(qsScripts .. "/videos/record.sh --fullscreen"),
  { locked = true, description = "Utilities: Record screen (no sound)" }
)
hl.bind(
  "SUPER + SHIFT + R",
  hl.dsp.exec_cmd(qsScripts .. "/videos/record.sh --fullscreen --sound"),
  { locked = true, description = "Utilities: Record screen (with sound)" }
)

--# Fullscreen screenshot
local grimhyprctl = "grim -o \"$(hyprctl activeworkspace -j | jq -r '.monitor')\""
hl.bind(
  "CTRL + Print",
  hl.dsp.exec_cmd(
    grimhyprctl
    .. " - | wl-copy && "
    .. "notify-send -a 'System' -t 1200 'Screenshot Copied' "
  ),
  { locked = true, description = "Utilities: Screenshot >> clipboard" }
)
hl.bind(
  "Print",
  hl.dsp.exec_cmd(
    "mkdir -p $(xdg-user-dir PICTURES)/Screenshots && "
    .. "SCREENSHOT_PATH=$(xdg-user-dir PICTURES)/Screenshots/Screenshot_\"$(date '+%Y-%m-%d_%H.%M.%S')\".png; "
    .. grimhyprctl
    .. " $SCREENSHOT_PATH && "
    .. "notify-send -a 'System' -t 1200 'Screenshot Saved' \"$SCREENSHOT_PATH\" "
  ),
  { locked = true, non_consuming = true, description = "Utilities: Screenshot >> clipboard & file" }
)

--##! Screen
--# Zoom
local function zoomfunction(value)
  local zoomvalue = hl.get_config("cursor:zoom_factor")
  if (zoomvalue + value) > 3.0 then
    hl.config({ cursor = { zoom_factor = 3.0 } })
  elseif (zoomvalue + value) < 1.0 then
    hl.config({ cursor = { zoom_factor = 1.0 } })
  else
    hl.config({ cursor = { zoom_factor = zoomvalue + value } })
  end
end
hl.bind("SUPER + Minus", function()
  zoomfunction(-0.3)
end, { repeating = true, description = "Screen: Zoom out" })
hl.bind("SUPER + Plus", function()
  zoomfunction(0.3)
end, { repeating = true, description = "Screen: Zoom in" })

--# Zoom with keypad
hl.bind("SUPER + code:82", function()
  zoomfunction(-0.3)
end, { repeating = true })
hl.bind("SUPER + code:86", function()
  zoomfunction(0.3)
end, { repeating = true })

--##! Media
local mediaNextCommand = 'playerctl next || playerctl position `bc <<< "100 * $(playerctl metadata mpris:length) / 1000000 / 100"`'
hl.bind("XF86AudioNext", hl.dsp.exec_cmd(mediaNextCommand), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_SINK@ toggle"), { locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_SOURCE@ toggle"), { locked = true })

--#!
--##! Window
--# Focusing
hl.bind("SUPER + mouse:272", function()
  local win = hl.get_active_window()
  if win ~= nil and win.floating == true and win.fullscreen == false then
    hl.dispatch(hl.dsp.window.drag())
  end
end, { mouse = true, description = "Window: Move" })

hl.bind("SUPER + mouse:274", function ()
  local win = hl.get_active_window()
  if win ~= nil and win.floating == true and win.fullscreen == false then
    hl.dispatch(hl.dsp.window.drag())
  end
end, { mouse = true })

hl.bind("SUPER + mouse:273", function ()
   local win = hl.get_active_window()
  if win ~= nil and win.floating == true and win.fullscreen == false then
    hl.dispatch(hl.dsp.window.resize())
  end
end, { mouse = true, description = "Window: Resize" })

--#/# bind = SUPER + ←/↑/→/↓,, -- Focus in direction
for i = 1, 4 do
  local arrowkey = { "Left", "Right", "Up", "Down" }
  local focusdir = { "l", "r", "u", "d" }
  hl.bind(
    "SUPER + " .. arrowkey[i],
    hl.dsp.focus({ direction = focusdir[i] }),
    { description = "Window: Focus " .. arrowkey[i] }
  )
end
for i = 1, 2 do
  local arrowkey = { "BracketLeft", "BracketRight" }
  local focusdir = { "l", "r" }
  hl.bind("SUPER + " .. arrowkey[i], hl.dsp.focus({ direction = focusdir[i] }))
end
--#/# bind = SUPER + SHIFT, ←/↑/→/↓,, -- Move in direction
for i = 1, 4 do
  local arrowkey = { "Left", "Right", "Up", "Down" }
  local focusdir = { "l", "r", "u", "d" }
  hl.bind(
    "SUPER + SHIFT + " .. arrowkey[i],
    hl.dsp.window.move({ direction = focusdir[i] }),
    { description = "Window: Move " .. arrowkey[i] }
  )
end

hl.bind("SUPER + Q", hl.dsp.window.close(), { description = "Window: Close" })

--# Window split ratio
--#/# binde = SUPER, ;/',, -- Adjust split ratio
hl.bind("SUPER + Semicolon", hl.dsp.layout("splitratio -0.1"), { repeating = true })
hl.bind("SUPER + Apostrophe", hl.dsp.layout("splitratio +0.1"), { repeating = true })
--# Positioning mode
hl.bind("SUPER + V", hl.dsp.window.float({ action = "toggle" }), { description = "Window: Float/Tile" })
hl.bind("SUPER + C", hl.dsp.window.center(), { description = "Window: Move to center" })
hl.bind(
  "SUPER + M",
  hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }),
  { description = "Window: Maximize" }
)
hl.bind(
  "SUPER + F",
  hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }),
  { description = "Window: Fullscreen" }
)
hl.bind(
  "SUPER + ALT + F",
  hl.dsp.window.fullscreen_state({ internal = 0, client = 3, action = "toggle" }),
  { description = "Window: Fullscreen spoof" }
)
hl.bind("SUPER + P", hl.dsp.window.pin(), { description = "Window: Pin" })

--#/# bind = SUPER+SHIFT, Hash,, -- Move to workspace -- (1, 2, 3,...)
for i = 1, 10 do
  local numberkey = { 10, 11, 12, 13, 14, 15, 16, 17, 18, 19 }
  hl.bind("SUPER + SHIFT + code:" .. numberkey[i], function()
    hl.dispatch(hl.dsp.window.move({ workspace = workspace_in_group(i) }))
  end)
end

--#/# bind = SUPER+ALT, Hash,, -- Send to workspace -- (1, 2, 3,...)
for i = 1, 10 do
  hl.bind("SUPER + ALT + " .. (i % 10), function()
    hl.dispatch(hl.dsp.window.move({ workspace = workspace_in_group(i), follow = false }))
  end, { description = "Window: Send to workspace " .. i })
end
--# We also use raw keycodes because some keyboard layouts register number keys as different chars. The codes can be verified with `wev`
for i = 1, 10 do
  local numberkey = { 10, 11, 12, 13, 14, 15, 16, 17, 18, 19 }
  hl.bind("SUPER + ALT + code:" .. numberkey[i], function()
    hl.dispatch(hl.dsp.window.move({ workspace = workspace_in_group(i), follow = false }))
  end)
end
--# keypad numbers
for i = 1, 10 do
  local numpadkey = { 87, 88, 89, 83, 84, 85, 79, 80, 81, 90 }
  hl.bind("SUPER + ALT + code:" .. numpadkey[i], function()
    hl.dispatch(hl.dsp.window.move({ workspace = workspace_in_group(i), follow = false }))
  end)
end

--##! Workspace
--# Switching
--#/# bind = SUPER, Hash,, -- Focus workspace -- (1, 2, 3,...)
for i = 1, 10 do
  hl.bind("SUPER + " .. (i % 10), function()
    hl.dispatch(hl.dsp.focus({ workspace = workspace_in_group(i) }))
  end, { description = "Workspace: Focus " .. i })
end
--# We also use raw keycodes because some keyboard layouts register number keys as different chars. The codes can be verified with `wev`
for i = 1, 10 do
  local numberkey = { 10, 11, 12, 13, 14, 15, 16, 17, 18, 19 }
  hl.bind("SUPER + code:" .. numberkey[i], function()
    hl.dispatch(hl.dsp.focus({ workspace = workspace_in_group(i) }))
  end)
end
--# keypad numbers
for i = 1, 10 do
  local numpadkey = { 87, 88, 89, 83, 84, 85, 79, 80, 81, 90 }
  hl.bind("SUPER + code:" .. numpadkey[i], function()
    hl.dispatch(hl.dsp.focus({ workspace = workspace_in_group(i) }))
  end)
end

-- #/# bind = CTRL+SUPER, ←/→,, -- Focus left/right
-- #/# bind = CTRL+SUPER+ALT, ←/→,, -- # [hidden] Focus busy left/right
-- for i = 1, 2 do
--   local keys = { "Left", "Right" }
--   local prefix = { "r-", "r+" }
--   local descdir = { "left", "right" }
--   hl.bind(
--     "CTRL + SUPER + " .. keys[i],
--     hl.dsp.focus({ workspace = prefix[i] .. "1" }),
--     { description = "Workspace: Focus " .. descdir[i] }
--   )
-- end
-- for i = 1, 2 do
--   local keys = { "Left", "Right" }
--   local prefix = { "m-", "m+" }
--   hl.bind("CTRL + SUPER + ALT + " .. keys[i], hl.dsp.focus({ workspace = prefix[i] .. "1" }))
-- end
-- for i = 1, 4 do
--   local key = { "BracketLeft", "BracketRight", "Up", "Down" }
--   local prefix = { "-1", "+1", "r-5", "r+5" }
--   hl.bind("CTRL + SUPER + " .. key[i], hl.dsp.focus({ workspace = prefix[i] }))
-- end

--##! Virtual machines
hl.define_submap("virtual-machine", function()
  hl.bind("SUPER + ALT + F1", function()
    local currentsubmap = hl.get_current_submap()
    if currentsubmap == "virtual-machine" then
      hl.dispatch(
        hl.dsp.exec_cmd("notify-send 'Exited Virtual Machine submap' 'Keybinds re-enabled' -a 'Hyprland'")
      )
      hl.dispatch(hl.dsp.submap("reset"))
    elseif currentsubmap == "" then
      hl.dispatch(
        hl.dsp.exec_cmd(
          "notify-send 'Entered Virtual Machine submap' 'Keybinds disabled. hit SUPER+ALT+F1 to escape' -a 'Hyprland'"
        )
      )
      hl.dispatch(hl.dsp.submap("virtual-machine"))
    end
  end, { submap_universal = true })

  -- TODO: fix the mouse unbind in the virtual-machine submap. 
  -- unbind mouse drag/resize to no-op while in this submap
  -- hl.unbind("SUPER + mouse:272")
  -- hl.unbind("SUPER + mouse:274")
  -- hl.unbind("SUPER + mouse:273")
end)

--##! Apps
hl.bind("SUPER + T", hl.dsp.exec_cmd(Terminal), { description = "App: Terminal" })
hl.bind("SUPER + E", hl.dsp.exec_cmd(FileManager), { description = "App: File manager" })
hl.bind("SUPER + I", hl.dsp.exec_cmd(SettingsApp), { description = "App: Settings app" })
