import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import Qt.labs.synchronizer
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
  id: overviewScope

  PanelWindow {
    id: panelWindow
    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(panelWindow.screen)
    property bool monitorIsFocused: (Hyprland.focusedMonitor?.id == monitor?.id)
    visible: GlobalStates.overviewOpen

    WlrLayershell.namespace: "quickshell:overview"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: GlobalStates.overviewOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    color: "transparent"

    mask: Region {
      item: GlobalStates.overviewOpen ? columnLayout : null
    }

    anchors {
      top: true
      bottom: true
      left: true
      right: true
    }

    Connections {
      target: GlobalStates
      function onOverviewOpenChanged() {
        if (!GlobalStates.overviewOpen) {
          GlobalFocusGrab.dismiss();
        } else {
          GlobalFocusGrab.addDismissable(panelWindow);
        }
      }
    }

    Connections {
      target: GlobalFocusGrab
      function onDismissed() {
        GlobalStates.overviewOpen = false;
      }
    }
    implicitWidth: columnLayout.implicitWidth
    implicitHeight: columnLayout.implicitHeight

    Column {
      id: columnLayout
      visible: GlobalStates.overviewOpen
      anchors {
        horizontalCenter: parent.horizontalCenter
        top: parent.top
      }
      spacing: -8

      Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) {
          GlobalStates.overviewOpen = false;
        }
      }

      Loader {
        id: overviewLoader
        anchors.horizontalCenter: parent.horizontalCenter
        active: GlobalStates.overviewOpen
        sourceComponent: OverviewWidget {
          screen: panelWindow.screen
        }
      }
    }
  }

  GlobalShortcut {
    name: "overviewWorkspacesClose"
    description: "Closes overview on press"

    onPressed: {
      GlobalStates.overviewOpen = false;
    }
  }
  GlobalShortcut {
    name: "overviewWorkspacesToggle"
    description: "Toggles overview on press"

    onPressed: {
      GlobalStates.overviewOpen = !GlobalStates.overviewOpen;
    }
  }
}
