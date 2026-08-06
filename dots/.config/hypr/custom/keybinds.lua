-- This file will not be overwritten across dots-hyprland updates.
-- The file name is for the sake of organization and does not matter
-- See the corresponding files in ~/.config/hypr/hyprland for examples
--
-- hl.bind(
--   "SUPER + CTRL + SHIFT + Minus",
--   hl.dsp.exec_cmd("kill $(pgrep quickshell) || qs -c $qsConfig"),
--   { description = "Toggle shell" }
-- )

-- hl.bind("SUPER + Tab", hl.dsp.global("quickshell:searchToggle"))

-- Quickshell / session
-- hl.bind("SUPER + SHIFT + Escape", hl.dsp.global("quickshell:sessionOpen"))
-- hl.bind("SUPER + Escape", hl.dsp.exec_cmd("hyprctl reload"))

-- Focus
hl.bind("SUPER + H", hl.dsp.focus({ direction = "l" }))
hl.bind("SUPER + J", hl.dsp.focus({ direction = "d" }))
hl.bind("SUPER + K", hl.dsp.focus({ direction = "u" }))
hl.bind("SUPER + L", hl.dsp.focus({ direction = "r" }))

-- Move window in direction
hl.bind("SUPER + SHIFT + H", hl.dsp.window.move({ direction = "l" }))
hl.bind("SUPER + SHIFT + J", hl.dsp.window.move({ direction = "d" }))
hl.bind("SUPER + SHIFT + K", hl.dsp.window.move({ direction = "u" }))
hl.bind("SUPER + SHIFT + L", hl.dsp.window.move({ direction = "r" }))

hl.bind("SUPER + O", hl.dsp.exec_cmd(Terminal))
