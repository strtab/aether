import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
  forceWidth: true

  ContentSection {
    title: Translation.tr("Cheat sheet")

    ContentSubsection {
      title: Translation.tr("Super key symbol")
      description: Translation.tr("You can also manually edit cheatsheet.superKey")
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
      text: Translation.tr("Use macOS-like symbols for mods keys")
      checked: Config.options.cheatsheet.useMacSymbol
      onCheckedChanged: {
        Config.options.cheatsheet.useMacSymbol = checked;
      }
      description: Translation.tr("e.g. 󰘴  for Ctrl, 󰘵  for Alt, 󰘶  for Shift, etc")
    }

    ConfigSwitch {
      text: Translation.tr("Use symbols for function keys")
      checked: Config.options.cheatsheet.useFnSymbol
      onCheckedChanged: {
        Config.options.cheatsheet.useFnSymbol = checked;
      }
      description: Translation.tr("e.g. 󱊫 for F1, 󱊶  for F12")
    }
    ConfigSwitch {
      text: Translation.tr("Use symbols for mouse")
      checked: Config.options.cheatsheet.useMouseSymbol
      onCheckedChanged: {
        Config.options.cheatsheet.useMouseSymbol = checked;
      }
      description: Translation.tr("Replace 󱕐   for \"Scroll ↓\", 󱕑   \"Scroll ↑\", L󰍽   \"LMB\", R󰍽   \"RMB\", 󱕒   \"Scroll ↑/↓\" and ⇞/⇟ for \"Page_↑/↓\"")
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
    title: Translation.tr("Dock")

    ConfigSwitch {
      text: Translation.tr("Enable")
      checked: Config.options.dock.enable
      onCheckedChanged: {
        Config.options.dock.enable = checked;
      }
    }

    ConfigSwitch {
      text: Translation.tr("Pinned on startup")
      checked: Config.options.dock.pinnedOnStartup
      onCheckedChanged: {
        Config.options.dock.pinnedOnStartup = checked;
      }
    }
    ConfigSwitch {
      text: Translation.tr("Show pin button")
      checked: Config.options.dock.showPinButton
      onCheckedChanged: {
        Config.options.dock.showPinButton = checked;
      }
    }
  }
  ConfigSwitch {
    text: Translation.tr("Show overview button")
    checked: Config.options.dock.showOverviewButton
    onCheckedChanged: {
      Config.options.dock.showOverviewButton = checked;
    }
  }

  ConfigSpinBox {
    text: Translation.tr("Icon size (px)")
    from: 55
    to: 100
    stepSize: 1
    onValueChanged: {
    }
  }
  ConfigSwitch {
    text: Translation.tr("Hover to reveal")
    checked: Config.options.dock.hoverToReveal
    onCheckedChanged: {
      Config.options.dock.hoverToReveal = checked;
    }
  }
  ConfigSwitch {
    checked: Config.options.dock.monochromeIcons
    onCheckedChanged: {
      Config.options.dock.monochromeIcons = checked;
    }
  }

  ContentSection {
    title: Translation.tr("Lock screen")

    ConfigSwitch {
      text: Translation.tr('Use Hyprlock (instead of Quickshell)')
      checked: Config.options.lock.useHyprlock
      onCheckedChanged: {
        Config.options.lock.useHyprlock = checked;
      }
      description: Translation.tr("If you want to somehow use fingerprint unlock...")
    }

    ConfigSwitch {
      text: Translation.tr('Launch on startup')
      checked: Config.options.lock.launchOnStartup
      onCheckedChanged: {
        Config.options.lock.launchOnStartup = checked;
      }
    }

    ContentSubsection {
      title: Translation.tr("Security")

      ConfigSwitch {
        text: Translation.tr('Require password to power off/restart')
        checked: Config.options.lock.security.requirePasswordToPower
        onCheckedChanged: {
          Config.options.lock.security.requirePasswordToPower = checked;
        }
        description: Translation.tr("Remember that on most devices one can always hold the power button to force shutdown\nThis only makes it a tiny bit harder for accidents to happen")
      }

      ConfigSwitch {
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
        text: Translation.tr('Center clock')
        checked: Config.options.lock.centerClock
        onCheckedChanged: {
          Config.options.lock.centerClock = checked;
        }
      }

      ConfigSwitch {
        text: Translation.tr('Show "Locked" text')
        checked: Config.options.lock.showLockedText
        onCheckedChanged: {
          Config.options.lock.showLockedText = checked;
        }
      }

      ConfigSwitch {
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
        text: Translation.tr('Enable blur')
        checked: Config.options.lock.blur.enable
        onCheckedChanged: {
          Config.options.lock.blur.enable = checked;
        }
      }

      ConfigSpinBox {
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
    title: Translation.tr("Notifications")

    ConfigSpinBox {
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
    title: Translation.tr("On-screen display")

    ConfigSpinBox {
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
    title: Translation.tr("Region selector (screen snipping/Google Lens)")

    ConfigSwitch {
      text: Translation.tr('Windows hint')
      checked: Config.options.regionSelector.targetRegions.windows
      onCheckedChanged: {
        Config.options.regionSelector.targetRegions.windows = checked;
      }
    }
    ConfigSwitch {
      text: Translation.tr('Layers hint')
      checked: Config.options.regionSelector.targetRegions.layers
      onCheckedChanged: {
        Config.options.regionSelector.targetRegions.layers = checked;
      }
    }
    ConfigSwitch {
      text: Translation.tr('Content hint')
      checked: Config.options.regionSelector.targetRegions.content
      onCheckedChanged: {
        Config.options.regionSelector.targetRegions.content = checked;
      }
      description: Translation.tr("Could be images or parts of the screen that have some containment.\nMight not always be accurate.\nThis is done with an image processing algorithm run locally and no AI is used.")
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
            value: "rectangles",
            displayName: Translation.tr("Rectangular selection")
          },
          {
            value: "circle",
            displayName: Translation.tr("Circle to Search")
          }
        ]
      }
    }

    ContentSubsection {
      title: Translation.tr("Rectangular selection")

      ConfigSwitch {
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
    title: Translation.tr("Sidebars")

    ConfigSwitch {
      text: Translation.tr('Keep right sidebar loaded')
      checked: Config.options.sidebar.keepRightSidebarLoaded
      onCheckedChanged: {
        Config.options.sidebar.keepRightSidebarLoaded = checked;
      }
      description: Translation.tr("When enabled keeps the content of the right sidebar loaded to reduce the delay when opening,\nat the cost of around 15MB of consistent RAM usage. Delay significance depends on your system's performance.\nUsing a custom kernel like linux-cachyos might help")
    }

    // ConfigSwitch {
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
      //       value: "classic"
      //     },
      //     {
      //       displayName: Translation.tr("Android"),
      //       value: "android"
      //     }
      //   ]
      // }

      ConfigSpinBox {
        enabled: Config.options.sidebar.quickToggles.style === "android"
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
        text: Translation.tr("Enable")
        checked: Config.options.sidebar.quickSliders.enable
        onCheckedChanged: {
          Config.options.sidebar.quickSliders.enable = checked;
        }
      }

      ConfigSwitch {
        text: Translation.tr("Brightness")
        enabled: Config.options.sidebar.quickSliders.enable
        checked: Config.options.sidebar.quickSliders.showBrightness
        onCheckedChanged: {
          Config.options.sidebar.quickSliders.showBrightness = checked;
        }
      }

      ConfigSwitch {
        text: Translation.tr("Volume")
        enabled: Config.options.sidebar.quickSliders.enable
        checked: Config.options.sidebar.quickSliders.showVolume
        onCheckedChanged: {
          Config.options.sidebar.quickSliders.showVolume = checked;
        }
      }

      ConfigSwitch {
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
  //   title: Translation.tr("Overview")
  //
  //   ConfigSwitch {
  //     text: Translation.tr("Enable")
  //     checked: Config.options.overview.enable
  //     onCheckedChanged: {
  //       Config.options.overview.enable = checked;
  //     }
  //   }
  //   ConfigSwitch {
  //     checked: Config.options.overview.centerIcons
  //     onCheckedChanged: {
  //       Config.options.overview.centerIcons = checked;
  //     }
  //   }
  //   ConfigSpinBox {
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
  //           value: 0
  //         },
  //         {
  //           displayName: Translation.tr("Right to left"),
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
  //           value: 0
  //         },
  //         {
  //           displayName: Translation.tr("Bottom-up"),
  //           value: 1
  //         }
  //       ]
  //     }
  //   }
  // }

  ContentSection {
    title: Translation.tr("Wallpaper selector")

    ConfigSwitch {
      text: Translation.tr('Use system file picker')
      checked: Config.options.wallpaperSelector.useSystemFileDialog
      onCheckedChanged: {
        Config.options.wallpaperSelector.useSystemFileDialog = checked;
      }
    }
  }
  ContentSection {
    title: Translation.tr("Color generation")

    ConfigSwitch {
      text: Translation.tr("Shell & utilities")
      checked: Config.options.appearance.wallpaperTheming.enableAppsAndShell
      onCheckedChanged: {
        Config.options.appearance.wallpaperTheming.enableAppsAndShell = checked;
      }
    }
    ConfigSwitch {
      text: Translation.tr("Qt apps")
      checked: Config.options.appearance.wallpaperTheming.enableQtApps
      onCheckedChanged: {
        Config.options.appearance.wallpaperTheming.enableQtApps = checked;
      }
      description: Translation.tr("Shell & utilities theming must also be enabled")
    }
    // ConfigSwitch {
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
