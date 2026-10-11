pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets

// Context menu for a dock slot. Opens above the given point of the dock window.
PopupWindow {
  id: root

  required property var dockWindow

  // Id of the slot the menu was opened for; live data comes from DockApps
  property string appId: ""
  readonly property var app: DockApps.itemFor(root.appId)
  property bool open: false

  // Anchor point in dock window coordinates (horizontal center and bottom edge of the menu)
  property real anchorX: 0
  property real anchorY: 0

  function openFor(id, x, y) {
    root.appId = id;
    root.anchorX = x;
    root.anchorY = y;
    root.open = true;
  }

  function dismiss() {
    root.open = false;
  }

  anchor.window: root.dockWindow
  anchor.rect.x: root.anchorX
  anchor.rect.y: root.anchorY
  anchor.rect.width: 1
  anchor.rect.height: 1
  anchor.edges: Edges.Top
  anchor.gravity: Edges.Top
  anchor.adjustment: PopupAdjustment.Slide

  implicitWidth: 220
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
    radius: Appearance.rounding.unsharpenmore
    color: area.containsMouse ? Appearance.colors.colLayer1Hover : "transparent"

    StyledText {
      anchors.left: parent.left
      anchors.leftMargin: 10
      anchors.verticalCenter: parent.verticalCenter
      text: item.label
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

    StyledText {
      Layout.fillWidth: true
      Layout.leftMargin: 10
      Layout.rightMargin: 10
      Layout.preferredHeight: 24
      verticalAlignment: Text.AlignVCenter
      text: root.app.name
      elide: Text.ElideRight
      color: Appearance.colors.colSubtext
      style: Appearance.font.style.menu
    }

    MenuSeparator {}

    MenuItem {
      label: Translation.tr("Open")
      visible: !root.app.running
      onTriggered: DockApps.launch(root.app)
    }

    MenuItem {
      label: Translation.tr("Quit")
      visible: root.app.running
      onTriggered: DockApps.quit(root.app)
    }

    MenuItem {
      label: Translation.tr("Force quit")
      danger: true
      visible: root.app.running
      onTriggered: DockApps.forceKill(root.app)
    }

    MenuSeparator {}

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
  }
}
