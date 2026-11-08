{
  description = "Aether - Home-manager module for strtab's Hyprland dotfiles with QuickShell";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    quickshell.url = "github:outfoxxed/quickshell?tag=v0.3.2";
    quickshell.inputs.nixpkgs.follows = "nixpkgs";

    hyprland.url = "github:hyprwm/Hyprland?ref=v0.56.1";
    hyprland-plugins.url = "github:hyprwm/hyprland-plugins?ref=v0.56.0";
    hyprland-plugins.inputs.hyprland.follows = "hyprland";
    hyblock.url = "github:strtab/hyblock?ref=v0.56.0";
    hyblock.inputs.hyprland.follows = "hyprland";

    dotfiles = {
      url = "github:strtab/aether";
      flake = false;
    };
  };

  outputs =
    {
      self,
      quickshell,
      dotfiles,
      hyprland,
      ...
    }:
    let
      flakeInputs = { inherit quickshell dotfiles hyprland; };
    in
    {
      # Home-manager module for user configuration
      homeManagerModules.default =
        {
          config,
          lib,
          pkgs,
          ...
        }:
        (import ./home.nix) {
          inherit config lib pkgs;
          inputs = flakeInputs;
        };
      homeManagerModules.illogical-flake = self.homeManagerModules.default;
    };
}
