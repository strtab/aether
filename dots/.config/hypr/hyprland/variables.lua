-- Default variables
-- Copy these to ~/.config/hypr/custom/variables.lua to make changes in a dotfiles-update-friendly manner

-- The folder within ~/.config/quickshell containing the config
hl.env("qsConfig", "aether")

-- Apps
Terminal = "~/.config/hypr/hyprland/scripts/launch_first_available.sh 'kitty -1' 'alacritty' 'foot' 'wezterm' 'konsole' 'kgx' 'uxterm' 'xterm'"
FileManager = "~/.config/hypr/hyprland/scripts/launch_first_available.sh 'dolphin' 'nautilus' 'nemo' 'thunar' 'kitty -1 fish -c yazi'"
Browser = "~/.config/hypr/hyprland/scripts/launch_first_available.sh 'helium' 'google-chrome-stable' 'zen-browser' 'firefox' 'brave' 'chromium' 'microsoft-edge-stable' 'opera' 'librewolf'"
VolumeMixer = "~/.config/hypr/hyprland/scripts/launch_first_available.sh 'pavucontrol-qt' 'pavucontrol'"
SettingsApp = "XDG_CURRENT_DESKTOP=gnome ~/.config/hypr/hyprland/scripts/launch_first_available.sh 'qs -p ~/.config/quickshell/$qsConfig/settings.qml' 'systemsettings' 'gnome-control-center' 'better-control'"

WorkspaceGroupSize = 10
