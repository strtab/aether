import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import Quickshell.Io
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
  id: root
  property int sidebarWidth: Appearance.sizes.sidebarWidth

  PanelWindow {
    id: panelWindow
    visible: GlobalStates.notificationCenterOpen

    function hide() {
      GlobalStates.notificationCenterOpen = false;
    }

    exclusiveZone: 0
    implicitWidth: sidebarWidth
    WlrLayershell.namespace: "quickshell:notificationCenter"
    // Hyprland 0.49: Focus is always exclusive and setting this breaks mouse focus grab
    // WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    color: "transparent"

    anchors {
      top: true
      right: true
      bottom: true
    }

    onVisibleChanged: {
      if (visible) {
        GlobalFocusGrab.addDismissable(panelWindow);
      } else {
        GlobalFocusGrab.removeDismissable(panelWindow);
      }
    }
    Connections {
      target: GlobalFocusGrab
      function onDismissed() {
        panelWindow.hide();
      }
    }

    Loader {
      id: sidebarContentLoader
      active: GlobalStates.notificationCenterOpen
      anchors {
        fill: parent
        margins: Appearance.sizes.hyprlandGapsOut
        leftMargin: Appearance.sizes.elevationMargin
      }
      width: sidebarWidth - Appearance.sizes.hyprlandGapsOut - Appearance.sizes.elevationMargin
      height: parent.height - Appearance.sizes.hyprlandGapsOut * 2

      focus: GlobalStates.notificationCenterOpen
      Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) {
          panelWindow.hide();
        }
      }

      sourceComponent: Item {
        property int sidebarWidth: Appearance.sizes.sidebarWidth
        property int sidebarPadding: 10

        implicitHeight: sidebarRightBackground.implicitHeight
        implicitWidth: sidebarRightBackground.implicitWidth

        StyledRectangularShadow {
          target: sidebarRightBackground
        }
        Rectangle {
          id: sidebarRightBackground

          anchors.fill: parent
          implicitHeight: parent.height - Appearance.sizes.hyprlandGapsOut * 2
          implicitWidth: sidebarWidth - Appearance.sizes.hyprlandGapsOut * 2
          color: Appearance.colors.colLayer0
          border.width: 1
          border.color: Appearance.colors.colLayer0Border
          radius: Appearance.rounding.screenRounding - Appearance.sizes.hyprlandGapsOut + 1

          NotificationList {
            anchors.fill: parent
            anchors.margins: sidebarPadding
          }
        }
      }
    }
  }

  IpcHandler {
    target: "notifications"

    function toggle(): void {
      GlobalStates.notificationCenterOpen = !GlobalStates.notificationCenterOpen;
    }

    function close(): void {
      GlobalStates.notificationCenterOpen = false;
    }

    function open(): void {
      GlobalStates.notificationCenterOpen = true;
    }
  }

  GlobalShortcut {
    name: "notificationsToggle"
    description: "Toggles right sidebar on press"

    onPressed: {
      GlobalStates.notificationCenterOpen = !GlobalStates.notificationCenterOpen;
    }
  }
  GlobalShortcut {
    name: "notificationsOpen"
    description: "Opens right sidebar on press"

    onPressed: {
      GlobalStates.notificationCenterOpen = true;
    }
  }
  GlobalShortcut {
    name: "notificationsClose"
    description: "Closes right sidebar on press"

    onPressed: {
      GlobalStates.notificationCenterOpen = false;
    }
  }
}
