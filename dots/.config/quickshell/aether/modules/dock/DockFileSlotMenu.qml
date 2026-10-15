pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets

// Context menu for a slot of the file section. Opens above the icon top of the slot.
PopupWindow {
  id: root

  required property var dockWindow

  property string slotKey: ""
  property string itemPath: ""
  property bool isTrash: false
  property bool open: false

  // Slot the menu is attached to. Null once the slot is destroyed.
  property Item slotItem: null
  // Distance between the icon top and the menu, px
  property real gap: 10

  function openFor(slot) {
    root.slotKey = slot.slotKey;
    root.itemPath = slot.itemPath;
    root.isTrash = slot.isTrash;
    root.slotItem = slot;
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

  component MenuItem: Rectangle {
    id: item
    property string label: ""
    property bool danger: false
    signal triggered

    Layout.fillWidth: true
    Layout.preferredHeight: 28
    radius: Appearance.rounding.unsharpen
    color: area.containsMouse ? Appearance.colors.colLayer1Hover : "transparent"

    StyledText {
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.leftMargin: 10
      anchors.rightMargin: 10
      anchors.verticalCenter: parent.verticalCenter
      text: item.label
      elide: Text.ElideRight
      color: item.danger ? Appearance.colors.colError : Appearance.colors.colOnLayer1
      style: Appearance.font.style.menu
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

  component MenuSeparator: Rectangle {
    Layout.fillWidth: true
    Layout.preferredHeight: 1
    Layout.topMargin: 3
    Layout.bottomMargin: 3
    color: Appearance.colors.colOutlineVariant
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

    MenuItem {
      label: Translation.tr("Open")
      onTriggered: {
        if (root.isTrash)
          DockFiles.openTrash();
        else
          DockFiles.open(root.itemPath);
      }
    }

    MenuItem {
      label: Translation.tr("Show in folder")
      visible: !root.isTrash
      onTriggered: DockFiles.showInFolder(root.itemPath)
    }

    MenuSeparator {
      visible: !root.isTrash || DockFiles.trashFull
    }

    MenuItem {
      label: Translation.tr("Remove from dock")
      visible: !root.isTrash
      onTriggered: DockFiles.remove(root.itemPath)
    }

    MenuItem {
      label: Translation.tr("Empty Trash")
      danger: true
      visible: root.isTrash && DockFiles.trashFull
      onTriggered: DockFiles.emptyTrash()
    }
  }
}
