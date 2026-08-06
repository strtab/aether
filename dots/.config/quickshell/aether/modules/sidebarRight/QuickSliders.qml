import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.UPower

Rectangle {
  id: root
  property var screen: root.QsWindow.window?.screen
  property var brightnessMonitor: screen ? Brightness.getMonitorForScreen(screen) : null
  implicitWidth: contentItem.implicitWidth + root.horizontalPadding * 2
  implicitHeight: contentItem.implicitHeight + root.verticalPadding * 2
  radius: Appearance.rounding.normal
  color: Appearance.colors.colLayer1
  property real verticalPadding: 4
  property real horizontalPadding: 12
  Column {
    id: contentItem
    anchors {
      fill: parent
      leftMargin: root.horizontalPadding
      rightMargin: root.horizontalPadding
      topMargin: root.verticalPadding
      bottomMargin: root.verticalPadding
    }
    spacing: 2
    Loader {
      anchors {
        left: parent.left
        right: parent.right
      }
      // Only show once we actually have a brightness-capable monitor for this screen
      visible: active
      active: Config.options.sidebar.quickSliders.showBrightness && root.brightnessMonitor != null
      sourceComponent: QuickSlider {
        leftIcon: "brightness_4"
        rightIcon: "brightness_7"
        // optional chaining guards against the monitor disappearing after the loader was created
        value: root.brightnessMonitor?.brightness ?? 0
        onMoved: {
          root.brightnessMonitor?.setBrightness(value);
        }
      }
    }
    Loader {
      anchors {
        left: parent.left
        right: parent.right
      }
      visible: active
      active: Config.options.sidebar.quickSliders.showVolume
      sourceComponent: QuickSlider {
        leftIcon: "volume_mute"
        rightIcon: "volume_up"
        value: Audio.sink?.audio?.volume ?? 0
        onMoved: {
          if (Audio.sink)
            Audio.sink.audio.volume = value;
        }
      }
    }
    Loader {
      anchors {
        left: parent.left
        right: parent.right
      }
      visible: active
      active: Config.options.sidebar.quickSliders.showMic
      sourceComponent: QuickSlider {
        leftIcon: "mic_off"
        rightIcon: "mic"
        value: Audio.source?.audio?.volume ?? 0
        onMoved: {
          if (Audio.source)
            Audio.source.audio.volume = value;
        }
      }
    }
  }
  component QuickSlider: StyledSlider {
    id: quickSlider
    property string materialSymbol: ""
    stopIndicatorValues: []
    ticks: true
    icons: true
  }
}

