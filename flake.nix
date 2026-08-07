{
  description = "Aether - Home-manager module for strtab's Hyprland dotfiles with QuickShell";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    quickshell.url = "github:outfoxxed/quickshell?tag=v0.3.0";
    quickshell.inputs.nixpkgs.follows = "nixpkgs";

    hyprland.url = "github:hyprwm/Hyprland/5c9377c15f85c50648f35ca5a213754f95b93ca0"; # v0.56.1

    dotfiles = {
      url = "path:.";
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
