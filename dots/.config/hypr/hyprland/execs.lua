-- put former exec-once commands inside the func and former exec commands outside
hl.on("hyprland.start", function()
  -- Bar, wallpaper
  hl.exec_cmd("$HOME/.config/hypr/hyprland/scripts/start_geoclue_agent.sh")
  hl.exec_cmd("qs -c $qsConfig")

  -- Core components (authentication, lock screen, notification daemon)
  hl.exec_cmd("gnome-keyring-daemon --start --components=secrets --daemonize")
  hl.exec_cmd("dbus-update-activation-environment --all")
  hl.exec_cmd("sleep 1 && dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP") -- Some fix idk
	hl.exec_cmd( "wl-paste --type text --watch bash -c 'cliphist store && qs -c $qsConfig ipc call cliphistService update'")
	hl.exec_cmd( "wl-paste --type image --watch bash -c 'cliphist store && qs -c $qsConfig ipc call cliphistService update'")

  -- Audio
  hl.exec_cmd("easyeffects --hide-window --service-mode")
end)
