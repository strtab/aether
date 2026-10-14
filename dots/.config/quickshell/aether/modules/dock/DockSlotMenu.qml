pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets

// Context menu for a dock slot. Opens above the icon top of the slot and follows it.
PopupWindow {
  id: root

  required property var dockWindow

  // Id of the slot the menu was opened for; live data comes from DockApps
  property string appId: ""
  readonly property var app: DockApps.itemFor(root.appId)
  property bool open: false

  // Slot the menu is attached to. Null once the slot is destroyed.
  property Item slotItem: null
  // Distance between the icon top and the menu, px
  property real gap: 10

  function openFor(id, slot) {
    root.appId = id;
    root.slotItem = slot;
    root.open = true;
  }

  function dismiss() {
    root.open = false;
  }

  // Horizontal center and bottom edge of the menu, in dock window coordinates
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

    // [Desktop Action ...] groups of the .desktop file (or of the system entry for unpinned apps)
    Repeater {
      model: root.app.actions
      delegate: MenuItem {
        required property var modelData
        label: modelData.name
        onTriggered: DockApps.runAction(root.app, modelData)
      }
    }

    MenuItem {
      label: Translation.tr("New window")
      visible: root.app.running && !(root.app.actions.length > 0)
      onTriggered: DockApps.launch(root.app)
    }

    MenuSeparator {
      visible: root.app.running || (root.app.actions.length > 0)
    }

    MenuItem {
      readonly property bool pinned: DockApps.isPinned(root.app.appId)
      label: pinned ? Translation.tr("Remove from dock") : Translation.tr("Keep in dock")
      onTriggered: {
        if (pinned)
          DockApps.unpinApp(root.app.appId);
        else
          DockApps.pinApp(root.app.appId);
      }
    }

    MenuSeparator {}

    MenuItem {
      label: Translation.tr("Force quit")
      danger: true
      visible: root.app.running
      onTriggered: DockApps.forceKill(root.app)
    }

    MenuItem {
      label: Translation.tr("Quit")
      visible: root.app.running
      onTriggered: DockApps.quit(root.app)
    }

    MenuItem {
      label: Translation.tr("Open")
      visible: !root.app.running
      onTriggered: DockApps.launch(root.app)
    }
  }
}
