inputs:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.aether;

  hypr = cfg.hyprland.package;
  hypr-xdg = cfg.hyprland.portalPackage;

  dotfiles = inputs.dotfiles;
in
{
  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      hyprpicker
      hyprlock
    ];

    wayland.windowManager.hyprland = {
      enable = true;
      systemd.enable = false;
      xwayland.enable = true;
      package = hypr;
      portalPackage = hypr-xdg;
      configType = "lua";

      extraConfig = ''
        -- Internal stuff --
        require("hyprland.lib")
        require("hyprland.services")

        -- Environment variables --
        require("hyprland.env")
        if is_file_exists(HOME .. "/.config/hypr/custom/env.lua") then
          require("custom.env")
        end

        -- Default configurations --
        require("hyprland.execs")
        require("hyprland.general")
        require("hyprland.animations")
        require("hyprland.rules")
        require("hyprland.colors")
        require("hyprland.keybinds")

        -- nwg-displays support --
        if is_file_exists(HOME .. "/.config/hypr/workspaces.lua") then
          require("workspaces")
        end
        if is_file_exists(HOME .. "/.config/hypr/monitors.lua") then
          require("monitors")
        end

        -- Shell overrides --
        if is_file_exists(HOME .. "/.config/hypr/hyprland/shellOverrides/main.lua") then
          require("hyprland.shellOverrides.main")
        end
        if is_file_exists(HOME .. "/.config/hypr/hyprland/shellOverrides/animations.lua") then
          require("hyprland.shellOverrides.animations")
        end

        -- Custom configurations --
        if is_file_exists(HOME .. "/.config/hypr/custom/execs.lua") then
          require("custom.execs")
        end
        if is_file_exists(HOME .. "/.config/hypr/custom/general.lua") then
          require("custom.general")
        end
        if is_file_exists(HOME .. "/.config/hypr/custom/rules.lua") then
          require("custom.rules")
        end
        if is_file_exists(HOME .. "/.config/hypr/custom/keybinds.lua") then
          require("custom.keybinds")
        end
      '';

    };

    services.hypridle = {
      enable = true;
      settings = {
        general = {
          lock_cmd = "hyprctl dispatch 'hl.dsp.global(\"quickshell:lock\")' & pidof qs quickshell hyprlock || hyprlock";
          before_sleep_cmd = "loginctl lock-session";
          after_sleep_cmd = "hyprctl dispatch 'hl.dsp.global(\"quickshell:lockFocus\")'";
        };

        listener = [
          {
            timeout = 600;
            on-timeout = "loginctl lock-session";
          }
          {
            timeout = 900;
            on-timeout = "hyprctl dispatch 'hl.dsp.dpms({ action = \"disable\" })'";
            on-resume = "hyprctl dispatch 'hl.dsp.dpms({ action = \"enable\" })'";
          }
          {
            timeout = 1800;
            on-timeout = "systemctl suspend || loginctl suspend";
          }
        ];
      };
    };

    xdg.configFile."hypr/hyprland/env.lua".source = "${dotfiles}/dots/.config/hypr/hyprland/env.lua";
    xdg.configFile."hypr/hyprland/execs.lua".source =
      "${dotfiles}/dots/.config/hypr/hyprland/execs.lua";
    xdg.configFile."hypr/hyprland/rules.lua".source =
      "${dotfiles}/dots/.config/hypr/hyprland/rules.lua";
    xdg.configFile."hypr/hyprland/general.lua".source =
      "${dotfiles}/dots/.config/hypr/hyprland/general.lua";
    xdg.configFile."hypr/hyprland/keybinds.lua".source =
      "${dotfiles}/dots/.config/hypr/hyprland/keybinds.lua";
    xdg.configFile."hypr/hyprland/variables.lua".source =
      "${dotfiles}/dots/.config/hypr/hyprland/variables.lua";
    xdg.configFile."hypr/hyprland/animations.lua".source =
      "${dotfiles}/dots/.config/hypr/hyprland/animations.lua";
    xdg.configFile."hypr/hyprland/lib/init.lua".source =
      "${dotfiles}/dots/.config/hypr/hyprland/lib/init.lua";
    xdg.configFile."hypr/hyprland/services/init.lua".source =
      "${dotfiles}/dots/.config/hypr/hyprland/services/init.lua";
    xdg.configFile."hypr/hyprland/services/create_custom_config.lua".source =
      "${dotfiles}/dots/.config/hypr/hyprland/services/create_custom_config.lua";

    xdg.configFile."hypr/hyprland/scripts/zoom.sh".source =
      "${dotfiles}/dots/.config/hypr/hyprland/scripts/zoom.sh";
    xdg.configFile."hypr/hyprland/scripts/record.sh".source =
      "${dotfiles}/dots/.config/hypr/hyprland/scripts/record.sh";
    xdg.configFile."hypr/hyprland/scripts/snip_to_search.sh".source =
      "${dotfiles}/dots/.config/hypr/hyprland/scripts/snip_to_search.sh";
    xdg.configFile."hypr/hyprland/scripts/workspace_action.sh".source =
      "${dotfiles}/dots/.config/hypr/hyprland/scripts/workspace_action.sh";
    xdg.configFile."hypr/hyprland/scripts/start_geoclue_agent.sh".source =
      "${dotfiles}/dots/.config/hypr/hyprland/scripts/start_geoclue_agent.sh";
    xdg.configFile."hypr/hyprland/scripts/launch_first_available.sh".source =
      "${dotfiles}/dots/.config/hypr/hyprland/scripts/launch_first_available.sh";

    xdg.configFile."hypr/hyprlock/check-capslock.sh".source =
      "${dotfiles}/dots/.config/hypr/hyprlock/check-capslock.sh";
    xdg.configFile."hypr/hyprlock/status.sh".source =
      "${dotfiles}/dots/.config/hypr/hyprlock/status.sh";
  };
}
