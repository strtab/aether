pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

Item {
  id: slot

  required property var modelData
  required property int index
  // Dock PanelWindow: metrics, hover and drag state
  required property var dock

  readonly property var app: DockApps.itemFor(slot.modelData)

  Layout.preferredWidth: slot.dock.slotWidth
  Layout.fillHeight: true

  readonly property int maxDots: (Config.options?.dock?.iconSize / 10)
  readonly property real dotWidthFocused: (Config.options?.dock?.iconSize / 13)
  readonly property real dotWidthInactive: (Config.options?.dock?.iconSize / 13)
  readonly property real dotHeight: (Config.options?.dock?.iconSize / 13)

  // ------------------------------------------------------------ drag shift

  property real dragXOffset: 0
  property real shiftOffset: {
    const source = slot.dock.dragSourceIndex;
    const target = slot.dock.dragTargetIndex;
    if (source === -1 || target === -1 || slot.index === source)
      return 0;
    if (source < target)
      return (slot.index > source && slot.index <= target) ? -slot.dock.slotWidth : 0;
    if (source > target)
      return (slot.index >= target && slot.index < source) ? slot.dock.slotWidth : 0;
    return 0;
  }

  Behavior on shiftOffset {
    NumberAnimation {
      duration: Appearance.animation.hover.duration
      easing.type: Easing.OutQuad
    }
  }

  transform: Translate {
    x: slot.index === slot.dock.dragSourceIndex ? slot.dragXOffset : slot.shiftOffset
  }

  z: slot.index === slot.dock.dragSourceIndex ? 100 : (slot.hovered ? 20 : (slot.growSize > 0 ? 10 : 0))

  // ---------------------------------------------------------- magnification

  readonly property bool hovered: slot.dock.zoomHoverX >= slot.x && slot.dock.zoomHoverX < slot.x + slot.width
  // Distance from the cursor to the slot center, in slot widths
  readonly property real distanceToCursor: slot.dock.zoomHoverX < 0 ? -1 : Math.abs(slot.dock.zoomHoverX - (slot.x + slot.width / 2)) / slot.dock.slotWidth
  readonly property real zoomMultiplier: {
    const d = slot.distanceToCursor;
    if (d < 0)
      return 0.0;
    if (d <= 0.5)
      return 1.0 - d;
    if (d < 1.5)
      return 0.5 * (1.5 - d);
    return 0.0;
  }
  property int growSize: Math.round(slot.zoomMultiplier * slot.dock.zoomPx)
  readonly property real iconPx: slot.dock.iconSize + slot.growSize

  Behavior on growSize {
    NumberAnimation {
      duration: 30
      easing.type: Easing.InOutQuad
    }
  }

  // ---------------------------------------------------------------- state

  readonly property bool running: slot.app.running
  readonly property bool isActive: slot.app.toplevels.some(t => t.activated === true)
  readonly property int focusedIndex: slot.app.toplevels.findIndex(t => t.activated === true)

  property real bounceLift: 0.0
  property bool launching: false

  onRunningChanged: {
    if (slot.running)
      slot.launching = false;
  }

  onLaunchingChanged: {
    if (slot.launching)
      bounceAnim.restart();
    else
      bounceAnim.stop();
  }

  // Safety net: stop bouncing when the app never shows a window
  Timer {
    interval: 80000
    running: slot.launching
    onTriggered: slot.launching = false
  }

  function bounce() {
    bounceAnim.restart();
  }

  // Hop heights in px, derived from the icon size
  readonly property real bouncePeak1: slot.dock.iconSize * Appearance.animation.dockBounce.peakRatio
  readonly property real bouncePeak2: slot.bouncePeak1 * Appearance.animation.dockBounce.decay

  SequentialAnimation {
    id: bounceAnim
    loops: slot.launching ? Animation.Infinite : 1
    onStopped: {
      slot.bounceLift = 0.0;
    }

    // Hop 1: up
    NumberAnimation {
      target: slot
      property: "bounceLift"
      from: 0
      to: slot.bouncePeak1
      duration: Appearance.animation.dockBounce.hop1Half
      easing.type: Easing.BezierSpline
      easing.bezierCurve: Appearance.animation.dockBounce.riseCurve
    }
    // Hop 1: down
    NumberAnimation {
      target: slot
      property: "bounceLift"
      from: slot.bouncePeak1
      to: 0
      duration: Appearance.animation.dockBounce.hop1Half
      easing.type: Easing.BezierSpline
      easing.bezierCurve: Appearance.animation.dockBounce.fallCurve
    }
    // Hop 2: up
    NumberAnimation {
      target: slot
      property: "bounceLift"
      from: 0
      to: slot.bouncePeak2
      duration: Appearance.animation.dockBounce.hop2Half
      easing.type: Easing.BezierSpline
      easing.bezierCurve: Appearance.animation.dockBounce.riseCurve
    }
    // Hop 2: down
    NumberAnimation {
      target: slot
      property: "bounceLift"
      from: slot.bouncePeak2
      to: 0
      duration: Appearance.animation.dockBounce.hop2Half
      easing.type: Easing.BezierSpline
      easing.bezierCurve: Appearance.animation.dockBounce.fallCurve
    }
  }

  Image {
    id: icon
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
    anchors.bottomMargin: slot.dock.iconBottomMargin + slot.bounceLift
    width: slot.iconPx
    height: slot.iconPx
    transformOrigin: Item.Bottom
    source: slot.app.icon
    // Fixed raster size so magnification does not reload the image
    sourceSize: Qt.size(slot.dock.iconSize + slot.dock.zoomPx, slot.dock.iconSize + slot.dock.zoomPx)
    fillMode: Image.PreserveAspectFit
    asynchronous: true
    mipmap: true
    smooth: true

    layer.enabled: slot.dock.monochrome
    layer.effect: MultiEffect {
      saturation: -0.1
      colorization: 1.0
      colorizationColor: Appearance.colors.colPrimary
      brightness: slot.dock.menuOpen ? -0.2 : 0
    }
  }

  // Window indicator dots. Anchored to the slot bottom, never move with magnification.
  Row {
    id: dots
    visible: slot.running && !mouseArea.isDragging
    spacing: 3
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 4

    Repeater {
      model: Math.min(slot.app.toplevels.length, slot.maxDots)
      delegate: Rectangle {
        id: dot
        required property int index
        readonly property bool focused: slot.isActive && (slot.app.toplevels.length <= 1 || dot.index === slot.focusedIndex)
        width: dot.focused ? slot.dotWidthFocused : slot.dotWidthInactive
        height: slot.dotHeight
        radius: Appearance.rounding.full
        color: dot.focused ? Appearance.colors.colPrimary : ColorUtils.transparentize(Appearance.colors.colOnLayer0, 0.5)

        Behavior on width {
          animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }
        Behavior on color {
          animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }
      }
    }
  }

  PopupToolTip {
    id: tooltip
    extraVisibleCondition: slot.hovered && slot.dock.dragSourceIndex === -1 && !slot.dock.menuOpen
    text: slot.app.name
    anchors.bottom: icon.top
    anchors.horizontalCenter: icon.horizontalCenter
    anchors.bottomMargin: 10
  }

  // ----------------------------------------------------------------- input

  MouseArea {
    id: mouseArea
    anchors.fill: parent
    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
    preventStealing: true

    property point pressPos: Qt.point(0, 0)
    property real grabX: 0
    property bool isDragging: false
    property bool dragOccurred: false

    function endDrag() {
      slot.dragXOffset = 0;
      slot.dock.dragSourceIndex = -1;
      slot.dock.dragTargetIndex = -1;
      mouseArea.isDragging = false;
      DockApps.dragging = false;
    }

    onPressed: mouse => {
      if (mouse.button !== Qt.LeftButton)
        return;
      pressPos = Qt.point(mouse.x, mouse.y);
      grabX = mouse.x;
      isDragging = false;
      dragOccurred = false;
    }

    onPositionChanged: mouse => {
      if (!(mouse.buttons & Qt.LeftButton))
        return;

      if (!isDragging && Math.hypot(mouse.x - pressPos.x, mouse.y - pressPos.y) > 8) {
        isDragging = true;
        dragOccurred = true;
        DockApps.dragging = true;
        slot.dock.dragSourceIndex = slot.index;
        slot.dock.dragTargetIndex = slot.index;
      }

      if (isDragging) {
        const cursorX = slot.mapToItem(slot.parent, mouse.x, 0).x;
        slot.dragXOffset = cursorX - slot.x - grabX;
        // Pinned apps stay inside the pinned area; a running-only app may land right after it
        const maxIndex = slot.app.pinned ? DockApps.pinnedCount - 1 : DockApps.pinnedCount;
        slot.dock.dragTargetIndex = Math.max(0, Math.min(maxIndex, slot.dock.slotIndexAt(cursorX)));
      }
    }

    onReleased: mouse => {
      if (mouse.button !== Qt.LeftButton || !isDragging)
        return;
      const source = slot.dock.dragSourceIndex;
      const target = slot.dock.dragTargetIndex;
      const appId = slot.app.appId;
      endDrag();
      if (target !== -1 && target !== source)
        DockApps.moveToPinnedIndex(appId, target);
    }

    onCanceled: {
      endDrag();
      dragOccurred = false;
    }

    onClicked: mouse => {
      if (dragOccurred) {
        dragOccurred = false;
        return;
      }
      if (mouse.button === Qt.RightButton) {
        slot.dock.openSlotMenu(slot);
      } else if (mouse.button === Qt.MiddleButton) {
        DockApps.launch(slot.app);
      } else if (slot.running) {
        DockApps.focus(slot.app);
      } else {
        slot.launching = true;
        DockApps.launch(slot.app);
      }
    }
  }
}
