pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

Item {
  id: slot

  required property string appId
  required property int index
  // Dock PanelWindow: metrics, hover and drag state
  required property var dock

  readonly property var app: DockApps.itemFor(slot.appId)

  // ------------------------------------------------------------- presence

  // True while the app is gone and the slot plays its leave animation
  readonly property bool leaving: DockApps.leavingIds[slot.appId] === true
  // 0 = hidden, 1 = fully shown. Drives opacity and scale only. It starts at 1, so the icon of a
  // new slot is shown at once; it is animated only by the leave sequence.
  property real presence: 1.0
  // 0 = collapsed, 1 = full width. Drives the layout width, so the capsule follows it.
  // A new slot grows from 0, which expands the capsule smoothly (not during startup).
  property real widthFactor: DockApps.settled ? 0.0 : 1.0

  transformOrigin: Item.Center
  // While the slot is narrower than its icon, the icon is revealed from the center instead of
  // overlapping the neighbours. Off at full width, so a magnified icon can rise above the slot.
  clip: slot.widthFactor < 1.0
  // The slot is as wide as its icon is large, so the padding around the icon grows
  // with the magnification and the capsule grows with the slots.
  Layout.preferredWidth: slot.dock.slotWidth * (slot.iconPx / slot.dock.iconSize) * slot.widthFactor
  Layout.fillHeight: true
  scale: 0.7 + 0.3 * slot.presence
  opacity: slot.presence

  Behavior on presence {
    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
  }

  Behavior on widthFactor {
    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
  }

  // Collapses the width, and with it the capsule, once the icon has faded out
  Timer {
    id: collapseTimer
    interval: Appearance.animation.elementMoveFast.duration
    repeat: false
    onTriggered: slot.widthFactor = 0.0
  }

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

  // Center of this slot in the resting layout, measured from the dock row center.
  // Magnification is computed against the resting layout, not the live one: the live layout
  // changes with the zoom itself, which would feed back into the zoom and make it jitter.
  // The resting layout uses the slot widths without zoom, so a collapsed slot takes no room.
  readonly property real restCenter: slot.dock.restCenters[slot.appId] ?? 0
  // Distance from the cursor to the resting slot center, in resting slot widths
  readonly property real distanceToCursor: slot.dock.zoomActive ? Math.abs(slot.dock.hoverOffset - slot.restCenter) / slot.dock.slotWidth : -1
  readonly property bool hovered: slot.distanceToCursor >= 0 && slot.distanceToCursor < 0.5

  // Magnetism reach, in resting slot widths: slots farther than this stay at normal size
  readonly property real zoomRadius: slot.dock.zoomRadius
  // Distance around the cursor where the slot gets the full zoom
  readonly property real zoomPlateau: slot.dock.zoomPlateau

  readonly property real zoomMultiplier: {
    const d = slot.distanceToCursor;
    if (d < 0)
      return 0.0;
    if (d <= slot.zoomPlateau)
      return 1.0;
    if (d >= slot.zoomRadius)
      return 0.0;
    // Smooth cosine falloff from 1 at the plateau edge to 0 at the radius
    const t = (d - slot.zoomPlateau) / (slot.zoomRadius - slot.zoomPlateau);
    return 0.5 * (1.0 + Math.cos(Math.PI * t));
  }

  property int growSize: Math.round(slot.zoomMultiplier * slot.dock.zoomPx)
  readonly property real iconPx: slot.dock.iconSize + slot.growSize
  // Top edge of the icon in slot coordinates. The bounce offset is left out on purpose,
  // so the tooltip and the menu do not jitter during a launch bounce.
  readonly property real iconTop: slot.height - slot.dock.iconBottomMargin - slot.iconPx

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
  readonly property bool menuTarget: slot.dock.menuOpen && slot.dock.menuAppId === slot.app.appId
  readonly property bool pressedRunning: mouseArea.pressed && (mouseArea.pressedButtons & Qt.LeftButton) !== 0 && slot.running && !mouseArea.isDragging
  readonly property bool dimmed: slot.menuTarget || slot.pressedRunning

  property real bounceLift: 0.0
  property bool launching: false

  onRunningChanged: {
    if (slot.running)
      slot.launching = false;
  }

  // Starts the bounce. When launching ends the running cycle is not cut: it plays to its end
  // and bounceAnim stops itself (see onRunningChanged there).
  onLaunchingChanged: {
    if (slot.launching && !bounceAnim.running)
      bounceAnim.start();
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

  // One bounce cycle. While the app is launching, a new cycle starts as soon as the previous one
  // ends. `loops` and `running` are deliberately not bound to `launching`: the onLaunchingChanged
  // handler runs before such bindings are re-evaluated, so the animation used to start with the
  // old loop count and play only once.
  SequentialAnimation {
    id: bounceAnim
    loops: 1
    onRunningChanged: {
      if (bounceAnim.running)
        return;
      slot.bounceLift = 0.0;
      if (slot.launching)
        Qt.callLater(bounceAnim.start);
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

  // ---------------------------------------------------------------- icon

  Loader {
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
    anchors.bottomMargin: slot.dock.iconBottomMargin + slot.bounceLift
    asynchronous: true
    sourceComponent: DockIcon {
      width: slot.iconPx
      height: slot.iconPx
      transformOrigin: Item.Bottom
      iconSource: slot.app.icon
      resetToken: DockApps.iconEpoch
      // Fixed raster size so magnification does not reload the image
      sourceSize: Qt.size(slot.dock.iconSize + slot.dock.zoomPx, slot.dock.iconSize + slot.dock.zoomPx)

      layer.smooth: true
      layer.enabled: slot.dock.monochrome || slot.dimmed
      layer.effect: MultiEffect {
        saturation: slot.dock.monochrome ? -1 : 0
        brightness: slot.dimmed ? -0.25 : 0
      }
    }
  }

  // ---------------------------------------------------------------- dots

  // Enter animation: the width grows from 0 to 1
  Component.onCompleted: slot.widthFactor = slot.leaving ? 0.0 : 1.0

  readonly property int maxDots: (Config.options?.dock?.iconSize / 10)
  readonly property real dotWidthFocused: (Config.options?.dock?.iconSize / 13)
  readonly property real dotWidthInactive: (Config.options?.dock?.iconSize / 13)
  readonly property real dotHeight: (Config.options?.dock?.iconSize / 13)

  // Opacity of the indicator dots
  property real dotsOpacity: 1.0

  Behavior on dotsOpacity {
    NumberAnimation {
      duration: DockApps.dotsFadeDuration
      easing.type: Easing.OutQuad
    }
  }

  // Leave sequence: dots fade -> icon fades (width kept) -> width collapses
  onLeavingChanged: {
    if (slot.leaving) {
      slot.dotsOpacity = 0.0;
      leaveTimer.restart();
    } else {
      leaveTimer.stop();
      collapseTimer.stop();
      slot.dotsOpacity = 1.0;
      slot.presence = 1.0;
      slot.widthFactor = 1.0;
    }
  }

  // Starts the icon fade once the dots are gone (no wait when there are no dots)
  Timer {
    id: leaveTimer
    interval: slot.app.dotCount > 0 ? DockApps.dotsFadeDuration : 0
    repeat: false
    onTriggered: {
      slot.presence = 0.0;
      collapseTimer.restart();
    }
  }

  // Window indicator dots. Anchored to the slot bottom, never move with magnification.
  // The count comes from the item data, so a leaving slot keeps its dots until they fade out.
  Row {
    id: dots
    visible: !mouseArea.isDragging
    opacity: slot.dotsOpacity
    spacing: 3
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 4

    Repeater {
      model: Math.min(slot.app.dotCount, slot.maxDots)
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

  // ----------------------------------------------------------------- input

  MouseArea {
    id: mouseArea
    enabled: !slot.leaving
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
      if (mouse.button === Qt.RightButton || mouse.button === Qt.MiddleButton) {
        slot.dock.openSlotMenu(slot);
      } else if (slot.running) {
        DockApps.focus(slot.app);
      } else {
        slot.launching = true;
        DockApps.launch(slot.app);
      }
    }
  }
}
