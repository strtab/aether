inputs:

{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.aether;

  # Python environment for quickshell wallpaper analysis
  pythonEnv = pkgs.python3.withPackages (ps: [
    ps.build
    ps.cffi
    ps.click
    ps."dbus-python"
    ps."kde-material-you-colors"
    ps.libsass
    ps.loguru
    ps."material-color-utilities"
    ps.materialyoucolor
    ps.numpy
    ps.pillow
    ps.psutil
    ps.pycairo
    ps.pygobject3
    ps.pywayland
    ps.setproctitle
    ps."setuptools-scm"
    ps.tqdm
    ps.wheel
    ps."pyproject-hooks"
    ps.opencv4
  ]);
in
{
  # Export pythonEnv for use in other modules
  options.programs.aether.internal.pythonEnv = lib.mkOption {
    type = lib.types.package;
    internal = true;
    default = pythonEnv;
  };

  config = lib.mkIf cfg.enable {
    # User packages for Illogical Impulse
    home.packages = with pkgs; [
      # Core utilities
      cava
      power-profiles-daemon
      lxqt.pavucontrol-qt
      wireplumber
      libdbusmenu-gtk3
      playerctl
      brightnessctl
      ddcutil
      bc
      curl
      rsync
      wget
      libqalculate
      ripgrep
      jq

      # GUI applications
      fuzzel
      matugen
      mpv
      mpvpaper
      wf-recorder
      hyprshot
      wlogout

      # System utilities
      xdg-user-dirs
      tesseract
      upower
      wtype
      ydotool
      glib
      translate-shell
      imagemagick
      ffmpeg
      songrec # Music recognition
      pulseaudio # Provides pactl and parec for audio recording
      gnome-settings-daemon # Provides gsettings
      libnotify # Provides notify-send
      easyeffects

      # Wayland/Hyprland specific
      wayland-protocols
      wayland-utils
      xdg-user-dirs
      hyprsunset
      hyprlock
      hypridle

      # Clipboard
      wl-clipboard
      cliphist

      # Utils for screenshoting
      hyprpicker
      swappy # Image viewer
      slurp
      grim

      # Development libraries
      libsoup_3
      libportal-gtk4
      gobject-introspection
      sassc

      # Themes and icons
      gruvbox-plus-icons
      adw-gtk3

      # Python with required packages for wallpaper analysis
      pythonEnv

      # Minimal Qt/KDE packages (only what's needed for functionality)
      gnome-keyring # Keyring support
      kdePackages.kiconthemes
      kdePackages.kio
      kdePackages.kservice
      kdePackages.kxmlgui
      kdePackages.kconfig
      kdePackages.kcoreaddons
      kdePackages.kwayland
      kdePackages.powerdevil
      kdePackages.kwayland-integration
      kdePackages.plasma-integration
      kdePackages.kdegraphics-thumbnailers
      kdePackages.frameworkintegration
      kdePackages.kdbusaddons
      kdePackages.ki18n
      kdePackages.qtsvg
      kdePackages.plasma-workspace # Provides plasma-apply-colorscheme
      kdePackages.kde-cli-tools # Provides various KDE CLI utilities
      kdePackages.polkit-kde-agent-1 # Polkit authentication agent
      kdePackages.kdialog # Dialog prompts
      kdePackages.kirigami

      # for quickshell key store
      libsecret
    ];
  };
}
