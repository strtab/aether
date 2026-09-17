import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

Item {
  id: root
  readonly property HyprlandMonitor monitor: Hyprland.monitorFor(root.QsWindow.window?.screen)
  readonly property Toplevel activeWindow: ToplevelManager.activeToplevel

  property string activeWindowAddress: `0x${activeWindow?.HyprlandToplevel?.address}`
  property bool focusingThisMonitor: HyprlandData.activeWorkspace?.monitor == monitor?.name
  property var biggestWindow: HyprlandData.biggestWindowForWorkspace(HyprlandData.monitors[root.monitor?.id]?.activeWorkspace.id)

  implicitWidth: rowLayout.implicitWidth

  function trimLeading(s) {
    return s ? s.replace(/^\s+/, "") : s;
  }

  function clear(s) {
    if (!s) return s;
    const cleared = s.replace(/^.*\./, "");
    return cleared.charAt(0).toUpperCase() + cleared.slice(1);
  }

  RowLayout {
    id: rowLayout
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter

    StyledText {
      Layout.fillHeight: true
      font.pixelSize: Appearance.font.pixelSize.large
      font.family: Appearance.font.family.numbers
      color: Appearance.colors.onMenubarBackground
      text: root.focusingThisMonitor && root.activeWindow?.activated && root.biggestWindow ? (root.clear(root.activeWindow?.appId)) : (root.clear(root.biggestWindow?.class)) ?? Translation.tr("Desktop")
    }
  }
}
