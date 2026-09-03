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

  ContentSection {
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
}
