pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets

// Context menu of the dock separator: dock behavior toggles. Opens above the separator.
PopupWindow {
  id: root

  required property var dockWindow

  property bool open: false

  // Item the menu is attached to (the separator). Null once it is destroyed.
  property Item slotItem: null
  // Distance between the icon top and the menu, px
  property real gap: 20

  readonly property bool magnification: Config.options?.dock?.magnification?.enable ?? true
  // Auto-hide is the inverse of the "pinned" option: a pinned dock is always visible
  readonly property bool autoHide: !(Config.options?.dock?.pinnedOnStartup ?? false)

  function openFor(item) {
    root.slotItem = item;
    root.open = true;
  }

  function dismiss() {
    root.open = false;
  }

  anchor.window: root.dockWindow
  anchor.rect.x: root.slotItem ? root.dockWindow.iconCenterX(root.slotItem) : 0
  anchor.rect.y: root.slotItem ? root.dockWindow.iconTop(root.slotItem) - root.gap : 0
  anchor.rect.width: 1
  anchor.rect.height: 1
  anchor.edges: Edges.Top
  anchor.gravity: Edges.Top
  anchor.adjustment: PopupAdjustment.Slide

  implicitWidth: 200
  implicitHeight: menuCol.implicitHeight + 12
  visible: root.open
  color: "transparent"

  onOpenChanged: {
    if (root.open)
      GlobalFocusGrab.addDismissable(root);
    else
      GlobalFocusGrab.removeDismissable(root);
  }

  Connections {
    target: GlobalFocusGrab
    function onDismissed() {
      root.open = false;
    }
  }

  component MenuToggle: Rectangle {
    id: item
    property string label: ""
    property bool checked: false
    signal triggered

    Layout.fillWidth: true
    Layout.preferredHeight: 28
    radius: Appearance.rounding.unsharpen
    color: area.containsMouse ? Appearance.colors.colLayer1Hover : "transparent"

    StyledText {
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.leftMargin: 10
      anchors.rightMargin: 32
      anchors.verticalCenter: parent.verticalCenter
      text: item.label
      elide: Text.ElideRight
      color: Appearance.colors.colOnLayer1
      style: Appearance.font.style.menu
    }

    // Material Symbols ligature name, shown only when the option is on
    Text {
      anchors.right: parent.right
      anchors.rightMargin: 10
      anchors.verticalCenter: parent.verticalCenter
      visible: item.checked
      text: "check"
      font.family: Appearance.font.family.iconMaterial
      font.pixelSize: 16
      color: Appearance.colors.colOnLayer1
    }

    MouseArea {
      id: area
      anchors.fill: parent
      hoverEnabled: true
      onClicked: {
        root.dismiss();
        item.triggered();
      }
    }
  }

  Rectangle {
    anchors.fill: parent
    color: Appearance.colors.colLayer1Base
    border.width: 1
    border.color: Appearance.colors.colLayer0Border
    radius: Appearance.rounding.small
  }

  ColumnLayout {
    id: menuCol
    anchors.fill: parent
    anchors.margins: 6
    spacing: 2

    MenuToggle {
      label: Translation.tr("Magnification")
      checked: root.magnification
      onTriggered: Config.options.dock.magnification.enable = !root.magnification
    }

    MenuToggle {
      label: Translation.tr("Auto-hide")
      checked: root.autoHide
      // Auto-hide on means not pinned, so turning it off pins the dock
      onTriggered: Config.options.dock.pinnedOnStartup = root.autoHide
    }
  }
}
