pragma ComponentBehavior: Bound

import QtQuick
import qs.services
import qs.modules.common
import qs.modules.common.widgets

// Context menu for an app slot of the dock.
PopupMenu {
  id: root

  // Attach at the icon top of the slot (slots and the separator expose iconTop)
  anchorInset: root.anchorItem?.iconTop ?? 0

  // Id of the slot the menu was opened for; live data comes from DockApps
  property string appId: ""
  readonly property var app: DockApps.itemFor(root.appId)

  function openForApp(id, slot) {
    root.appId = id;
    root.openFor(slot);
  }

  // [Desktop Action ...] groups of the .desktop file (or of the system entry for unpinned apps)
  Repeater {
    model: root.app.actions
    delegate: PopupMenuItem {
      required property var modelData
      label: modelData.name
      onTriggered: DockApps.runAction(root.app, modelData)
    }
  }

  PopupMenuItem {
    label: Translation.tr("New window")
    visible: root.app.running && !(root.app.actions.length > 0)
    onTriggered: DockApps.launch(root.app)
  }

  PopupMenuSeparator {
    visible: root.app.running || (root.app.actions.length > 0)
  }

  PopupMenuItem {
    readonly property bool pinned: DockApps.isPinned(root.app.appId)
    label: pinned ? Translation.tr("Remove from dock") : Translation.tr("Keep in dock")
    onTriggered: {
      if (pinned)
        DockApps.unpinApp(root.app.appId);
      else
        DockApps.pinApp(root.app.appId);
    }
  }

  PopupMenuSeparator {}

  PopupMenuItem {
    label: Translation.tr("Force quit")
    danger: true
    visible: root.app.running
    onTriggered: DockApps.forceKill(root.app)
  }

  PopupMenuItem {
    label: Translation.tr("Quit")
    visible: root.app.running
    onTriggered: DockApps.quit(root.app)
  }

  PopupMenuItem {
    label: Translation.tr("Open")
    visible: !root.app.running
    onTriggered: DockApps.launch(root.app)
  }
}
