import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
  forceWidth: true

  ContentSection {

    title: Translation.tr("Keyboard")

    ConfigInput {
      title: Translation.tr("Keyboard layout")
      description: Translation.tr("Examples: us, es, latam")
      placeholderText: Translation.tr("Keyboard layout")
      text: Config.options.hyprland.input.kbLayout
      onTextChanged: {
        Config.options.hyprland.input.kbLayout = text;
        HyprlandConfig.set("input:kb_layout", text);
      }
    }

    ConfigSwitch {
      title: Translation.tr("Numlock by default")
      checked: Config.options.hyprland.input.numlock
      onCheckedChanged: {
        Config.options.hyprland.input.numlock = checked;
        HyprlandConfig.set("input:numlock_by_default", checked ? 1 : 0);
      }
    }

    ConfigSpinBox {
      title: Translation.tr("Repeat delay (ms)")
      value: Config.options.hyprland.input.repeatDelay
      from: 100
      to: 1000
      stepSize: 10
      onValueChanged: {
        Config.options.hyprland.input.repeatDelay = value;
        HyprlandConfig.set("input:repeat_delay", value);
      }
    }

    ConfigSpinBox {
      title: Translation.tr("Repeat rate")
      value: Config.options.hyprland.input.repeatRate
      from: 10
      to: 100
      stepSize: 1
      onValueChanged: {
        Config.options.hyprland.input.repeatRate = value;
        HyprlandConfig.set("input:repeat_rate", value);
      }
    }

    ConfigComboBox {
      title: Translation.tr("Follow mouse")
      description: Translation.tr("How moving the cursor affects window focus")
      value: Config.options.hyprland.input.followMouse
      onSelected: newValue => {
        Config.options.hyprland.input.followMouse = newValue;
        HyprlandConfig.set("input:follow_mouse", newValue);
      }
      model: [
        {
          displayName: Translation.tr("Disabled"),
          value: 0
        },
        {
          displayName: Translation.tr("Full"),
          value: 1
        },
        {
          displayName: Translation.tr("Loose"),
          value: 2
        },
        {
          displayName: Translation.tr("Explicit"),
          value: 3
        },
      ]
    }
  }
}
