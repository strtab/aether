pragma ComponentBehavior: Bound

import QtQuick
import qs.services
import qs.modules.common
import qs.modules.common.widgets

// Context menu for a slot of the file section.
PopupMenu {
  id: root

  // Attach at the icon top of the slot (slots and the separator expose iconTop)
  anchorInset: root.anchorItem?.iconTop ?? 0

  property string slotKey: ""
  property string itemPath: ""
  property bool isTrash: false

  function openForFile(slot) {
    root.slotKey = slot.slotKey;
    root.itemPath = slot.itemPath;
    root.isTrash = slot.isTrash;
    root.openFor(slot);
  }

  PopupMenuItem {
    label: Translation.tr("Open")
    onTriggered: {
      if (root.isTrash)
        DockFiles.openTrash();
      else
        DockFiles.open(root.itemPath);
    }
  }

  PopupMenuItem {
    label: Translation.tr("Show in folder")
    visible: !root.isTrash
    onTriggered: DockFiles.showInFolder(root.itemPath)
  }

  PopupMenuSeparator {
    visible: !root.isTrash || DockFiles.trashFull
  }

  PopupMenuItem {
    label: Translation.tr("Remove from dock")
    visible: !root.isTrash
    onTriggered: DockFiles.remove(root.itemPath)
  }

  PopupMenuItem {
    label: Translation.tr("Empty Trash")
    danger: true
    visible: root.isTrash && DockFiles.trashFull
    onTriggered: DockFiles.emptyTrash()
  }
}
