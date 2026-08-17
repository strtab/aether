import QtQuick
import Quickshell
import Quickshell.Io
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

ContentPage {
  forceWidth: true

  Process {
    id: translationProc
    property string locale: ""
    command: [Directories.aiTranslationScriptPath, translationProc.locale]
  }

  ContentSection {
    ConfigComboBox {
      title: Translation.tr("Interface Language")
      description: Translation.tr("Select the language for the user interface.\n\"Auto\" will use your system's locale.")
      textRole: "displayName"
      model: [
        {
          displayName: Translation.tr("Auto (System)"),
          value: "auto"
        },
        ...Translation.allAvailableLanguages.map(lang => ({
              displayName: lang,
              value: lang
            }))]
      value: Config.options.language.ui
      onSelected: newValue => Config.options.language.ui = newValue
    }
  }

  ContentSection {
    title: Translation.tr("Audio")

    ConfigSwitch {
      title: Translation.tr("Earbang protection")
      description: Translation.tr("Prevents abrupt increments and restricts volume limit")
      checked: Config.options.audio.protection.enable
      onCheckedChanged: {
        Config.options.audio.protection.enable = checked;
      }
    }
    enabled: Config.options.audio.protection.enable
    ConfigSpinBox {
      title: Translation.tr("Max allowed increase")
      value: Config.options.audio.protection.maxAllowedIncrease
      from: 0
      to: 100
      stepSize: 2
      onValueChanged: {
        Config.options.audio.protection.maxAllowedIncrease = value;
      }
    }
    ConfigSpinBox {
      title: Translation.tr("Volume limit")
      value: Config.options.audio.protection.maxAllowed
      from: 0
      to: 154 // pavucontrol allows up to 153%
      stepSize: 2
      onValueChanged: {
        Config.options.audio.protection.maxAllowed = value;
      }
    }
  }

  ContentSection {
    title: Translation.tr("Battery")

    ConfigSpinBox {
      title: Translation.tr("Low warning")
      value: Config.options.battery.low
      from: 0
      to: 100
      stepSize: 5
      onValueChanged: {
        Config.options.battery.low = value;
      }
    }
    ConfigSpinBox {
      title: Translation.tr("Critical warning")
      value: Config.options.battery.critical
      from: 0
      to: 100
      stepSize: 5
      onValueChanged: {
        Config.options.battery.critical = value;
      }
    }
    ConfigSwitch {
      title: Translation.tr("Automatic suspend")
      description: Translation.tr("Automatically suspends the system when battery is low")
      checked: Config.options.battery.automaticSuspend
      onCheckedChanged: {
        Config.options.battery.automaticSuspend = checked;
      }
    }
    ConfigSpinBox {
      enabled: Config.options.battery.automaticSuspend
      title: Translation.tr("at")
      value: Config.options.battery.suspend
      from: 0
      to: 100
      stepSize: 5
      onValueChanged: {
        Config.options.battery.suspend = value;
      }
    }
    ConfigSpinBox {
      title: Translation.tr("Full warning")
      value: Config.options.battery.full
      from: 0
      to: 101
      stepSize: 5
      onValueChanged: {
        Config.options.battery.full = value;
      }
    }
  }

  ContentSection {
    title: Translation.tr("Sounds")
    ConfigSwitch {
      title: Translation.tr("Battery")
      checked: Config.options.sounds.battery
      onCheckedChanged: {
        Config.options.sounds.battery = checked;
      }
    }
    ConfigSwitch {
      title: Translation.tr("Pomodoro")
      checked: Config.options.sounds.pomodoro
      onCheckedChanged: {
        Config.options.sounds.pomodoro = checked;
      }
    }
  }

  ContentSection {
    title: Translation.tr("Time")

    ConfigSwitch {
      title: Translation.tr("Second precision")
      description: Translation.tr("Enable if you want clocks to show seconds accurately")
      checked: Config.options.time.secondPrecision
      onCheckedChanged: {
        Config.options.time.secondPrecision = checked;
      }
    }

    ConfigComboBox {
      title: Translation.tr("Time format")
      description: Translation.tr("Select the format for displaying time in the user interface.")
      textRole: "displayName"
      model: [
        {
          displayName: Translation.tr("24h"),
          value: "hh:mm"
        },
        {
          displayName: Translation.tr("24h with seconds"),
          value: "hh:mm:ss"
        },
        {
          displayName: Translation.tr("12h am/pm"),
          value: "h:mm ap"
        },
        {
          displayName: Translation.tr("12h am/pm with seconds"),
          value: "h:mm:ss ap"
        },
        {
          displayName: Translation.tr("12h AM/PM"),
          value: "h:mm AP"
        },
        {
          displayName: Translation.tr("12h AM/PM with seconds"),
          value: "h:mm:ss AP"
        }
      ]
      value: Config.options.time.format
      onSelected: newValue => {
        if (newValue === "hh:mm") {
          Quickshell.execDetached(["bash", "-c", `sed -i 's/\\TIME12\\b/TIME/' '${FileUtils.trimFileProtocol(Directories.config)}/hypr/hyprlock.conf'`]);
        } else {
          Quickshell.execDetached(["bash", "-c", `sed -i 's/\\TIME\\b/TIME12/' '${FileUtils.trimFileProtocol(Directories.config)}/hypr/hyprlock.conf'`]);
        }

        Config.options.time.format = newValue;
      }
    }
  }

  ContentSection {
    title: Translation.tr("Work safety")

    ConfigSwitch {
      title: Translation.tr("Hide clipboard images copied from sussy sources")
      checked: Config.options.workSafety.enable.clipboard
      onCheckedChanged: {
        Config.options.workSafety.enable.clipboard = checked;
      }
    }
    ConfigSwitch {
      title: Translation.tr("Hide sussy/anime wallpapers")
      checked: Config.options.workSafety.enable.wallpaper
      onCheckedChanged: {
        Config.options.workSafety.enable.wallpaper = checked;
      }
    }
  }
}
