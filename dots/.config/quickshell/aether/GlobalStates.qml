pragma Singleton
pragma ComponentBehavior: Bound
import qs.modules.common
import qs.services
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

Singleton {
  id: root
  property bool barOpen: true
  property bool sidebarLeftOpen: false
  property bool sidebarRightOpen: false
  property bool notificationCenterOpen: false
  property bool mediaControlsOpen: false
  property bool osdBrightnessOpen: false
  property bool osdVolumeOpen: false
  property bool oskOpen: false
  property bool overviewOpen: false
  property bool regionSelectorOpen: false
  property bool searchOpen: false
  property bool screenLocked: false
  property bool screenLockContainsCharacters: false
  property bool screenUnlockFailed: false
  property bool sessionOpen: false
  property bool superDown: false
  property bool superReleaseMightTrigger: true
  property bool wallpaperSelectorOpen: false
  property bool workspaceShowNumbers: false

  onSidebarRightOpenChanged: {
    if (GlobalStates.sidebarRightOpen) {
      GlobalStates.notificationCenterOpen = false
      Notifications.timeoutAll();
    }
  }
  onNotificationCenterOpenChanged: {
    if (GlobalStates.notificationCenterOpen) {
      GlobalStates.sidebarRightOpen = false
      Notifications.timeoutAll();
      Notifications.markAllRead();
    }
  }

  GlobalShortcut {
    name: "superDown"
    description: "Super key is held"

    onPressed: {
      root.superDown = true;
    }
    onReleased: {
      root.superDown = false;
    }
  }
}
