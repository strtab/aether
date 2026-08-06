inputs:

{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.aether;
  pythonEnv = cfg.internal.pythonEnv;

  # The raw QuickShell package
  qsPackage = inputs.quickshell.packages.${pkgs.stdenv.hostPlatform.system}.default;

  # Runtime dependencies
  qtImports = [
    pkgs.kdePackages.qtbase
    pkgs.kdePackages.qtdeclarative
    pkgs.kdePackages.qtsvg
    pkgs.kdePackages.qtwayland
    pkgs.kdePackages.qt5compat
    pkgs.kdePackages.qtimageformats
    pkgs.kdePackages.qtmultimedia
    pkgs.kdePackages.qtpositioning
    pkgs.kdePackages.qtsensors
    pkgs.kdePackages.qtquicktimeline
    pkgs.kdePackages.qttools
    pkgs.kdePackages.qttranslations
    pkgs.kdePackages.qtvirtualkeyboard
    pkgs.kdePackages.qtwebsockets
    pkgs.kdePackages.qtwebengine
    pkgs.kdePackages.syntax-highlighting
    pkgs.kdePackages.kirigami.unwrapped
  ];
in
{
  config = lib.mkIf cfg.enable {
    qt = {
      enable = true;
      platformTheme.name = "${config.programs.aether.theme.name}";
      style.name = "${config.programs.aether.theme.style}";
    };

    home.packages = [
      # WRAPPED QuickShell (named "qs" to match config expectation)
      # This replaces the raw package to avoid collisions and force environment
      (pkgs.writeShellScriptBin "qs" ''
        # Force environment variables for reliability
        export QTWEBENGINEPROCESS_PATH="${pkgs.kdePackages.qtwebengine}/libexec/QtWebEngineProcess"
        export QT_PLUGIN_PATH="${lib.makeSearchPath "lib/qt-6/plugins" qtImports}:${lib.makeSearchPath "lib/qt6/plugins" qtImports}:${lib.makeSearchPath "lib/plugins" qtImports}"
        export QML2_IMPORT_PATH="${lib.makeSearchPath "lib/qt-6/qml" qtImports}"

        # Comprehensive XDG_DATA_DIRS for icon and desktop file discovery
        export XDG_DATA_DIRS="${
          lib.makeSearchPath "share" [
            pkgs.gruvbox-plus-icons
            pkgs.lxqt.pavucontrol-qt
            pkgs.pavucontrol
          ]
        }:$HOME/.nix-profile/share:$HOME/.local/share:/etc/profiles/per-user/$USER/share:/run/current-system/sw/share:/usr/share:$XDG_DATA_DIRS"

        export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
        export QT_QPA_PLATFORMTHEME=kde

        # Launch the real binary
        exec ${qsPackage}/bin/qs "$@"
      '')
      pkgs.qt6Packages.qt6ct
      pkgs.libsForQt5.qtgraphicaleffects
      pkgs.libsForQt5.qtsvg
      pythonEnv
    ]
    ++ qtImports;
  };
}
