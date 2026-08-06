inputs:

{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.aether;
in
{
  config = lib.mkIf cfg.enable {
    # Environment variables for Illogical Impulse
    home.sessionVariables = {
      AETHER_DOTFILES_SOURCE = "${config.home.homeDirectory}/.config";
      AETHER_VIRTUAL_ENV = "${config.home.homeDirectory}/.local/state/quickshell/.venv";
      qsConfig = "${config.home.homeDirectory}/.config/quickshell/${cfg.qsConfig}";
    };

    # Ensure variables are available to systemd services (and Hyprland)
    systemd.user.sessionVariables = config.home.sessionVariables;
  };
}
