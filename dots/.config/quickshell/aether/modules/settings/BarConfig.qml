import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
  forceWidth: true

  ContentSection {
    icon: "spoke"
    title: Translation.tr("Positioning")

    ContentSubsection {
      title: Translation.tr("Automatically hide")
      Layout.fillWidth: false

      ConfigSelectionArray {
        currentValue: Config.options.bar.autoHide.enable
        onSelected: newValue => {
          Config.options.bar.autoHide.enable = newValue; // Update local copy
        }
        options: [
          {
            displayName: Translation.tr("No"),
            icon: "close",
            value: false
          },
          {
            displayName: Translation.tr("Yes"),
            icon: "check",
            value: true
          }
        ]
      }

      ContentSubsection {
        title: Translation.tr("Corner style")
        Layout.fillWidth: true

        ConfigSelectionArray {
          currentValue: Config.options.bar.cornerStyle
          onSelected: newValue => {
            Config.options.bar.cornerStyle = newValue; // Update local copy
          }
          options: [
            {
              displayName: Translation.tr("Hug"),
              icon: "line_curve",
              value: 0
            },
            {
              displayName: Translation.tr("Float"),
              icon: "page_header",
              value: 1
            },
            {
              displayName: Translation.tr("Rect"),
              icon: "toolbar",
              value: 2
            }
          ]
        }
      }
    }
  }

  ContentSection {
    icon: "spoke"
    title: Translation.tr("Background")
    ConfigSwitch {
      buttonIcon: "colors"
      text: Translation.tr('Show background')
      checked: Config.options.bar.background.enable
      onCheckedChanged: {
        Config.options.bar.background.enable = checked;
      }
    }
    ContentSubsection {
      title: Translation.tr("Style")
      Layout.fillWidth: true

      ConfigSelectionArray {
        currentValue: Config.options.bar.background.style
        onSelected: newValue => {
          Config.options.bar.background.style = newValue; // Update local copy
        }
        options: [
          {
            displayName: Translation.tr("Default"),
            icon: "line_curve",
            value: 0
          },
          {
            displayName: Translation.tr("Plain color"),
            icon: "page_header",
            value: 1
          },
          {
            displayName: Translation.tr("Transparent"),
            icon: "toolbar",
            value: 2
          }
        ]
      }
    }
    Input {
      Layout.fillWidth: true
      visible: Config.options.bar.background.style === 1 ?? false
      placeholderText: Translation.tr("Color")
      text: Config.options.bar.background.color
      wrapMode: TextEdit.Wrap
      onTextChanged: {
        Config.options.bar.background.color = text;
        debounceTimer.restart();
      }
      Timer {
        id: debounceTimer
        interval: 600
        repeat: false
        onTriggered: {
          const color = parent.text.trim();
          const isValidHex = /^#[0-9A-Fa-f]{6}$/.test(color);
          if (!isValidHex)
            return;
          Config.options.bar.background.color = parent.text;
        }
      }
    }
  }

  ContentSection {
    icon: "notifications"
    title: Translation.tr("Notifications")
    ConfigSwitch {
      buttonIcon: "counter_2"
      text: Translation.tr("Unread indicator: show count")
      checked: Config.options.bar.indicators.notifications.showUnreadCount
      onCheckedChanged: {
        Config.options.bar.indicators.notifications.showUnreadCount = checked;
      }
    }
  }

  // ContentSection {
  //   icon: "shelf_auto_hide"
  //   title: Translation.tr("Menu button")
  //
  //   ContentSubsection {
  //     title: Translation.tr("Icon")
  //     ConfigSelectionArray {
  //       currentValue: Config.options.bar.menuButton.icon
  //       onSelected: newValue => {
  //         Config.options.bar.menuButton.icon = newValue;
  //       }
  //       options: [
  //         {
  //           "value": "spark",
  //           "displayName": " Spark",
  //           "iconSource": "spark-symbolic"
  //         },
  //         {
  //           "value": "distro",
  //           "displayName": " Distro",
  //           "iconSource": SystemInfo.distroIcon
  //         },
  //       ]
  //     }
  //   }
  // }

  ContentSection {
    icon: "shelf_auto_hide"
    title: Translation.tr("Tray")

    ConfigSwitch {
      buttonIcon: "keep"
      text: Translation.tr('Make icons pinned by default')
      checked: Config.options.tray.invertPinnedItems
      onCheckedChanged: {
        Config.options.tray.invertPinnedItems = checked;
      }
    }

    ConfigSwitch {
      buttonIcon: "colors"
      text: Translation.tr('Tint icons')
      checked: Config.options.tray.monochromeIcons
      onCheckedChanged: {
        Config.options.tray.monochromeIcons = checked;
      }
    }
  }

  // ContentSection {
  //   icon: "widgets"
  //   title: Translation.tr("Utility buttons")
  //
  //   ConfigRow {
  //     uniform: true
  //     ConfigSwitch {
  //       buttonIcon: "content_cut"
  //       text: Translation.tr("Screen snip")
  //       checked: Config.options.bar.utilButtons.showScreenSnip
  //       onCheckedChanged: {
  //         Config.options.bar.utilButtons.showScreenSnip = checked;
  //       }
  //     }
  //     ConfigSwitch {
  //       buttonIcon: "colorize"
  //       text: Translation.tr("Color picker")
  //       checked: Config.options.bar.utilButtons.showColorPicker
  //       onCheckedChanged: {
  //         Config.options.bar.utilButtons.showColorPicker = checked;
  //       }
  //     }
  //   }
  //   ConfigRow {
  //     uniform: true
  //     ConfigSwitch {
  //       buttonIcon: "keyboard"
  //       text: Translation.tr("Keyboard toggle")
  //       checked: Config.options.bar.utilButtons.showKeyboardToggle
  //       onCheckedChanged: {
  //         Config.options.bar.utilButtons.showKeyboardToggle = checked;
  //       }
  //     }
  //     ConfigSwitch {
  //       buttonIcon: "mic"
  //       text: Translation.tr("Mic toggle")
  //       checked: Config.options.bar.utilButtons.showMicToggle
  //       onCheckedChanged: {
  //         Config.options.bar.utilButtons.showMicToggle = checked;
  //       }
  //     }
  //   }
  //   ConfigRow {
  //     uniform: true
  //     ConfigSwitch {
  //       buttonIcon: "dark_mode"
  //       text: Translation.tr("Dark/Light toggle")
  //       checked: Config.options.bar.utilButtons.showDarkModeToggle
  //       onCheckedChanged: {
  //         Config.options.bar.utilButtons.showDarkModeToggle = checked;
  //       }
  //     }
  //     ConfigSwitch {
  //       buttonIcon: "speed"
  //       text: Translation.tr("Performance Profile toggle")
  //       checked: Config.options.bar.utilButtons.showPerformanceProfileToggle
  //       onCheckedChanged: {
  //         Config.options.bar.utilButtons.showPerformanceProfileToggle = checked;
  //       }
  //     }
  //   }
  //   ConfigRow {
  //     uniform: true
  //     ConfigSwitch {
  //       buttonIcon: "videocam"
  //       text: Translation.tr("Record")
  //       checked: Config.options.bar.utilButtons.showScreenRecord
  //       onCheckedChanged: {
  //         Config.options.bar.utilButtons.showScreenRecord = checked;
  //       }
  //     }
  //     ConfigSwitch {
  //       buttonIcon: "search"
  //       text: Translation.tr("Search")
  //       checked: Config.options.bar.utilButtons.showSearchToggle
  //       onCheckedChanged: {
  //         Config.options.bar.utilButtons.showSearchToggle = checked;
  //       }
  //     }
  //   }
  // }

  ContentSection {
    icon: "workspaces"
    title: Translation.tr("Workspaces")

    ConfigSwitch {
      buttonIcon: "check"
      text: Translation.tr('Enable')
      checked: Config.options.bar.workspaces.enable
      onCheckedChanged: {
        Config.options.bar.workspaces.enable = checked;
      }
    }

    ConfigSwitch {
      buttonIcon: "counter_1"
      text: Translation.tr('Always show numbers')
      checked: Config.options.bar.workspaces.alwaysShowNumbers
      onCheckedChanged: {
        Config.options.bar.workspaces.alwaysShowNumbers = checked;
      }
    }

    ConfigSwitch {
      buttonIcon: "award_star"
      text: Translation.tr('Show app icons')
      checked: Config.options.bar.workspaces.showAppIcons
      onCheckedChanged: {
        Config.options.bar.workspaces.showAppIcons = checked;
      }
    }

    ConfigSwitch {
      buttonIcon: "colors"
      text: Translation.tr('Tint app icons')
      checked: Config.options.bar.workspaces.monochromeIcons
      onCheckedChanged: {
        Config.options.bar.workspaces.monochromeIcons = checked;
      }
    }

    ConfigSpinBox {
      icon: "view_column"
      text: Translation.tr("Workspaces shown")
      value: Config.options.bar.workspaces.shown
      from: 1
      to: 30
      stepSize: 1
      onValueChanged: {
        Config.options.bar.workspaces.shown = value;
      }
    }

    ConfigSpinBox {
      icon: "touch_long"
      text: Translation.tr("Number show delay when pressing Super (ms)")
      value: Config.options.bar.workspaces.showNumberDelay
      from: 0
      to: 1000
      stepSize: 50
      onValueChanged: {
        Config.options.bar.workspaces.showNumberDelay = value;
      }
    }

    ContentSubsection {
      title: Translation.tr("Number style")

      ConfigSelectionArray {
        currentValue: JSON.stringify(Config.options.bar.workspaces.numberMap)
        onSelected: newValue => {
          Config.options.bar.workspaces.numberMap = JSON.parse(newValue);
        }
        options: [
          {
            displayName: Translation.tr("Normal"),
            icon: "timer_10",
            value: '[]'
          },
          {
            displayName: Translation.tr("Han chars"),
            icon: "square_dot",
            value: '["一","二","三","四","五","六","七","八","九","十","十一","十二","十三","十四","十五","十六","十七","十八","十九","二十"]'
          },
          {
            displayName: Translation.tr("Roman"),
            icon: "account_balance",
            value: '["I","II","III","IV","V","VI","VII","VIII","IX","X","XI","XII","XIII","XIV","XV","XVI","XVII","XVIII","XIX","XX"]'
          }
        ]
      }
    }
  }
}
