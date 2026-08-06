import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.services
import qs.modules.common
import qs.modules.common.widgets

Item {
  id: root

  property string currentLayoutCode: "us"

  // implicitWidth: rowLayout.implicitWidth
  width: 24
  implicitHeight: Appearance.sizes.barHeight

  Connections {
    target: Hyprland
    function onRawEvent(event) {
      if (event.name === "activelayout")
        proc.running = true;
    }
  }

  Process {
    id: proc
    running: true
    command: ["hyprctl", "devices", "-j"]
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          var devices = JSON.parse(this.text);
          for (var device of devices.keyboards) {
            if (device.main) {
              root.currentLayoutCode = device.active_keymap;
              break;
            }
          }
        } catch (e) {}
      }
    }
  }

  RowLayout {
    id: rowLayout
    anchors.centerIn: parent

    StyledText {
      text: root.currentLayoutCode.slice(0, 2).toLowerCase()
      color: Appearance.colors.onMenubarBackground
      font.pixelSize: Appearance.font.pixelSize.large + 1
      Layout.fillHeight: true
      animateChange: true
    }
  }
}
