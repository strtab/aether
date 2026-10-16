pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import qs.services
import qs.modules.common

// One slot of the file section: a file or a directory from the config list, or the trash.
// Follows the same layout and magnification protocol as DockSlot (restCenters, iconPx, widthFactor).
Item {
  id: slot

  // Dock PanelWindow: metrics, hover and menu state
  required property var dock

  // Filled in by the owner
  property string slotKey: ""
  property int order: 0
  property bool isTrash: false
  property string label: ""
  property string iconSource: ""
  // Shown when iconSource cannot be loaded (the type icon of an image preview)
  property string fallbackSource: ""
  // The icon is the file itself (an image), so it is not desaturated
  property bool isPreview: false
  // Path of the file or directory. Empty for the trash.
  property string itemPath: ""

  // Position in the row. Files come after the apps, the trash comes last.
  readonly property real sortKey: slot.isTrash ? 100000 : 1000 + slot.order
  // The dock reads this on every slot kind
  readonly property bool leaving: false
  readonly property string tooltipText: slot.label

  // ------------------------------------------------------------- presence

  // 0 = collapsed, 1 = full width. A new slot grows from 0, which expands the capsule smoothly
  // (not during startup).
  property real widthFactor: DockApps.settled ? 0.0 : 1.0

  Component.onCompleted: slot.widthFactor = 1.0

  Behavior on widthFactor {
    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
  }

  clip: slot.widthFactor < 1.0
  Layout.preferredWidth: slot.dock.slotWidth * (slot.iconPx / slot.dock.iconSize) * slot.widthFactor
  Layout.fillHeight: true
  z: slot.hovered ? 20 : (slot.growSize > 0 ? 10 : 0)

  // ---------------------------------------------------------- magnification

  // Same math as DockSlot: computed against the resting layout, so the zoom does not feed back
  readonly property real restCenter: slot.dock.restCenters[slot.slotKey] ?? 0
  readonly property real distanceToCursor: slot.dock.zoomActive ? Math.abs(slot.dock.hoverOffset - slot.restCenter) / slot.dock.slotWidth : -1
  readonly property bool hovered: slot.distanceToCursor >= 0 && slot.distanceToCursor < 0.5

  readonly property real zoomRadius: slot.dock.zoomRadius
  readonly property real zoomPlateau: slot.dock.zoomPlateau

  readonly property real zoomMultiplier: {
    const d = slot.distanceToCursor;
    if (d < 0)
      return 0.0;
    if (d <= slot.zoomPlateau)
      return 1.0;
    if (d >= slot.zoomRadius)
      return 0.0;
    const t = (d - slot.zoomPlateau) / (slot.zoomRadius - slot.zoomPlateau);
    return 0.5 * (1.0 + Math.cos(Math.PI * t));
  }

  // A file dragged over the trash zooms it, like the cursor would
  readonly property bool dropping: slot.isTrash && dropArea.containsDrag

  property int growSize: Math.round(Math.max(slot.zoomMultiplier, slot.dropping ? 1.0 : 0.0) * slot.dock.zoomPx)
  readonly property real iconPx: slot.dock.iconSize + slot.growSize
  // Top edge of the icon in slot coordinates
  readonly property real iconTop: slot.height - slot.dock.iconBottomMargin - slot.iconPx

  Behavior on growSize {
    NumberAnimation {
      duration: slot.dock.zoomDuration
      easing.type: Easing.InOutQuad
    }
  }

  // ---------------------------------------------------------------- state

  readonly property bool menuTarget: slot.dock.menuOpen && slot.dock.menuFileKey === slot.slotKey
  readonly property bool pressedLeft: mouseArea.pressed && (mouseArea.pressedButtons & Qt.LeftButton) !== 0
  readonly property bool dimmed: slot.menuTarget || slot.pressedLeft
  readonly property bool desaturate: slot.dock.monochrome && !slot.isPreview

  // ---------------------------------------------------------------- icon

  DockIcon {
    id: icon
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
    anchors.bottomMargin: slot.dock.iconBottomMargin
    width: slot.iconPx
    height: slot.iconPx
    transformOrigin: Item.Bottom
    iconSource: slot.iconSource
    fallbackSource: slot.fallbackSource
    resetToken: DockApps.iconEpoch
    // Fixed raster size so magnification and resizing do not reload the image
    sourceSize: Qt.size(slot.dock.rasterSize, slot.dock.rasterSize)

    layer.smooth: true
    layer.enabled: slot.desaturate || slot.dimmed
    layer.effect: MultiEffect {
      saturation: slot.desaturate ? -1 : 0
      brightness: slot.dimmed ? -0.25 : 0
    }
  }

  // ----------------------------------------------------------------- input

  function activate() {
    if (slot.isTrash)
      DockFiles.openTrash();
    else
      DockFiles.open(slot.itemPath);
  }

  MouseArea {
    id: mouseArea
    anchors.fill: parent
    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
    onClicked: mouse => {
      if (mouse.button === Qt.LeftButton)
        slot.activate();
      else
        slot.dock.openFileMenu(slot);
    }
  }

  // Dropping on the trash moves the files to the trash. Dropping anywhere else on the dock
  // is handled by the dock window and adds the paths to the config list.
  DropArea {
    id: dropArea
    anchors.fill: parent
    enabled: slot.isTrash
    keys: ["text/uri-list"]
    onEntered: drag => drag.accept(Qt.CopyAction)
    onDropped: drop => {
      if (!drop.hasUrls)
        return;
      // Copy, so the source file manager never removes the original itself
      drop.accept(Qt.CopyAction);
      DockFiles.trashUrls(drop.urls);
    }
  }
}
