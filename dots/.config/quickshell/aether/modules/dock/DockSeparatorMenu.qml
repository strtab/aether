pragma ComponentBehavior: Bound

import QtQuick
import qs.services
import qs.modules.common
import qs.modules.common.widgets

// Context menu of the dock separator: dock behavior toggles.
PopupMenu {
  id: root

  // Attach at the icon top of the slot (slots and the separator expose iconTop)
  anchorInset: root.anchorItem?.iconTop ?? 0

  readonly property bool magnification: Config.options?.dock?.magnification?.enable ?? true
  // Auto-hide is the inverse of the "pinned" option: a pinned dock is always visible
  readonly property bool autoHide: !(Config.options?.dock?.pinnedOnStartup ?? false)

  PopupMenuToggle {
    label: Translation.tr("Magnification")
    checked: root.magnification
    onTriggered: Config.options.dock.magnification.enable = !root.magnification
  }

  PopupMenuToggle {
    label: Translation.tr("Auto-hide")
    checked: root.autoHide
    // Auto-hide on means not pinned, so turning it off pins the dock
    onTriggered: Config.options.dock.pinnedOnStartup = root.autoHide
  }
}
