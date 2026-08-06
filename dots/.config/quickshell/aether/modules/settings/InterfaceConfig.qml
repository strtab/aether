import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
  forceWidth: true

  ContentSection {
    icon: "keyboard"
    title: Translation.tr("Cheat sheet")

    ContentSubsection {
      title: Translation.tr("Super key symbol")
      tooltip: Translation.tr("You can also manually edit cheatsheet.superKey")
      ConfigSelectionArray {
        currentValue: Config.options.cheatsheet.superKey
        onSelected: newValue => {
          Config.options.cheatsheet.superKey = newValue;
        }
        // Use a nerdfont to see the icons
        options: (["", "󱄅", "⌘"]).map(icon => {
          return {
            displayName: icon,
            value: icon
          };
        })
      }
    }

    ConfigSwitch {
      buttonIcon: "󰘵"
      text: Translation.tr("Use macOS-like symbols for mods keys")
      checked: Config.options.cheatsheet.useMacSymbol
      onCheckedChanged: {
        Config.options.cheatsheet.useMacSymbol = checked;
      }
      StyledToolTip {
        text: Translation.tr("e.g. 󰘴  for Ctrl, 󰘵  for Alt, 󰘶  for Shift, etc")
      }
    }

    ConfigSwitch {
      buttonIcon: "󱊶"
      text: Translation.tr("Use symbols for function keys")
      checked: Config.options.cheatsheet.useFnSymbol
      onCheckedChanged: {
        Config.options.cheatsheet.useFnSymbol = checked;
      }
      StyledToolTip {
        text: Translation.tr("e.g. 󱊫 for F1, 󱊶  for F12")
      }
    }
    ConfigSwitch {
      buttonIcon: "󰍽"
      text: Translation.tr("Use symbols for mouse")
      checked: Config.options.cheatsheet.useMouseSymbol
      onCheckedChanged: {
        Config.options.cheatsheet.useMouseSymbol = checked;
      }
      StyledToolTip {
        text: Translation.tr("Replace 󱕐   for \"Scroll ↓\", 󱕑   \"Scroll ↑\", L󰍽   \"LMB\", R󰍽   \"RMB\", 󱕒   \"Scroll ↑/↓\" and ⇞/⇟ for \"Page_↑/↓\"")
      }
    }

    ConfigSpinBox {
      text: Translation.tr("Keybind font size")
      value: Config.options.cheatsheet.fontSize.key
      from: 8
      to: 30
      stepSize: 1
      onValueChanged: {
        Config.options.cheatsheet.fontSize.key = value;
      }
    }
    ConfigSpinBox {
      text: Translation.tr("Description font size")
      value: Config.options.cheatsheet.fontSize.comment
      from: 8
      to: 30
      stepSize: 1
      onValueChanged: {
        Config.options.cheatsheet.fontSize.comment = value;
      }
    }
  }
  ContentSection {
    icon: "call_to_action"
    title: Translation.tr("Dock")

    ConfigSwitch {
      buttonIcon: "check"
      text: Translation.tr("Enable")
      checked: Config.options.dock.enable
      onCheckedChanged: {
        Config.options.dock.enable = checked;
      }
    }

    ConfigRow {
      uniform: true
      ConfigSwitch {
        buttonIcon: "keep"
        text: Translation.tr("Pinned on startup")
        checked: Config.options.dock.pinnedOnStartup
        onCheckedChanged: {
          Config.options.dock.pinnedOnStartup = checked;
        }
      }
      ConfigSwitch {
        buttonIcon: "keep"
        text: Translation.tr("Show pin button")
        checked: Config.options.dock.showPinButton
        onCheckedChanged: {
          Config.options.dock.showPinButton = checked;
        }
      }
    }
    ConfigSwitch {
      buttonIcon: "highlight_mouse_cursor"
      text: Translation.tr("Show overview button")
      checked: Config.options.dock.showOverviewButton
      onCheckedChanged: {
        Config.options.dock.showOverviewButton = checked;
      }
    }

    ConfigSpinBox {
      icon: "aspect_ratio"
      text: Translation.tr("Icon size (px)")
      value: Config.options.dock.iconSize ?? 40
      from: 55
      to: 100
      stepSize: 1
      onValueChanged: {
        Config.setNestedValue("dock.iconSize", value);
      }
    }
    ConfigSwitch {
      buttonIcon: "highlight_mouse_cursor"
      text: Translation.tr("Hover to reveal")
      checked: Config.options.dock.hoverToReveal
      onCheckedChanged: {
        Config.options.dock.hoverToReveal = checked;
      }
    }
    ConfigSwitch {
      buttonIcon: "colors"
      text: Translation.tr("Tint app icons")
      checked: Config.options.dock.monochromeIcons
      onCheckedChanged: {
        Config.options.dock.monochromeIcons = checked;
      }
    }
  }

  ContentSection {
    icon: "lock"
    title: Translation.tr("Lock screen")

    ConfigSwitch {
      buttonIcon: "water_drop"
      text: Translation.tr('Use Hyprlock (instead of Quickshell)')
      checked: Config.options.lock.useHyprlock
      onCheckedChanged: {
        Config.options.lock.useHyprlock = checked;
      }
      StyledToolTip {
        text: Translation.tr("If you want to somehow use fingerprint unlock...")
      }
    }

    ConfigSwitch {
      buttonIcon: "account_circle"
      text: Translation.tr('Launch on startup')
      checked: Config.options.lock.launchOnStartup
      onCheckedChanged: {
        Config.options.lock.launchOnStartup = checked;
      }
    }

    ContentSubsection {
      title: Translation.tr("Security")

      ConfigSwitch {
        buttonIcon: "settings_power"
        text: Translation.tr('Require password to power off/restart')
        checked: Config.options.lock.security.requirePasswordToPower
        onCheckedChanged: {
          Config.options.lock.security.requirePasswordToPower = checked;
        }
        StyledToolTip {
          text: Translation.tr("Remember that on most devices one can always hold the power button to force shutdown\nThis only makes it a tiny bit harder for accidents to happen")
        }
      }

      ConfigSwitch {
        buttonIcon: "key_vertical"
        text: Translation.tr('Also unlock keyring')
        checked: Config.options.lock.security.unlockKeyring
        onCheckedChanged: {
          Config.options.lock.security.unlockKeyring = checked;
        }
        StyledToolTip {
          text: Translation.tr("This is usually safe and needed for your browser and AI sidebar anyway\nMostly useful for those who use lock on startup instead of a display manager that does it (GDM, SDDM, etc.)")
        }
      }
    }

    ContentSubsection {
      title: Translation.tr("Style: general")

      ConfigSwitch {
        buttonIcon: "center_focus_weak"
        text: Translation.tr('Center clock')
        checked: Config.options.lock.centerClock
        onCheckedChanged: {
          Config.options.lock.centerClock = checked;
        }
      }

      ConfigSwitch {
        buttonIcon: "info"
        text: Translation.tr('Show "Locked" text')
        checked: Config.options.lock.showLockedText
        onCheckedChanged: {
          Config.options.lock.showLockedText = checked;
        }
      }

      ConfigSwitch {
        buttonIcon: "shapes"
        text: Translation.tr('Use varying shapes for password characters')
        checked: Config.options.lock.materialShapeChars
        onCheckedChanged: {
          Config.options.lock.materialShapeChars = checked;
        }
      }
    }
    ContentSubsection {
      title: Translation.tr("Style: Blurred")

      ConfigSwitch {
        buttonIcon: "blur_on"
        text: Translation.tr('Enable blur')
        checked: Config.options.lock.blur.enable
        onCheckedChanged: {
          Config.options.lock.blur.enable = checked;
        }
      }

      ConfigSpinBox {
        icon: "loupe"
        text: Translation.tr("Extra wallpaper zoom (%)")
        value: Config.options.lock.blur.extraZoom * 100
        from: 1
        to: 150
        stepSize: 2
        onValueChanged: {
          Config.options.lock.blur.extraZoom = value / 100;
        }
      }
    }
  }

  ContentSection {
    icon: "notifications"
    title: Translation.tr("Notifications")

    ConfigSpinBox {
      icon: "av_timer"
      text: Translation.tr("Timeout duration (if not defined by notification) (ms)")
      value: Config.options.notifications.timeout
      from: 1000
      to: 60000
      stepSize: 1000
      onValueChanged: {
        Config.options.notifications.timeout = value;
      }
    }
  }

  ContentSection {
    icon: "voting_chip"
    title: Translation.tr("On-screen display")

    ConfigSpinBox {
      icon: "av_timer"
      text: Translation.tr("Timeout (ms)")
      value: Config.options.osd.timeout
      from: 100
      to: 3000
      stepSize: 100
      onValueChanged: {
        Config.options.osd.timeout = value;
      }
    }
  }

  ContentSection {
    icon: "screenshot_frame_2"
    title: Translation.tr("Region selector (screen snipping/Google Lens)")

    ContentSubsection {
      title: Translation.tr("Hint target regions")
      ConfigRow {
        ConfigSwitch {
          buttonIcon: "select_window"
          text: Translation.tr('Windows')
          checked: Config.options.regionSelector.targetRegions.windows
          onCheckedChanged: {
            Config.options.regionSelector.targetRegions.windows = checked;
          }
        }
        ConfigSwitch {
          buttonIcon: "right_panel_open"
          text: Translation.tr('Layers')
          checked: Config.options.regionSelector.targetRegions.layers
          onCheckedChanged: {
            Config.options.regionSelector.targetRegions.layers = checked;
          }
        }
        ConfigSwitch {
          buttonIcon: "nearby"
          text: Translation.tr('Content')
          checked: Config.options.regionSelector.targetRegions.content
          onCheckedChanged: {
            Config.options.regionSelector.targetRegions.content = checked;
          }
          StyledToolTip {
            text: Translation.tr("Could be images or parts of the screen that have some containment.\nMight not always be accurate.\nThis is done with an image processing algorithm run locally and no AI is used.")
          }
        }
      }
    }

    ContentSubsection {
      title: Translation.tr("Google Lens")

      ConfigSelectionArray {
        currentValue: Config.options.search.imageSearch.useCircleSelection ? "circle" : "rectangles"
        onSelected: newValue => {
          Config.options.search.imageSearch.useCircleSelection = (newValue === "circle");
        }
        options: [
          {
            icon: "activity_zone",
            value: "rectangles",
            displayName: Translation.tr("Rectangular selection")
          },
          {
            icon: "gesture",
            value: "circle",
            displayName: Translation.tr("Circle to Search")
          }
        ]
      }
    }

    ContentSubsection {
      title: Translation.tr("Rectangular selection")

      ConfigSwitch {
        buttonIcon: "point_scan"
        text: Translation.tr("Show aim lines")
        checked: Config.options.regionSelector.rect.showAimLines
        onCheckedChanged: {
          Config.options.regionSelector.rect.showAimLines = checked;
        }
      }
    }

    ContentSubsection {
      title: Translation.tr("Circle selection")

      ConfigSpinBox {
        icon: "eraser_size_3"
        text: Translation.tr("Stroke width")
        value: Config.options.regionSelector.circle.strokeWidth
        from: 1
        to: 20
        stepSize: 1
        onValueChanged: {
          Config.options.regionSelector.circle.strokeWidth = value;
        }
      }

      ConfigSpinBox {
        icon: "screenshot_frame_2"
        text: Translation.tr("Padding")
        value: Config.options.regionSelector.circle.padding
        from: 0
        to: 100
        stepSize: 5
        onValueChanged: {
          Config.options.regionSelector.circle.padding = value;
        }
      }
    }
  }

  ContentSection {
    icon: "side_navigation"
    title: Translation.tr("Sidebars")

    ConfigSwitch {
      buttonIcon: "memory"
      text: Translation.tr('Keep right sidebar loaded')
      checked: Config.options.sidebar.keepRightSidebarLoaded
      onCheckedChanged: {
        Config.options.sidebar.keepRightSidebarLoaded = checked;
      }
      StyledToolTip {
        text: Translation.tr("When enabled keeps the content of the right sidebar loaded to reduce the delay when opening,\nat the cost of around 15MB of consistent RAM usage. Delay significance depends on your system's performance.\nUsing a custom kernel like linux-cachyos might help")
      }
    }

    // ConfigSwitch {
    //   buttonIcon: "translate"
    //   text: Translation.tr('Enable translator')
    //   checked: Config.options.sidebar.translator.enable
    //   onCheckedChanged: {
    //     Config.options.sidebar.translator.enable = checked;
    //   }
    // }

    ContentSubsection {
      title: Translation.tr("Quick toggles")

      // ConfigSelectionArray {
      //   Layout.fillWidth: false
      //   currentValue: Config.options.sidebar.quickToggles.style
      //   onSelected: newValue => {
      //     Config.options.sidebar.quickToggles.style = newValue;
      //   }
      //   options: [
      //     {
      //       displayName: Translation.tr("Classic"),
      //       icon: "password_2",
      //       value: "classic"
      //     },
      //     {
      //       displayName: Translation.tr("Android"),
      //       icon: "action_key",
      //       value: "android"
      //     }
      //   ]
      // }

      ConfigSpinBox {
        enabled: Config.options.sidebar.quickToggles.style === "android"
        icon: "splitscreen_left"
        text: Translation.tr("Columns")
        value: Config.options.sidebar.quickToggles.android.columns
        from: 1
        to: 8
        stepSize: 1
        onValueChanged: {
          Config.options.sidebar.quickToggles.android.columns = value;
        }
      }
    }

    ContentSubsection {
      title: Translation.tr("Sliders")

      ConfigSwitch {
        buttonIcon: "check"
        text: Translation.tr("Enable")
        checked: Config.options.sidebar.quickSliders.enable
        onCheckedChanged: {
          Config.options.sidebar.quickSliders.enable = checked;
        }
      }

      ConfigSwitch {
        buttonIcon: "brightness_6"
        text: Translation.tr("Brightness")
        enabled: Config.options.sidebar.quickSliders.enable
        checked: Config.options.sidebar.quickSliders.showBrightness
        onCheckedChanged: {
          Config.options.sidebar.quickSliders.showBrightness = checked;
        }
      }

      ConfigSwitch {
        buttonIcon: "volume_up"
        text: Translation.tr("Volume")
        enabled: Config.options.sidebar.quickSliders.enable
        checked: Config.options.sidebar.quickSliders.showVolume
        onCheckedChanged: {
          Config.options.sidebar.quickSliders.showVolume = checked;
        }
      }

      ConfigSwitch {
        buttonIcon: "mic"
        text: Translation.tr("Microphone")
        enabled: Config.options.sidebar.quickSliders.enable
        checked: Config.options.sidebar.quickSliders.showMic
        onCheckedChanged: {
          Config.options.sidebar.quickSliders.showMic = checked;
        }
      }
    }
  }

  // ContentSection {
  //   icon: "overview_key"
  //   title: Translation.tr("Overview")
  //
  //   ConfigSwitch {
  //     buttonIcon: "check"
  //     text: Translation.tr("Enable")
  //     checked: Config.options.overview.enable
  //     onCheckedChanged: {
  //       Config.options.overview.enable = checked;
  //     }
  //   }
  //   ConfigSwitch {
  //     buttonIcon: "center_focus_strong"
  //     text: Translation.tr("Center icons")
  //     checked: Config.options.overview.centerIcons
  //     onCheckedChanged: {
  //       Config.options.overview.centerIcons = checked;
  //     }
  //   }
  //   ConfigSpinBox {
  //     icon: "loupe"
  //     text: Translation.tr("Scale (%)")
  //     value: Config.options.overview.scale * 100
  //     from: 1
  //     to: 100
  //     stepSize: 1
  //     onValueChanged: {
  //       Config.options.overview.scale = value / 100;
  //     }
  //   }
  //   ConfigRow {
  //     uniform: true
  //     ConfigSpinBox {
  //       icon: "splitscreen_bottom"
  //       text: Translation.tr("Rows")
  //       value: Config.options.overview.rows
  //       from: 1
  //       to: 20
  //       stepSize: 1
  //       onValueChanged: {
  //         Config.options.overview.rows = value;
  //       }
  //     }
  //     ConfigSpinBox {
  //       icon: "splitscreen_right"
  //       text: Translation.tr("Columns")
  //       value: Config.options.overview.columns
  //       from: 1
  //       to: 20
  //       stepSize: 1
  //       onValueChanged: {
  //         Config.options.overview.columns = value;
  //       }
  //     }
  //   }
  //   ConfigRow {
  //     uniform: true
  //     ConfigSelectionArray {
  //       currentValue: Config.options.overview.orderRightLeft
  //       onSelected: newValue => {
  //         Config.options.overview.orderRightLeft = newValue;
  //       }
  //       options: [
  //         {
  //           displayName: Translation.tr("Left to right"),
  //           icon: "arrow_forward",
  //           value: 0
  //         },
  //         {
  //           displayName: Translation.tr("Right to left"),
  //           icon: "arrow_back",
  //           value: 1
  //         }
  //       ]
  //     }
  //     ConfigSelectionArray {
  //       currentValue: Config.options.overview.orderBottomUp
  //       onSelected: newValue => {
  //         Config.options.overview.orderBottomUp = newValue;
  //       }
  //       options: [
  //         {
  //           displayName: Translation.tr("Top-down"),
  //           icon: "arrow_downward",
  //           value: 0
  //         },
  //         {
  //           displayName: Translation.tr("Bottom-up"),
  //           icon: "arrow_upward",
  //           value: 1
  //         }
  //       ]
  //     }
  //   }
  // }

  ContentSection {
    icon: "wallpaper_slideshow"
    title: Translation.tr("Wallpaper selector")

    ConfigSwitch {
      buttonIcon: "ad"
      text: Translation.tr('Use system file picker')
      checked: Config.options.wallpaperSelector.useSystemFileDialog
      onCheckedChanged: {
        Config.options.wallpaperSelector.useSystemFileDialog = checked;
      }
    }
  }

  ContentSection {
    icon: "text_format"
    title: Translation.tr("Fonts")

    ContentSubsection {
      title: Translation.tr("Main font")
      tooltip: Translation.tr("Used for general UI text")

      FontSelector {
        id: mainFontSelector
        selectedFont: Config.options?.appearance?.typography?.main ?? "Roboto Flex"
        onSelectedFontChanged: {
          if (Config.options?.appearance?.typography)
            Config.setNestedValue("appearance.typography.main", selectedFont);
        }
        Connections {
          target: Config.options?.appearance?.typography ?? null
          function onMainFontChanged() {
            mainFontSelector.selectedFont = Config.options.appearance.typography.main;
          }
        }
      }
    }

    ContentSubsection {
      title: Translation.tr("Numbers font")
      tooltip: Translation.tr("Used for displaying numbers")

      FontSelector {
        id: numbersFontSelector
        selectedFont: Config.options?.appearance?.typography?.numbers ?? "Roboto Flex"
        onSelectedFontChanged: {
          if (Config.options?.appearance?.typography)
            Config.setNestedValue("appearance.typography.numbers", selectedFont);
        }
        Connections {
          target: Config.options?.appearance?.typography ?? null
          function onMainFontChanged() {
            numbersFontSelector.selectedFont = Config.options.appearance.typography.numbers;
          }
        }
      }
    }

    ContentSubsection {
      title: Translation.tr("Title font")
      tooltip: Translation.tr("Used for headings and titles")

      FontSelector {
        id: titleFontSelector
        selectedFont: Config.options?.appearance?.typography?.title ?? "Roboto Flex"
        onSelectedFontChanged: {
          if (Config.options?.appearance?.typography)
            Config.setNestedValue("appearance.typography.title", selectedFont);
        }
        Connections {
          target: Config.options?.appearance?.typography ?? null
          function onMainFontChanged() {
            titleFontSelector.selectedFont = Config.options.appearance.typography.title;
          }
        }
      }
    }

    ContentSubsection {
      title: Translation.tr("Monospace font")
      tooltip: Translation.tr("Used for code and terminal")

      FontSelector {
        id: monospaceFontSelector
        selectedFont: Config.options?.appearance?.typography?.monospace ?? "JetBrains Mono NF"
        onSelectedFontChanged: {
          if (Config.options?.appearance?.typography)
            Config.setNestedValue("appearance.typography.monospace", selectedFont);
        }
        Connections {
          target: Config.options?.appearance?.monospace ?? null
          function onMainFontChanged() {
            monospaceFontSelector.selectedFont = Config.options.appearance.typography.monospace;
          }
        }
      }
    }

    ContentSubsection {
      title: Translation.tr("Nerd font icons")
      tooltip: Translation.tr("Font used for Nerd Font icons")

      FontSelector {
        id: nerdFontSelector
        selectedFont: Config.options?.appearance?.typography?.iconNerd ?? "JetBrains Mono NF"
        onSelectedFontChanged: {
          if (Config.options?.appearance?.typography)
            Config.setNestedValue("appearance.typography.iconNerd", selectedFont);
        }
        Connections {
          target: Config.options?.appearance?.iconNerd ?? null
          function onMainFontChanged() {
            nerdFontSelector.selectedFont = Config.options.appearance.typography.iconNerd;
          }
        }
      }
    }

    ContentSubsection {
      title: Translation.tr("Reading font")
      tooltip: Translation.tr("Used for reading large blocks of text")

      FontSelector {
        id: readingFontSelector
        selectedFont: Config.options?.appearance?.typography?.reading ?? "Readex Pro"
        onSelectedFontChanged: {
          if (Config.options?.appearance?.typography)
            Config.setNestedValue("appearance.typography.reading", selectedFont);
        }
        Connections {
          target: Config.options?.appearance?.reading ?? null
          function onMainFontChanged() {
            readingFontSelector.selectedFont = Config.options.appearance.typography.reading;
          }
        }
      }
    }

    ContentSubsection {
      title: Translation.tr("Expressive font")
      tooltip: Translation.tr("Used for decorative/expressive text")

      FontSelector {
        id: expressiveFontSelector
        selectedFont: Config.options?.appearance?.typography?.expressive ?? "Google Sans 17pt"
        onSelectedFontChanged: {
          if (Config.options?.appearance?.typography)
            Config.setNestedValue("appearance.typography.expressive", selectedFont);
        }
        Connections {
          target: Config.options?.appearance?.expressive ?? null
          function onMainFontChanged() {
            expressiveFontSelector.selectedFont = Config.options.appearance.typography.expressive;
          }
        }
      }
    }
  }
  ContentSection {
    icon: "colors"
    title: Translation.tr("Color generation")

    ConfigSwitch {
      buttonIcon: "hardware"
      text: Translation.tr("Shell & utilities")
      checked: Config.options.appearance.wallpaperTheming.enableAppsAndShell
      onCheckedChanged: {
        Config.options.appearance.wallpaperTheming.enableAppsAndShell = checked;
      }
    }
    ConfigSwitch {
      buttonIcon: "tv_options_input_settings"
      text: Translation.tr("Qt apps")
      checked: Config.options.appearance.wallpaperTheming.enableQtApps
      onCheckedChanged: {
        Config.options.appearance.wallpaperTheming.enableQtApps = checked;
      }
      StyledToolTip {
        text: Translation.tr("Shell & utilities theming must also be enabled")
      }
    }
    // ConfigSwitch {
    //   buttonIcon: "terminal"
    //   text: Translation.tr("Terminal")
    //   checked: Config.options.appearance.wallpaperTheming.enableTerminal
    //   onCheckedChanged: {
    //     Config.options.appearance.wallpaperTheming.enableTerminal = checked;
    //   }
    //   StyledToolTip {
    //     text: Translation.tr("Shell & utilities theming must also be enabled")
    //   }
    // }
    // ConfigRow {
    //   uniform: true
    //   ConfigSwitch {
    //     buttonIcon: "dark_mode"
    //     text: Translation.tr("Force dark mode in terminal")
    //     checked: Config.options.appearance.wallpaperTheming.terminalGenerationProps.forceDarkMode
    //     onCheckedChanged: {
    //       Config.options.appearance.wallpaperTheming.terminalGenerationProps.forceDarkMode = checked;
    //     }
    //     StyledToolTip {
    //       text: Translation.tr("Ignored if terminal theming is not enabled")
    //     }
    //   }
    // }
    //
    // ConfigSpinBox {
    //   icon: "invert_colors"
    //   text: Translation.tr("Terminal: Harmony (%)")
    //   value: Config.options.appearance.wallpaperTheming.terminalGenerationProps.harmony * 100
    //   from: 0
    //   to: 100
    //   stepSize: 10
    //   onValueChanged: {
    //     Config.options.appearance.wallpaperTheming.terminalGenerationProps.harmony = value / 100;
    //   }
    // }
    // ConfigSpinBox {
    //   icon: "gradient"
    //   text: Translation.tr("Terminal: Harmonize threshold")
    //   value: Config.options.appearance.wallpaperTheming.terminalGenerationProps.harmonizeThreshold
    //   from: 0
    //   to: 100
    //   stepSize: 10
    //   onValueChanged: {
    //     Config.options.appearance.wallpaperTheming.terminalGenerationProps.harmonizeThreshold = value;
    //   }
    // }
    // ConfigSpinBox {
    //   icon: "format_color_text"
    //   text: Translation.tr("Terminal: Foreground boost (%)")
    //   value: Config.options.appearance.wallpaperTheming.terminalGenerationProps.termFgBoost * 100
    //   from: 0
    //   to: 100
    //   stepSize: 10
    //   onValueChanged: {
    //     Config.options.appearance.wallpaperTheming.terminalGenerationProps.termFgBoost = value / 100;
    //   }
    // }
  }
}
