- **QuickShell**: Qt6-based desktop shell with Clean Design
- **Dynamic Theming**: Automatic color palette generation from wallpapers via matugen and kde-material-you-colors
- **Complete UI**: Menubar, sidebars, lock screen, logout menu
- **Power Management**: hypridle, hyprlock, hyprsunset
- **Tools**: fuzzel launcher, wlogout, hyprshot, hyprpicker, and more
- **Python Environment**: Pre-configured for wallpaper analysis scripts
- **Qt/QML Modules**: Complete Qt6 setup including QtPositioning

## Prerequisites

Configure these at the system level in `configuration.nix`:

```nix
services.geoclue2.enable = true;       # for QtPositioning
networking.networkmanager.enable = true;
services.upower.enable = true;         # for battery status

xdg = {
  portal.enable = true;
  portal.extraPortals = with pkgs; [
    xdg-desktop-portal-gnome
    xdg-desktop-portal-gtk
    xdg-desktop-portal-wlr
    kdePackages.xdg-desktop-portal-kde
  ];
};

environment.sessionVariables = {
  XDG_DATA_DIRS = [
    "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}"
  ];
};

# for brightness control via DDC/CI
users.users.yourusername.extraGroups = [ "i2c" ];
environment.systemPackages = with pkgs; [ i2c-tools ];
hardware.i2c.enable = true;

boot = {
  extraModulePackages = [ config.boot.kernelPackages.ddcci-driver ];
  kernelModules = [ "i2c_dev" "ddcci_backlight" ];
};

services.udev.extraRules = ''
  SUBSYSTEM=="i2c-dev", KERNEL=="i2c-[0-9]*", ATTRS{class}=="0x030000", TAG+="uaccess"
  SUBSYSTEM=="dri", KERNEL=="card[0-9]*", TAG+="uaccess"
'';
```

## Installation

### Minimal Setup

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    illogical-flake = {
      url = "github:soymou/illogical-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, illogical-flake, ... }: {
    homeConfigurations.yourusername = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      modules = [
        illogical-flake.homeManagerModules.default
        {
          programs.aether.enable = true;
        }
      ];
    };
  };
}
```

### Using Your Own Dotfiles Fork

Override the `dotfiles` input to use your own fork:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dotfiles = {
      url = "git+https://github.com/yourusername/aether?submodules=1";
      flake = false;
    };

    illogical-flake = {
      url = "github:soymou/illogical-flake";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.dotfiles.follows = "dotfiles";
    };
  };

  outputs = { nixpkgs, home-manager, illogical-flake, ... }: {
    homeConfigurations.yourusername = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      modules = [
        illogical-flake.homeManagerModules.default
        {
          programs.aether.enable = true;
        }
      ];
    };
  };
}
```

> **Note**: The dotfiles repository uses git submodules for some components (like Material shapes).
> You **must** include `?submodules=1` in the URL to fetch them properly.

Supported flake URL formats:

- GitHub with submodules: `url = "git+https://github.com/owner/repo?submodules=1";`
- Arbitrary git: `url = "git+https://example.com/repo.git?submodules=1";`
- Local path: `url = "path:/home/user/dotfiles";` — ensure submodules are initialized with `git submodule update --init --recursive`

## Configuration Options

### `programs.aether.enable`

**Type**: boolean  
**Default**: `false`

Enables the Illogical Impulse configuration. Must be set to `true` for any other option to take effect.

---

### `programs.aether.icons.enable`

**Type**: boolean  
**Default**: `true`

When enabled, configures GTK icon theme, dconf, kdeglobals, qt5ct/qt6ct, and kde-material-you-colors config with the icon theme names from `icons.dark` and `icons.light`. Disable to manage icon themes manually.

---

### `programs.aether.icons.dark`

**Type**: string  
**Default**: `"Gruvbox-Plus-Dark"`

Name of the icon theme used in dark mode. This string is written into GTK config, kdeglobals, qt5ct/qt6ct, and kde-material-you-colors config. Must match the directory name of an installed icon theme under `~/.local/share/icons` or `/usr/share/icons`.

---

### `programs.aether.icons.light`

**Type**: string  
**Default**: `"Gruvbox-Plus-Light"`

Name of the icon theme used in light mode. Written into kde-material-you-colors config so it can switch themes automatically based on wallpaper brightness. Must match an installed icon theme name.

---

### `programs.aether.icons.package`

**Type**: `package` or `null`  
**Default**: `null`

Package providing the icon theme. When `null`, falls back to the bundled `gruvbox-plus-icons` derivation. Set this to use a custom or nixpkgs icon theme package:

```nix
programs.aether.icons = {
  dark = "Papirus-Dark";
  light = "Papirus-Light";
  package = pkgs.papirus-icon-theme;
};
```

## Credits

- **[end-4](https://github.com/end-4)** — Creator of the Original dotfiles
- **[xBLACKICEx](https://github.com/xBLACKICEx)** — Original NixOS flake
- **[outfoxxed](https://git.outfoxxed.me/outfoxxed/quickshell)** — QuickShell developer
