import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
  forceWidth: true

  ContentSection {
    title: Translation.tr("Touchpad")

    ConfigSwitch {
      title: Translation.tr("Natural scroll")
      checked: Config.options.hyprland.input.touchpad.naturalScroll
      onCheckedChanged: {
        Config.options.hyprland.input.touchpad.naturalScroll = checked;
        HyprlandConfig.set("input:touchpad:natural_scroll", checked ? 1 : 0);
      }
    }

    ConfigSwitch {
      title: Translation.tr("Disable while typing")
      checked: Config.options.hyprland.input.touchpad.disableWhileTyping
      onCheckedChanged: {
        Config.options.hyprland.input.touchpad.disableWhileTyping = checked;
        HyprlandConfig.set("input:touchpad:disable_while_typing", checked ? 1 : 0);
      }
    }

    ConfigSwitch {
      title: Translation.tr("Clickfinger behavior")
      checked: Config.options.hyprland.input.touchpad.clickfingerBehavior
      onCheckedChanged: {
        Config.options.hyprland.input.touchpad.clickfingerBehavior = checked;
        HyprlandConfig.set("input:touchpad:clickfinger_behavior", checked ? 1 : 0);
      }
    }

    ConfigSpinBox {
      title: Translation.tr("Scroll factor")
      value: Math.round(Config.options.hyprland.input.touchpad.scrollFactor * 10)
      from: 1
      to: 30
      stepSize: 1
      onValueChanged: {
        Config.options.hyprland.input.touchpad.scrollFactor = value / 10.0;
        HyprlandConfig.set("input:touchpad:scroll_factor", value / 10.0);
      }
    }
  }
}
