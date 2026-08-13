import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
  forceWidth: true

  ContentSection {
    icon: "toggle_on"
    title: Translation.tr("")

    ConfigSwitch {
      buttonIcon: "check_circle"
      text: Translation.tr("Enable the menu bar")
      description: Translation.tr("Turn the entire top bar on or off.")
      checked: Config.options.bar.enable
      onCheckedChanged: {
        Config.options.bar.enable = checked;
      }
    }

    ContentSubsection {
      title: Translation.tr("Pin to monitors")
      description: Translation.tr("The menu bar will be displayed on these monitors")
      Input {
        Layout.fillWidth: true
        placeholderText: Translation.tr("e.g. eDP-1, DP-2")
        text: Config.options.bar.screenList.join(", ")
        wrapMode: TextEdit.Wrap
        onTextChanged: {
          screenListDebounceTimer.restart();
        }
        Timer {
          id: screenListDebounceTimer
          interval: 600
          repeat: false
          onTriggered: {
            const raw = parent.text.trim();
            const list = raw.length > 0 ? raw.split(",").map(name => name.trim()).filter(name => name.length > 0) : [];
            Config.options.bar.screenList = list;
          }
        }
      }
    }
  }

  ContentSection {
    icon: "spoke"
    title: Translation.tr("Positioning")

    ConfigComboBox {
      title: Translation.tr("Automatically hide and show the menu bar")
      description: Translation.tr("")
      model: [
        {
          displayName: Translation.tr("No"),
          value: false
        },
        {
          displayName: Translation.tr("Yes"),
          value: true
        }
      ]
      value: Config.options.bar.autoHide.enable
      onSelected: newValue => {
        Config.options.bar.autoHide.enable = newValue; // Update local copy
      }
    }

    ConfigSpinBox {
      enabled: Config.options.bar.autoHide.enable
      icon: "swipe_right"
      text: Translation.tr("Hover trigger region width (px)")
      // description: Translation.tr("Width of the invisible edge area that reveals the bar when the mouse touches it.")
      value: Config.options.bar.autoHide.hoverRegionWidth
      from: 1
      to: 50
      stepSize: 1
      onValueChanged: {
        Config.options.bar.autoHide.hoverRegionWidth = value;
      }
    }

    ConfigSwitch {
      enabled: Config.options.bar.autoHide.enable
      buttonIcon: "vertical_align_top"
      text: Translation.tr("Push windows down")
      description: Translation.tr("Reserve space for the bar instead of overlaying windows when it is shown.")
      checked: Config.options.bar.autoHide.pushWindows
      onCheckedChanged: {
        Config.options.bar.autoHide.pushWindows = checked;
      }
    }

    ConfigSwitch {
      enabled: Config.options.bar.autoHide.enable
      buttonIcon: "keyboard_command_key"
      text: Translation.tr("Show when pressing Super")
      description: Translation.tr("Temporarily reveal the auto-hidden bar while the Super key is held down.")
      checked: Config.options.bar.autoHide.showWhenPressingSuper.enable
      onCheckedChanged: {
        Config.options.bar.autoHide.showWhenPressingSuper.enable = checked;
      }
    }

    ConfigSpinBox {
      enabled: Config.options.bar.autoHide.enable && Config.options.bar.autoHide.showWhenPressingSuper.enable
      icon: "timer"
      text: Translation.tr("Show delay when pressing Super (ms)")
      // description: Translation.tr("How long Super must be held before the bar appears.")
      value: Config.options.bar.autoHide.showWhenPressingSuper.delay
      from: 0
      to: 2000
      stepSize: 20
      onValueChanged: {
        Config.options.bar.autoHide.showWhenPressingSuper.delay = value;
      }
    }
  }

  ContentSection {
    icon: "spoke"
    title: Translation.tr("Style")
    ConfigSwitch {
      buttonIcon: "colors"
      text: Translation.tr('Show menu bar background')
      checked: Config.options.bar.background.enable
      onCheckedChanged: {
        Config.options.bar.background.enable = checked;
      }
    }
    ConfigComboBox {
      title: Translation.tr("Background style")
      description: Translation.tr("")
      model: [
        {
          displayName: Translation.tr("Follow the theme"),
          value: 0
        },
        {
          displayName: Translation.tr("Plain color"),
          value: 1
        },
        {
          displayName: Translation.tr("Transparent"),
          value: 2
        }
      ]
      value: Config.options.bar.background.style
      onSelected: newValue => {
        Config.options.bar.background.style = newValue; // Update local copy
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
        backgroundDebounceTimer.restart();
      }
      Timer {
        id: backgroundDebounceTimer
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
    ConfigComboBox {
      title: Translation.tr("Font color")
      description: Translation.tr("")
      model: [
        {
          displayName: Translation.tr("Follow the theme"),
          value: 0
        },
        {
          displayName: Translation.tr("Plain color"),
          value: 1
        },
      ]
      value: Config.options.bar.foreground.style
      onSelected: newValue => {
        Config.options.bar.foreground.style = newValue; // Update local copy
      }
    }
    Input {
      Layout.fillWidth: true
      visible: Config.options.bar.foreground.style == 1
      placeholderText: Translation.tr("Font color")
      text: Config.options.bar.foreground.color
      wrapMode: TextEdit.Wrap
      onTextChanged: {
        Config.options.bar.foreground.color = text;
        foregroundDebounceTimer.restart();
      }
      Timer {
        id: foregroundDebounceTimer
        interval: 600
        repeat: false
        onTriggered: {
          const color = parent.text.trim();
          const isValidHex = /^#[0-9A-Fa-f]{6}$/.test(color);
          if (!isValidHex)
            return;
          Config.options.bar.foreground.color = parent.text;
        }
      }
    }
  }

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
      visible: Config.options.bar.workspaces.enable
      buttonIcon: "counter_1"
      text: Translation.tr('Always show numbers')
      checked: Config.options.bar.workspaces.alwaysShowNumbers
      onCheckedChanged: {
        Config.options.bar.workspaces.alwaysShowNumbers = checked;
      }
    }

    ConfigSwitch {
      visible: Config.options.bar.workspaces.enable
      buttonIcon: "award_star"
      text: Translation.tr('Show app icons')
      checked: Config.options.bar.workspaces.showAppIcons
      onCheckedChanged: {
        Config.options.bar.workspaces.showAppIcons = checked;
      }
    }

    ConfigSwitch {
      visible: Config.options.bar.workspaces.enable
      buttonIcon: "colors"
      text: Translation.tr('Tint app icons')
      checked: Config.options.bar.workspaces.monochromeIcons
      onCheckedChanged: {
        Config.options.bar.workspaces.monochromeIcons = checked;
      }
    }

    ConfigSwitch {
      visible: Config.options.bar.workspaces.enable
      buttonIcon: "font_download"
      text: Translation.tr("Use Nerd Font glyphs")
      description: Translation.tr("Render workspace numbers using Nerd Font icons instead of plain digits.")
      checked: Config.options.bar.workspaces.useNerdFont
      onCheckedChanged: {
        Config.options.bar.workspaces.useNerdFont = checked;
      }
    }

    ConfigSpinBox {
      visible: Config.options.bar.workspaces.enable
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
      visible: Config.options.bar.workspaces.enable
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

    ConfigComboBox {
      visible: Config.options.bar.workspaces.enable
      title: Translation.tr("Number style")
      description: Translation.tr("")
      model: [
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
      value: JSON.stringify(Config.options.bar.workspaces.numberMap)
      onSelected: newValue => {
        Config.options.bar.workspaces.numberMap = JSON.parse(newValue);
      }
    }
  }

  ContentSection {
    icon: "monitor_heart"
    title: Translation.tr("Resources")

    ConfigSwitch {
      buttonIcon: "swap_horiz"
      text: Translation.tr("Always show swap usage")
      description: Translation.tr("Keep the swap indicator visible even when swap usage is low.")
      checked: Config.options.bar.resources.alwaysShowSwap
      onCheckedChanged: {
        Config.options.bar.resources.alwaysShowSwap = checked;
      }
    }

    ConfigSwitch {
      buttonIcon: "memory"
      text: Translation.tr("Always show CPU usage")
      description: Translation.tr("Keep the CPU indicator visible even when usage is low.")
      checked: Config.options.bar.resources.alwaysShowCpu
      onCheckedChanged: {
        Config.options.bar.resources.alwaysShowCpu = checked;
      }
    }

    ConfigSpinBox {
      icon: "sd_card_alert"
      text: Translation.tr("Memory warning threshold (%)")
      // description: Translation.tr("Highlight the memory indicator once usage crosses this percentage.")
      value: Config.options.bar.resources.memoryWarningThreshold
      from: 0
      to: 100
      stepSize: 1
      onValueChanged: {
        Config.options.bar.resources.memoryWarningThreshold = value;
      }
    }

    ConfigSpinBox {
      icon: "swap_vert"
      text: Translation.tr("Swap warning threshold (%)")
      // description: Translation.tr("Highlight the swap indicator once usage crosses this percentage.")
      value: Config.options.bar.resources.swapWarningThreshold
      from: 0
      to: 100
      stepSize: 1
      onValueChanged: {
        Config.options.bar.resources.swapWarningThreshold = value;
      }
    }

    ConfigSpinBox {
      icon: "speed"
      text: Translation.tr("CPU warning threshold (%)")
      // description: Translation.tr("Highlight the CPU indicator once usage crosses this percentage.")
      value: Config.options.bar.resources.cpuWarningThreshold
      from: 0
      to: 100
      stepSize: 1
      onValueChanged: {
        Config.options.bar.resources.cpuWarningThreshold = value;
      }
    }
  }

  ContentSection {
    icon: "cloud"
    title: Translation.tr("Weather")

    ConfigSwitch {
      buttonIcon: "my_location"
      text: Translation.tr("Use GPS location")
      description: Translation.tr("Detect your location automatically instead of entering a city manually.")
      checked: Config.options.bar.weather.enableGPS
      onCheckedChanged: {
        Config.options.bar.weather.enableGPS = checked;
      }
    }

    Input {
      Layout.fillWidth: true
      visible: !Config.options.bar.weather.enableGPS
      placeholderText: Translation.tr("City")
      text: Config.options.bar.weather.city
      wrapMode: TextEdit.Wrap
      onTextChanged: {
        weatherCityDebounceTimer.restart();
      }
      Timer {
        id: weatherCityDebounceTimer
        interval: 600
        repeat: false
        onTriggered: {
          Config.options.bar.weather.city = parent.text.trim();
        }
      }
    }

    ConfigSwitch {
      buttonIcon: "thermostat"
      text: Translation.tr("Use imperial units")
      description: Translation.tr("Show temperature and wind speed in imperial units (Fahrenheit, mph) instead of metric.")
      checked: Config.options.bar.weather.useUSCS
      onCheckedChanged: {
        Config.options.bar.weather.useUSCS = checked;
      }
    }

    ConfigSpinBox {
      icon: "update"
      text: Translation.tr("Update interval (minutes)")
      // description: Translation.tr("How often the weather forecast is refreshed.")
      value: Config.options.bar.weather.fetchInterval
      from: 1
      to: 120
      stepSize: 5
      onValueChanged: {
        Config.options.bar.weather.fetchInterval = value;
      }
    }
  }

  ContentSection {
    icon: "schedule"
    title: Translation.tr("Clock")

    ConfigSwitch {
      buttonIcon: "check"
      text: Translation.tr("Show clock")
      description: Translation.tr("Display the clock widget on the bar.")
      checked: Config.options.bar.clock.enable
      onCheckedChanged: {
        Config.options.bar.clock.enable = checked;
      }
    }

    ConfigSwitch {
      enabled: Config.options.bar.clock.enable
      buttonIcon: "calendar_today"
      text: Translation.tr("Show date")
      description: Translation.tr("Also display the date next to the time.")
      checked: Config.options.bar.clock.showDate
      onCheckedChanged: {
        Config.options.bar.clock.showDate = checked;
      }
    }
  }
}
