{
  pkgs,
  lib,
  inputs,
  ...
}:

let
  inherit (lib) mkEnableOption mkOption types;
in
{
  # Import all sub-modules
  imports = [
    (import ./modules/fonts.nix inputs)
    (import ./modules/packages.nix inputs)
    (import ./modules/qt.nix inputs)
    (import ./modules/environment.nix inputs)
    (import ./modules/dotfiles.nix inputs)
    (import ./modules/hyprland.nix inputs)
  ];

  # Main options for Illogical Impulse
  options.programs.aether = {
    enable = mkEnableOption "Enable the Illogical Impulse Hyprland configuration";

    qsConfig = mkOption {
      type = types.str;
      default = "ii";
    };

    copyQuickShellDots = mkEnableOption "Enable automatic overwriting quickshell dotfiles" // {
      default = true;
    };

    hyprland = {
      package = lib.mkOption {
        type = lib.types.package;
        default = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
        description = "Hyprland package";
      };
      portalPackage = lib.mkOption {
        type = lib.types.package;
        default = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
        description = "xdg-desktop-portal package for Hyprland";
      };
    };

    theme = {
      enable = mkEnableOption "Enable automatic overwriting theme name" // {
        default = true;
      };
      name = mkOption {
        type = types.str;
        default = "kde";
        description = "Qt platform theme name";
      };
      style = mkOption {
        type = types.str;
        default = "Breeze";
        description = "Qt widget style name";
      };
    };

    icons = {
      enable = mkEnableOption "" // {
        default = true;
      };
      dark = mkOption {
        type = types.str;
        default = "Gruvbox-Plus-Dark";
        description = "Name of the icon theme used in dark mode";
      };
      light = mkOption {
        type = types.str;
        default = "Gruvbox-Plus-Light";
        description = "Name of the icon theme used in light mode";
      };
      package = mkOption {
        type = types.nullOr types.package;
        default = null;
        description = "Package providing the icon theme";
      };
    };

    cursor = {
      enable = mkEnableOption "Enable automatic overwriting cursor theme name" // {
        default = true;
      };
      size = mkOption {
        type = types.int;
        default = 24;
        description = "Cursor size";
      };
    };

    # Internal options (not meant to be set by users)
    internal = {
      pythonEnv = mkOption {
        type = types.package;
        internal = true;
        description = "Python environment for QuickShell (internal use only)";
      };
    };
  };
}
