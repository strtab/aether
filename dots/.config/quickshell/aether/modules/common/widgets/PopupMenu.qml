pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common

// Standard context menu. It attaches to any Item, in any window, and closes on focus loss.
// Put PopupMenuItem, PopupMenuToggle and PopupMenuSeparator inside it; a Repeater of them works too.
//
// Usage (menu below a bar button):
//   PopupMenu {
//     id: menu
//     edge: Edges.Bottom
//     PopupMenuItem { label: "Open"; onTriggered: doSomething() }
//     PopupMenuSeparator {}
//     PopupMenuToggle { label: "Flag"; checked: flag; onTriggered: flag = !flag }
//   }
//   MouseArea { onClicked: menu.toggleFor(parent) }
PopupWindow {
  id: root

  property bool open: false

  // Item the menu is attached to. Null once it is destroyed, which hides the menu.
  property Item anchorItem: null
  // Window that holds anchorItem. Found automatically, set it only for unusual setups.
  property var anchorWindow: root.anchorItem ? root.anchorItem.QsWindow.window : null
  // Side of anchorItem the menu opens towards: Edges.Top, Edges.Bottom, Edges.Left or Edges.Right
  property int edge: Edges.Top
  // Distance between the attach point and the menu, px
  property real gap: 10
  // Moves the attach point from the edge of anchorItem towards its inside, px.
  // For example a dock slot attaches at its icon top, not at the top of the slot.
  property real anchorInset: 0
  property real menuWidth: 200

  // Children declared where the menu is used land in the menu column
  default property alias content: menuCol.data

  function openFor(item) {
    root.anchorItem = item;
    root.open = true;
  }

  // Opens the menu, or closes it when it is already open for the same item
  function toggleFor(item) {
    if (root.open && root.anchorItem === item)
      root.dismiss();
    else
      root.openFor(item);
  }

  function dismiss() {
    root.open = false;
  }

  // Position of an item in window coordinates, summed up the parent chain. Only plain property
  // reads, so bindings that use it follow the item when it moves or resizes. Scale and rotation
  // of the ancestors are not taken into account.
  function originOf(item) {
    let x = 0;
    let y = 0;
    for (let it = item; it; it = it.parent) {
      x += it.x;
      y += it.y;
    }
    return Qt.point(x, y);
  }

  // Attach point in window coordinates: the middle of the chosen side of anchorItem
  readonly property point _point: {
    const item = root.anchorItem;
    if (!item)
      return Qt.point(0, 0);
    const o = root.originOf(item);
    const inset = root.anchorInset;
    const gap = root.gap;
    switch (root.edge) {
    case Edges.Bottom:
      return Qt.point(o.x + item.width / 2, o.y + item.height - inset + gap);
    case Edges.Left:
      return Qt.point(o.x + inset - gap, o.y + item.height / 2);
    case Edges.Right:
      return Qt.point(o.x + item.width - inset + gap, o.y + item.height / 2);
    default:
      return Qt.point(o.x + item.width / 2, o.y + inset - gap);
    }
  }

  anchor.window: root.anchorWindow
  anchor.rect.x: root._point.x
  anchor.rect.y: root._point.y
  anchor.rect.width: 1
  anchor.rect.height: 1
  anchor.edges: root.edge
  anchor.gravity: root.edge
  anchor.adjustment: PopupAdjustment.Slide

  implicitWidth: root.menuWidth
  implicitHeight: menuCol.implicitHeight + 12
  visible: root.open && root.anchorItem !== null && root.anchorWindow !== null
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

    // The menu rows find their menu through this property (see PopupMenuItem)
    readonly property var popupMenu: root
  }
}
