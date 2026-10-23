import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
  id: root
  property bool pinned: Config.options?.dock?.pinnedOnStartup ?? false

  Variants {
    // For each monitor
    model: Quickshell.screens

    PanelWindow {
      id: dockRoot

      required property var modelData
      screen: modelData

      visible: (Config.options?.dock?.enable ?? true) && !GlobalStates.screenLocked

      // Icon size limits for the resize drag on the separator
      readonly property real iconSizeMin: 24
      readonly property real iconSizeMax: 96
      // While the separator is dragged, the new size lives here and is written to the config on release
      property bool resizing: false
      property real resizeSize: -1
      // Size saved in the config. Changes once per resize, so the window and the exclusive zone
      // are not reconfigured on every frame of the animation.
      readonly property real committedIconSize: Config.options?.dock?.iconSize ?? 65
      // Size the dock is heading to: the drag value while resizing, the config value otherwise
      readonly property real targetIconSize: (dockRoot.resizing && dockRoot.resizeSize > 0) ? dockRoot.resizeSize : dockRoot.committedIconSize
      // Size every metric of the dock is derived from. It is animated here, once, so the capsule,
      // the slots and the icons all change together. A Behavior on the capsule width or height
      // would lag behind the slots, which are summed from the same size.
      property real iconSize: dockRoot.targetIconSize

      Behavior on iconSize {
        // Not at startup, where the config value arrives after the default
        enabled: Config.ready && DockApps.settled
        NumberAnimation {
          duration: 110
          easing.type: Easing.OutCubic
        }
      }

      // Distance between the icon top and the tooltip or menu above it. Follows the icon size,
      // including the resize animation (10 px at the default size of 45).
      readonly property real popupGap: dockRoot.iconSize * 0.4

      // Largest size the dock can have. The window is sized for it and never resizes during the animation.
      readonly property real maxIconSize: Math.max(dockRoot.iconSizeMax, dockRoot.committedIconSize)
      // Fixed raster size of the icon images, so neither magnification nor resizing reloads them
      readonly property real rasterSize: dockRoot.maxIconSize + dockRoot.zoomPx
      readonly property bool monochrome: Config.options?.dock?.monochromeIcons ?? true

      // Window preview (Config.options.dock.preview). The logic is below, next to hoveredSlot.
      readonly property bool previewEnabled: Config.options?.dock?.preview?.enable ?? true
      readonly property int previewDelay: Config.options?.dock?.preview?.delay ?? 400
      readonly property int previewSwitchDelay: Config.options?.dock?.preview?.switchDelay ?? 120
      readonly property int previewCloseDelay: Config.options?.dock?.preview?.closeDelay ?? 300
      readonly property real previewThumbHeight: Config.options?.dock?.preview?.thumbHeight ?? 120
      readonly property int previewMaxColumns: Math.max(1, Config.options?.dock?.preview?.maxColumns ?? 4)
      readonly property int previewMaxRows: Math.max(1, Config.options?.dock?.preview?.maxRows ?? 2)
      // Upper bound for the height of the preview panel (thumbnail, title, paddings). The window is
      // sized for it, so it never resizes when the preview opens.
      readonly property real previewHeadroom: dockRoot.previewEnabled ? dockRoot.previewMaxRows * (dockRoot.previewThumbHeight + 30) + (dockRoot.previewMaxRows - 1) * 14 + 28 + 64 : 0
      // Extra icon size at the cursor. Set Config.options.dock.magnification to false to disable.
      readonly property real zoomPx: (Config.options?.dock?.magnification.enable ?? true) ? (Config.options?.dock?.magnification.strength ?? 30) : 0
      // Magnetism reach in resting slot widths
      readonly property real zoomRadius: Config.options?.dock?.magnification.radius ?? 2.5
      readonly property real zoomPlateau: Config.options?.dock?.magnification.plateau ?? 0.5
      // Pause between the cursor entering the dock and the magnification starting, ms
      readonly property int zoomDelay: Config.options?.dock?.magnification.delay ?? 120
      // Duration of one size step of a slot, ms. Higher = slower size changes.
      readonly property int zoomDuration: Config.options?.dock?.magnification.duration ?? 60

      // Smoothed state of the magnification. Every slot derives its size from these two numbers, so no slot
      // has an animation of its own that restarts on each pointer event.
      // zoomCursor follows hoverOffset, zoomLevel follows zoomActive (0 = no zoom, 1 = full zoom).
      property real zoomCursor: 0
      property real zoomLevel: 0
      // Time constants in seconds, derived from the duration of the effect
      readonly property real zoomCursorTau: Math.max(1, dockRoot.zoomDuration) / 6000
      readonly property real zoomLevelTau: Math.max(1, dockRoot.zoomDuration) / 2500

      // Slot width at rest. A magnified slot is wider in the same proportion as its icon.
      readonly property real slotWidth: dockRoot.iconSize + (dockRoot.iconSize / 4)
      readonly property real capsulePadding: 10
      readonly property real capsuleHeight: dockRoot.iconSize + (dockRoot.iconSize / 2)
      readonly property real iconBottomMargin: (dockRoot.capsuleHeight - dockRoot.iconSize) / 2
      readonly property int slotCount: slotRepeater.count

      // File section (files, directories and trash) after the apps, split from them by a thin separator.
      // The separator width is animated, so the capsule grows smoothly when the section appears.
      readonly property bool hasFileSection: DockFiles.itemCount > 0
      readonly property real separatorFullWidth: 13
      property real separatorWidth: dockRoot.hasFileSection ? dockRoot.separatorFullWidth : 0

      Behavior on separatorWidth {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
      }

      // Bumped whenever a slot is created or destroyed. The functions below read it, so
      // bindings that use them are re-evaluated for slots that did not exist before.
      property int layoutRevision: 0

      // Every slot of the row in creation order: apps, files, trash. File slots expose slotKey
      // and sortKey, app slots expose appId and index.
      function slotItems() {
        dockRoot.layoutRevision;
        const items = [];
        for (const repeater of [slotRepeater, fileRepeater, trashRepeater]) {
          for (let i = 0; i < repeater.count; i++) {
            const item = repeater.itemAt(i);
            if (item)
              items.push(item);
          }
        }
        return items;
      }

      // Every width that goes into the layout is a whole number of pixels. A RowLayout rounds the
      // cells that are not whole up, so a fractional slot width made the real row longer than the
      // sum below, and the difference changed from frame to frame while sizes were animated.
      // The capsule sums and the slots use the same rounding, so they always agree.
      //
      // Capsule and resting widths are both summed straight from the slots. Reading the layout's
      // implicitWidth instead would lag behind the slot properties and leave a transient
      // difference between the two, which shows up as the capsule shaking while it resizes.
      function liveRowWidth() {
        let w = Math.round(dockRoot.separatorWidth) + dockRoot.dropGap;
        for (const item of dockRoot.slotItems())
          w += Math.round(dockRoot.slotWidth * (item.iconPx / dockRoot.iconSize) * item.widthFactor);
        return w;
      }

      // Width of the slots without any magnification (follows the leave animation)
      function restRowWidth() {
        let w = Math.round(dockRoot.separatorWidth) + dockRoot.dropGap;
        for (const item of dockRoot.slotItems())
          w += Math.round(dockRoot.slotWidth * item.widthFactor);
        return w;
      }

      // Shift of the capsule center from the window center
      readonly property real capsuleOffset: (0.5 - dockRoot.pivot) * (dockRoot.capsuleWidth - dockRoot.restCapsuleWidth)
      readonly property real capsuleWidth: dockRoot.liveRowWidth() + dockRoot.capsulePadding * 2
      readonly property real restCapsuleWidth: dockRoot.restRowWidth() + dockRoot.capsulePadding * 2
      readonly property var restCenters: dockRoot.computeRestCenters()

      // Where the cursor is along the resting capsule: 0 = left end, 1 = right end.
      // The capsule grows away from the cursor: the side the cursor is on stays in place.
      readonly property real pivot: {
        const rest = dockRoot.restCapsuleWidth;
        return rest > 0 ? Math.max(0, Math.min(1, 0.5 + dockRoot.zoomCursor / rest)) : 0.5;
      }
      readonly property real tooltipHeadroom: 34

      // The window spans the whole screen width and never resizes, so slots coming and going
      // cannot move the capsule. The capsule is centered by an anchor, and the input mask
      // limits input to the capsule.
      anchors.left: true
      anchors.right: true
      anchors.bottom: true
      implicitHeight: dockRoot.maxIconSize * 1.5 + dockRoot.zoomPx + dockRoot.tooltipHeadroom + dockRoot.previewHeadroom + Appearance.sizes.elevationMargin + Appearance.sizes.hyprlandGapsOut
      exclusiveZone: root.pinned ? dockRoot.committedIconSize * 1.5 + Appearance.sizes.hyprlandGapsOut * 2 : 0

      WlrLayershell.namespace: "quickshell:dock"
      WlrLayershell.layer: Appearance.layers.dock
      // The preview takes the keyboard while it is shown (Escape closes it, see previewGrab)
      WlrLayershell.keyboardFocus: dockRoot.previewShown ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
      color: "transparent"

      // Cursor offset from the center of the resting capsule, in px. It is a physical offset, so
      // it stays valid while the capsule moves, grows or shrinks and when slots come and go.
      property real hoverOffset: 0
      property bool hoverActive: false
      property int dragSourceIndex: -1
      property int dragTargetIndex: -1
      // A file from another application is dragged over the dock
      property bool dropHover: false
      // A file is over a trash or directory slot. Their own DropArea takes the drag from dockDrop,
      // which clears dropHover, so the dock needs this to stay revealed.
      readonly property bool slotDropHover: dockRoot.anySlotDropping()
      // What is being dragged over the dock: "app" (.desktop files), "file" or "" (not accepted)
      property string dropKind: ""
      // False while the urls of the drag could not be read yet (some sources offer them late)
      property bool dropKindKnown: false
      // Slot order the drop gap is opened before, -1 = no gap. Apps use their model index,
      // files use 1000 + position, the trash comes after every position.
      property int dropOrder: -1
      // The files were dropped and the new slot has not arrived yet: the gap stays open for it
      property bool dropHold: false
      // True for a moment when the new slot replaces the gap, so both change without animation
      property bool dropSnap: false
      // True for a moment when a dragged slot is released, see beginDragSettle()
      property bool dragSnap: false

      // Gap opening. delay: how long the cursor must rest before the gap opens, moveDelay: before it
      // moves to another position, duration: how long it takes to open, close or move. All in ms.
      readonly property int gapDelay: Config.options?.dock?.dropGap?.delay ?? 250
      readonly property int gapMoveDelay: Config.options?.dock?.dropGap?.moveDelay ?? 120
      readonly property int gapDuration: Config.options?.dock?.dropGap?.duration ?? 420
      // The gap is one slot wide
      readonly property real gapSize: Math.round(dockRoot.slotWidth)
      // Slot order the cursor points at (dropOrder is the one the gap is open at)
      property int dropTarget: -1

      // Total width of the gap, added to the capsule. It changes only when the gap opens or closes,
      // never when the gap moves, so the capsule keeps its size while the gap travels along the row.
      // Moving is done by the slots themselves: each one slides by gapShift() with its own animation.
      property real dropGap: dockRoot.dropOrder >= 0 ? dockRoot.gapSize : 0

      Behavior on dropGap {
        enabled: !dockRoot.dropSnap
        NumberAnimation {
          duration: dockRoot.gapDuration
          easing.type: Easing.OutCubic
        }
      }

      readonly property bool menuOpen: slotMenu.open || fileMenu.open || separatorMenu.open
      // Only the menu that is open names its target, so the other kind of slot is never dimmed
      readonly property string menuAppId: slotMenu.open ? slotMenu.appId : ""
      readonly property string menuFileKey: fileMenu.open ? fileMenu.slotKey : ""

      // Magnification is disabled only while dragging. With an open menu the last position is kept.
      readonly property bool zoomActive: dockRoot.hoverActive && dockRoot.zoomArmed && dockRoot.dragSourceIndex === -1 && !dockRoot.resizing && !dockRoot.dropHover

      // True once the entry delay has passed. Reset as soon as the cursor leaves.
      property bool zoomArmed: false

      onHoverActiveChanged: {
        if (dockRoot.hoverActive) {
          dockRoot.zoomArmed = dockRoot.zoomDelay <= 0;
          if (!dockRoot.zoomArmed)
            zoomDelayTimer.restart();
        } else {
          zoomDelayTimer.stop();
          dockRoot.zoomArmed = false;
        }
      }

      Timer {
        id: zoomDelayTimer
        interval: dockRoot.zoomDelay
        repeat: false
        onTriggered: dockRoot.zoomArmed = true
      }

      onZoomActiveChanged: {
        // A new hover starts at the pointer, not where the last one ended
        if (dockRoot.zoomActive && dockRoot.zoomLevel < 0.01)
          dockRoot.zoomCursor = dockRoot.hoverOffset;
      }

      // Exponential smoothing, independent of the frame rate. The cursor is smoothed lightly (it only
      // softens big jumps), the level is smoothed more (it is the zoom coming in and going out).
      FrameAnimation {
        id: zoomFrames
        running: dockRoot.zoomActive || dockRoot.zoomLevel > 0
        onTriggered: {
          const dt = Math.min(zoomFrames.frameTime, 0.05);
          if (dockRoot.zoomActive)
            dockRoot.zoomCursor += (dockRoot.hoverOffset - dockRoot.zoomCursor) * (1 - Math.exp(-dt / dockRoot.zoomCursorTau));
          const target = dockRoot.zoomActive ? 1 : 0;
          let level = dockRoot.zoomLevel + (target - dockRoot.zoomLevel) * (1 - Math.exp(-dt / dockRoot.zoomLevelTau));
          if (Math.abs(target - level) < 0.001)
            level = target;
          dockRoot.zoomLevel = level;
        }
      }

      // The zoom is kept while a menu or the preview is open. When they close, the pointer is usually
      // still over the dock, but the hover handler reports it a moment later. Switching the zoom off at
      // once would play the zoom-out and then the zoom-in, so the check waits for the hover to settle.
      function releaseHoverLater() {
        hoverReleaseTimer.restart();
      }

      Timer {
        id: hoverReleaseTimer
        interval: 200
        repeat: false
        onTriggered: {
          if (!dockRoot.menuOpen && !dockRoot.previewOpen && !rowHover.hovered)
            dockRoot.hoverActive = false;
        }
      }

      onMenuOpenChanged: {
        if (!dockRoot.menuOpen)
          dockRoot.releaseHoverLater();
      }

      // The pointer is over the dock. rowHover is checked as well as hitArea: a HoverHandler blocks
      // hover for the items behind it, so while the pointer is over the slots, hitArea.containsMouse
      // is false. Without rowHover the dock hid again as soon as the rising capsule reached the pointer.
      readonly property bool dockHovered: hitArea.containsMouse || rowHover.hovered

      // A drag from another application sends no pointer hover events, so dropHover keeps the dock open
      property bool reveal: root.pinned || (Config.options?.dock?.hoverToReveal?.enable && dockRoot.dockHovered) || dockRoot.menuOpen || dockRoot.dropHover || dockRoot.slotDropHover || dockRoot.resizing || dockRoot.previewOpen || (!ToplevelManager.activeToplevel?.activated)

      // Where the capsule slides to, and whether it has actually arrived in the revealed position.
      // Tooltips wait for that: a popup created while the capsule is still sliding up sits in a
      // half-hidden dock, near the pointer, and interferes with the reveal.
      readonly property real capsuleBottomTarget: dockRoot.reveal ? Appearance.sizes.hyprlandGapsOut : -(dockRoot.capsuleHeight + Appearance.sizes.elevationMargin)
      readonly property bool fullyRevealed: dockRoot.reveal && Math.abs(capsule.anchors.bottomMargin - dockRoot.capsuleBottomTarget) < 1

      // Slot centers in the resting layout (no magnification), measured from the row center and
      // keyed by slot key (app id or file slot key). Keyed by key, not by index, so a removed slot
      // cannot shift the others.
      function computeRestCenters() {
        const entries = [];
        for (const item of dockRoot.slotItems()) {
          entries.push({
            "id": item.slotKey ?? item.appId,
            "order": item.sortKey ?? item.index,
            "w": Math.round(dockRoot.slotWidth * item.widthFactor)
          });
        }
        // Order by the model index. Reading the index also re-evaluates this function when a slot
        // is moved: a move changes neither the slot count nor any width, and without this the
        // centers kept the old order until the next slot was added or removed.
        entries.sort((a, b) => a.order - b.order);
        // The drop gap is left out on purpose. These centers are also what the drop position is
        // measured against, and a gap that moves around must not move the thing it is measured by.
        const sep = Math.round(dockRoot.separatorWidth);
        let total = sep;
        for (const e of entries)
          total += e.w;
        const centers = {};
        let x = -total / 2;
        let sepPlaced = false;
        for (const e of entries) {
          // The separator sits between the apps (order < 1000) and the file section
          if (!sepPlaced && e.order >= 1000) {
            x += sep;
            sepPlaced = true;
          }
          centers[e.id] = x + e.w / 2;
          x += e.w;
        }
        return centers;
      }

      function updateHover() {
        // The pointer in window coordinates. The row itself moves under the pointer while the dock grows,
        // so its own coordinates would feed the movement back into the magnification.
        dockRoot.hoverOffset = rowHover.point.scenePosition.x - dockRoot.width / 2;
        dockRoot.hoverActive = true;
      }

      function slotIndexAt(x) {
        for (let i = 0; i < slotRepeater.count; i++) {
          const item = slotRepeater.itemAt(i);
          if (item && x >= item.x && x < item.x + item.width)
            return i;
        }
        return x < 0 ? 0 : Math.max(0, slotRepeater.count - 1);
      }

      // Cursor offset from the center of the capsule, for a point in the drop area. Like hoverOffset it
      // is a physical offset: it does not change when the capsule grows or shrinks around its center.
      function dropOffset(x, y) {
        return dockRow.mapFromItem(dockDrop, x, y).x - dockRow.width / 2 + dockRoot.capsuleOffset;
      }

      // Number of slots of a repeater whose center is left of the cursor offset. It is measured
      // against the resting layout (restCenters, no gap), so the gap opening or moving cannot
      // change the answer and make the gap jump back and forth.
      function slotsBefore(repeater, offset) {
        let count = 0;
        for (let i = 0; i < repeater.count; i++) {
          const item = repeater.itemAt(i);
          if (item && offset > (dockRoot.restCenters[item.slotKey ?? item.appId] ?? 0))
            count = i + 1;
        }
        return count;
      }

      // Index in the pinned list for a drop at x. Pinned apps live in the pinned block, so the
      // index stops at its end, in front of the first app that is only running.
      function dropPinIndex(offset) {
        return Math.min(DockApps.pinnedCount, dockRoot.slotsBefore(slotRepeater, offset));
      }

      // Index in the file section for a drop at x: 0 is next to the separator, the count is the end
      function fileDropIndex(offset) {
        return dockRoot.slotsBefore(fileRepeater, offset);
      }

      function anySlotDropping() {
        for (const item of dockRoot.slotItems()) {
          if (item.dropping)
            return true;
        }
        return false;
      }

      // Distance an element with this slot order slides to make room for the gap
      function gapShift(order) {
        return (dockRoot.dropOrder >= 0 && order >= dockRoot.dropOrder) ? dockRoot.gapSize : 0;
      }

      // Sets dropKind from the dragged urls. Until the urls are readable it guesses "file" and
      // is asked again on the next pointer move.
      function resolveDropKind(drag) {
        const list = drag.hasUrls ? Array.from(drag.urls) : [];
        dockRoot.dropKindKnown = list.length > 0;
        if (list.some(u => DockFiles.urlToPath(u).endsWith(".desktop")))
          dockRoot.dropKind = "app";
        else
          dockRoot.dropKind = DockFiles.enabled ? "file" : "";
      }

      // The gap opens after the cursor has rested at a position for a while, so passing over the
      // dock does not make everything move. Order is -1 for no gap.
      function setDropTarget(order) {
        if (order === dockRoot.dropTarget)
          return;
        dockRoot.dropTarget = order;
        if (order === dockRoot.dropOrder) {
          gapDelayTimer.stop();
          return;
        }
        gapDelayTimer.interval = dockRoot.dropOrder >= 0 ? dockRoot.gapMoveDelay : dockRoot.gapDelay;
        gapDelayTimer.restart();
      }

      // offset is the cursor offset from the capsule center (see dropOffset)
      function updateDropGap(offset) {
        let order = -1;
        if (dockRoot.dropKind === "app")
          order = dockRoot.dropPinIndex(offset);
        else if (dockRoot.dropKind === "file")
          order = 1000 + dockRoot.fileDropIndex(offset);
        dockRoot.setDropTarget(order);
      }

      // Closes the gap. With snap the new slot has just taken its place, so nothing is animated.
      function releaseDropGap(snap) {
        dropHoldTimer.stop();
        gapDelayTimer.stop();
        dockRoot.dropTarget = -1;
        dockRoot.dropHold = false;
        if (snap)
          dockRoot.dropSnap = true;
        dockRoot.dropOrder = -1;
        if (snap)
          Qt.callLater(() => dockRoot.dropSnap = false);
      }

      // Called when a slot is created
      function slotArrived() {
        if (dockRoot.dropHold)
          dockRoot.releaseDropGap(true);
      }

      // A dragged slot is released and the model is reordered in the same moment. The layout moves
      // the neighbours by itself, so their drag shift must drop to zero at once. Animating it would
      // push them a slot away from their place and slide them back, which looked like a twitch.
      function beginDragSettle() {
        dockRoot.dragSnap = true;
        Qt.callLater(() => dockRoot.dragSnap = false);
      }

      Timer {
        id: gapDelayTimer
        repeat: false
        onTriggered: {
          if (Quickshell.env("QS_DEBUG") === "1")
            console.log("dock drop gap:", dockRoot.dropKind, dockRoot.dropOrder, "->", dockRoot.dropTarget);
          dockRoot.dropOrder = dockRoot.dropTarget;
        }
      }

      Timer {
        id: dropHoldTimer
        interval: 1500
        repeat: false
        onTriggered: dockRoot.releaseDropGap(false)
      }

      // Top edge of a slot icon in window coordinates. Only plain property reads,
      // so every binding that calls this stays live.
      function iconTop(slot) {
        return capsule.y + dockRow.y + slot.y + slot.iconTop;
      }

      // Horizontal center of a slot in window coordinates
      function iconCenterX(slot) {
        return capsule.x + dockRow.x + slot.x + slot.width / 2;
      }

      // Slot under the cursor, or the trash or directory slot a file is dragged over, or null.
      // Reads each slot's own `hovered` and `dropping`, so it stays live.
      function findHoveredSlot() {
        for (const item of dockRoot.slotItems()) {
          if ((item.hovered || item.dropping) && !item.leaving)
            return item;
        }
        return null;
      }
      readonly property Item hoveredSlot: dockRoot.findHoveredSlot()

      // Top edge of a slot icon at rest (no magnification) in window coordinates. The preview is placed
      // against it, so it stays put while the icons grow and shrink.
      readonly property real iconRestTop: capsule.y + dockRoot.iconBottomMargin

      // ------------------------------------------------------------ focus

      // Window that has the focus. While the preview is shown the dock holds the keyboard (focus grab) and the
      // compositor reports no active window, so the last one is kept for the dots and the preview highlight.
      property var focusedToplevel: null

      function syncFocused() {
        const active = ToplevelManager.activeToplevel;
        if (active) {
          focusClearTimer.stop();
          dockRoot.focusedToplevel = active;
        } else if (!dockRoot.previewOpen) {
          // The focus usually comes back a moment later, so a short wait avoids a flicker of the dots
          focusClearTimer.restart();
        }
      }

      Timer {
        id: focusClearTimer
        interval: 200
        repeat: false
        onTriggered: {
          if (!ToplevelManager.activeToplevel && !dockRoot.previewOpen)
            dockRoot.focusedToplevel = null;
        }
      }

      Connections {
        target: ToplevelManager
        function onActiveToplevelChanged() {
          dockRoot.syncFocused();
        }
      }

      Component.onCompleted: dockRoot.syncFocused()

      // ------------------------------------------------------------ window preview

      // Slot the preview is shown for. Kept after the preview closed, so it fades out in place.
      property Item previewSlot: null
      // The preview is open. It becomes visible once the dock has arrived (see previewShown).
      property bool previewOpen: false
      // Slot the open delay is running for. Its windows are captured while it waits.
      property Item previewPending: null
      // Slot that was pressed or dismissed. It gets no preview until the cursor has left it.
      property Item previewBlockedSlot: null
      // A slot is pressed while the preview is open. The grab stays until the button is released: dropping
      // it in the middle of a click re-focuses the pointer and the release never reaches the slot.
      property bool previewPressHold: false

      onPreviewPressHoldChanged: {
        if (dockRoot.previewPressHold)
          previewHoldTimer.restart();
        else
          previewHoldTimer.stop();
      }

      // Safety net: never keep the grab forever if a release gets lost
      Timer {
        id: previewHoldTimer
        interval: 10000
        repeat: false
        onTriggered: dockRoot.previewPressHold = false
      }

      readonly property bool previewAllowed: dockRoot.previewEnabled && dockRoot.dragSourceIndex === -1 && !dockRoot.resizing && !dockRoot.dropHover && !dockRoot.menuOpen

      // App slot under the cursor that has at least one window. File slots have no app.
      readonly property Item previewCandidate: {
        const slot = dockRoot.hoveredSlot;
        if (!slot || slot.leaving)
          return null;
        return (slot.app?.toplevels?.length ?? 0) > 0 ? slot : null;
      }

      // Slot the panel is placed on. While the open delay runs, the pending slot is already used,
      // so its thumbnails are ready when the panel appears.
      readonly property Item previewTarget: dockRoot.previewOpen ? dockRoot.previewSlot : (dockRoot.previewPending ?? dockRoot.previewSlot)

      // Tooltips wait for the capsule to arrive, and so does the preview
      readonly property bool previewShown: dockRoot.previewOpen && dockRoot.previewAllowed && dockRoot.fullyRevealed && (dockRoot.previewSlot?.app?.toplevels?.length ?? 0) > 0
      readonly property bool previewWarm: !dockRoot.previewOpen && dockRoot.previewPending !== null && dockRoot.previewAllowed && dockRoot.fullyRevealed

      // The pointer is on the panel, or on the dock over an app that has windows. When it is neither,
      // the preview is on its way out. The zoom stays while the preview is open, so the candidate
      // stays too while the pointer is on its way to the panel.
      readonly property bool previewKeep: dockPreview.hovered || (rowHover.hovered && dockRoot.previewCandidate !== null)

      onPreviewCandidateChanged: dockRoot.updatePreview()
      onPreviewAllowedChanged: dockRoot.updatePreview()
      onPreviewKeepChanged: dockRoot.syncPreviewClose()

      onPreviewOpenChanged: {
        if (!dockRoot.previewOpen)
          dockRoot.releaseHoverLater();
        dockRoot.syncPreviewClose();
        dockRoot.syncFocused();
      }

      function updatePreview() {
        if (!dockRoot.previewAllowed) {
          dockRoot.closePreview();
          return;
        }
        const slot = dockRoot.previewCandidate;
        // A pressed slot gets no preview until the cursor has left it
        if (slot !== null && slot === dockRoot.previewBlockedSlot) {
          previewOpenTimer.stop();
          dockRoot.previewPending = null;
          return;
        }
        dockRoot.previewBlockedSlot = null;
        if (slot === null || (dockRoot.previewOpen && slot === dockRoot.previewSlot)) {
          // Nothing to open, or the preview already shows this app. Closing is up to previewKeep.
          previewOpenTimer.stop();
          dockRoot.previewPending = null;
          return;
        }
        dockRoot.previewPending = slot;
        // Moving from app to app while the preview is open is quicker than opening it
        previewOpenTimer.interval = dockRoot.previewOpen ? dockRoot.previewSwitchDelay : dockRoot.previewDelay;
        previewOpenTimer.restart();
      }

      function syncPreviewClose() {
        if (dockRoot.previewOpen && !dockRoot.previewKeep)
          previewCloseTimer.restart();
        else
          previewCloseTimer.stop();
      }

      function closePreview() {
        previewOpenTimer.stop();
        previewCloseTimer.stop();
        dockRoot.previewPending = null;
        dockRoot.previewOpen = false;
      }

      // Closes the preview and keeps it closed until the cursor has left the slot
      function dismissPreview() {
        dockRoot.previewBlockedSlot = dockRoot.hoveredSlot;
        dockRoot.closePreview();
      }

      Timer {
        id: previewOpenTimer
        repeat: false
        onTriggered: {
          const slot = dockRoot.previewPending;
          // Order matters: the target slot must never fall back to the old one in between
          if (slot !== null && slot === dockRoot.previewCandidate) {
            dockRoot.previewSlot = slot;
            dockRoot.previewOpen = true;
          }
          dockRoot.previewPending = null;
        }
      }

      Timer {
        id: previewCloseTimer
        interval: dockRoot.previewCloseDelay
        repeat: false
        onTriggered: {
          if (!dockRoot.previewKeep)
            dockRoot.previewOpen = false;
        }
      }

      // While the preview is shown it holds the keyboard and the pointer: a click outside of the dock
      // clears the grab and closes the preview
      HyprlandFocusGrab {
        id: previewGrab
        windows: [dockRoot]
        active: dockRoot.previewShown || dockRoot.previewPressHold
        onCleared: {
          if (dockRoot.previewOpen)
            dockRoot.dismissPreview();
        }
      }

      Item {
        id: previewKeys
        focus: dockRoot.previewShown

        Keys.onPressed: event => {
          const modifiers = [Qt.Key_Shift, Qt.Key_Control, Qt.Key_Alt, Qt.Key_AltGr, Qt.Key_Meta, Qt.Key_Super_L, Qt.Key_Super_R, Qt.Key_CapsLock, Qt.Key_NumLock];
          if (event.key === Qt.Key_Escape) {
            dockRoot.dismissPreview();
            event.accepted = true;
          } else if (!modifiers.includes(event.key)) {
            // The dock has the keyboard only because of the preview. Give it back at the first key,
            // so the typing that goes on in the focused window is not swallowed.
            dockRoot.dismissPreview();
          }
        }
      }

      function openSlotMenu(slot) {
        fileMenu.dismiss();
        separatorMenu.dismiss();
        slotMenu.openForApp(slot.app.appId, slot);
      }

      function openFileMenu(slot) {
        slotMenu.dismiss();
        separatorMenu.dismiss();
        fileMenu.openForFile(slot);
      }

      function openSeparatorMenu(item) {
        slotMenu.dismiss();
        fileMenu.dismiss();
        separatorMenu.openFor(item);
      }

      // Only the hover area receives input; it follows the capsule and grows while the dock is revealed
      mask: Region {
        item: hitArea
        // The preview panel sits above the capsule, outside of the hover area
        Region {
          item: previewHitBox
        }
      }

      MouseArea {
        id: hitArea
        anchors.horizontalCenter: capsule.horizontalCenter
        anchors.bottom: parent.bottom
        width: capsule.width + Appearance.sizes.elevationMargin * 2
        height: dockRoot.reveal ? dockRoot.capsuleHeight + Appearance.sizes.hyprlandGapsOut * 2 + Appearance.sizes.elevationMargin + (dockRoot.zoomActive ? dockRoot.zoomPx + dockRoot.tooltipHeadroom : 0) : (Config.options?.dock?.hoverToReveal?.height ?? 5)
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
      }

      // Files dropped anywhere on the dock: .desktop files are pinned as apps at the drop position,
      // everything else is added to the file section. It covers the same area as the hover area,
      // so a drag also reveals a hidden dock. The trash has its own DropArea on top of this one.
      DropArea {
        id: dockDrop
        anchors.fill: hitArea
        keys: ["text/uri-list"]
        onEntered: drag => {
          drag.accept(Qt.CopyAction);
          dockRoot.dropHover = true;
          // No magnification while a file is dragged over: it would widen the slots instead of
          // leaving one free slot at the drop position
          dockRoot.hoverActive = false;
          dockRoot.dropHold = false;
          dockRoot.resolveDropKind(drag);
          dockRoot.updateDropGap(dockRoot.dropOffset(drag.x, drag.y));
        }
        onPositionChanged: drag => {
          if (!dockRoot.dropKindKnown)
            dockRoot.resolveDropKind(drag);
          dockRoot.updateDropGap(dockRoot.dropOffset(drag.x, drag.y));
        }
        onExited: {
          dockRoot.dropHover = false;
          if (!dockRoot.dropHold)
            dockRoot.releaseDropGap(false);
        }
        onDropped: drop => {
          dockRoot.dropHover = false;
          if (!drop.hasUrls) {
            dockRoot.releaseDropGap(false);
            return;
          }
          // Copy, so the source file manager never removes the original itself
          drop.accept(Qt.CopyAction);
          const offset = dockRoot.dropOffset(drop.x, drop.y);
          const holding = dockRoot.dropOrder >= 0;
          gapDelayTimer.stop();
          const pinIndex = dockRoot.dropPinIndex(offset);
          const fileIndex = dockRoot.fileDropIndex(offset);
          const pinned = DockApps.pinDesktopUrls(drop.urls, pinIndex);
          const filesAdded = (DockFiles.enabled && pinned.rest.length > 0) ? DockFiles.addUrls(pinned.rest, fileIndex) : 0;
          if (holding && pinned.added + filesAdded > 0) {
            // Keep the gap where the new slot will appear, until it arrives and takes the gap's place
            dockRoot.dropOrder = pinned.added > 0 ? pinIndex : 1000 + fileIndex;
            dockRoot.dropHold = true;
            dropHoldTimer.restart();
          } else {
            dockRoot.releaseDropGap(false);
          }
        }
      }

      DockSlotMenu {
        id: slotMenu
        gap: dockRoot.popupGap
      }

      DockFileSlotMenu {
        id: fileMenu
        gap: dockRoot.popupGap
      }

      DockSeparatorMenu {
        id: separatorMenu
        gap: dockRoot.popupGap
      }

      Item {
        id: capsule
        width: dockRoot.capsuleWidth
        height: dockRoot.capsuleHeight
        // Whole pixels: a capsule edge on a fractional position shimmers while the dock grows
        x: Math.round((dockRoot.width - capsule.width) / 2 + dockRoot.capsuleOffset)
        anchors.bottom: parent.bottom
        // Slides below the screen edge when hidden
        anchors.bottomMargin: dockRoot.capsuleBottomTarget

        Behavior on anchors.bottomMargin {
          animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }

        StyledRectangularShadow {
          target: capsuleBackground
        }

        Rectangle {
          id: capsuleBackground
          anchors.fill: parent
          color: Appearance.colors.colLayer0
          border.width: 1
          border.color: Appearance.colors.colLayer0Border
          radius: dockRoot.iconSize / 2.2
        }

        RowLayout {
          id: dockRow
          anchors.fill: parent
          anchors.leftMargin: dockRoot.capsulePadding
          anchors.rightMargin: dockRoot.capsulePadding
          spacing: 0

          Repeater {
            id: slotRepeater
            model: DockApps.slotModel
            onItemAdded: {
              dockRoot.layoutRevision++;
              dockRoot.slotArrived();
            }
            onItemRemoved: dockRoot.layoutRevision++
            delegate: DockSlot {
              dock: dockRoot
            }
          }

          Item {
            id: fileSeparator
            Layout.preferredWidth: Math.round(dockRoot.separatorWidth)
            Layout.fillHeight: true
            visible: dockRoot.separatorWidth > 0
            opacity: dockRoot.separatorWidth / dockRoot.separatorFullWidth

            // Slides aside for the gap that opens among the apps
            property real gapOffset: dockRoot.gapShift(999.5)
            transform: Translate {
              x: fileSeparator.gapOffset
            }

            Behavior on gapOffset {
              enabled: !dockRoot.dropSnap
              NumberAnimation {
                duration: dockRoot.gapDuration
                easing.type: Easing.OutCubic
              }
            }

            // Same meaning as iconTop of a slot, so the separator menu can use the shared anchor math
            readonly property real iconTop: fileSeparator.height - dockRoot.iconBottomMargin - dockRoot.iconSize

            DockSeparator {
              anchors.centerIn: parent
              height: dockRoot.iconSize
              active: separatorArea.containsMouse || dockRoot.resizing
            }

            // Left drag (up = bigger) resizes the icons, right click opens the dock menu
            MouseArea {
              id: separatorArea
              anchors.fill: parent
              hoverEnabled: true
              preventStealing: true
              acceptedButtons: Qt.LeftButton | Qt.RightButton
              cursorShape: Qt.SizeVerCursor

              property real pressFromBottom: 0
              property real pressSize: 0

              function finishResize(commit) {
                if (dockRoot.resizing && commit)
                  Config.options.dock.iconSize = dockRoot.resizeSize;
                dockRoot.resizing = false;
                dockRoot.resizeSize = -1;
              }

              // The distance from the bottom edge does not depend on the item geometry,
              // which changes under the cursor while the size changes
              onPressed: mouse => {
                if (mouse.button !== Qt.LeftButton)
                  return;
                separatorArea.pressFromBottom = separatorArea.height - mouse.y;
                separatorArea.pressSize = dockRoot.iconSize;
              }

              onPositionChanged: mouse => {
                if (!(mouse.buttons & Qt.LeftButton))
                  return;
                const delta = (separatorArea.height - mouse.y) - separatorArea.pressFromBottom;
                if (!dockRoot.resizing && Math.abs(delta) < 4)
                  return;
                // The separator is centered in the capsule, 0.75 of the icon size above the bottom,
                // so dividing by 0.75 keeps it under the cursor
                const size = separatorArea.pressSize + delta / 0.75;
                dockRoot.resizeSize = Math.max(dockRoot.iconSizeMin, Math.min(dockRoot.iconSizeMax, Math.round(size)));
                dockRoot.resizing = true;
              }

              onReleased: mouse => {
                if (mouse.button === Qt.LeftButton)
                  separatorArea.finishResize(true);
              }

              onCanceled: separatorArea.finishResize(false)

              onClicked: mouse => {
                if (mouse.button === Qt.RightButton)
                  dockRoot.openSeparatorMenu(fileSeparator);
              }
            }
          }

          // Files and directories from Config.options.dock.files.items
          Repeater {
            id: fileRepeater
            model: DockFiles.enabled ? DockFiles.itemsModel : null
            onItemAdded: {
              dockRoot.layoutRevision++;
              dockRoot.slotArrived();
            }
            onItemRemoved: dockRoot.layoutRevision++
            delegate: DockFileSlot {
              id: fileSlot
              required property int index
              required property string path

              readonly property var meta: DockFiles.infoFor(fileSlot.path)
              readonly property bool preview: DockFiles.isPreviewable(fileSlot.meta.isDir, fileSlot.meta.suffix)

              dock: dockRoot
              order: fileSlot.index
              slotKey: "dock-file:" + fileSlot.path
              label: fileSlot.meta.name
              itemPath: fileSlot.path
              isPreview: fileSlot.preview
              isDir: fileSlot.meta.isDir
              iconSource: fileSlot.preview ? DockFiles.fileUrl(fileSlot.path) : DockFiles.iconForMeta(fileSlot.meta)
              // The plain type icon, when a preview or a custom directory icon cannot be loaded
              fallbackSource: (fileSlot.preview || fileSlot.meta.icon.length > 0) ? DockFiles.iconFor(fileSlot.meta.isDir, fileSlot.meta.suffix) : ""
            }
          }

          Repeater {
            id: trashRepeater
            model: DockFiles.trashEnabled ? 1 : 0
            onItemAdded: dockRoot.layoutRevision++
            onItemRemoved: dockRoot.layoutRevision++
            delegate: DockFileSlot {
              dock: dockRoot
              isTrash: true
              slotKey: "dock-trash"
              label: Translation.tr("Trash")
              iconSource: DockFiles.trashIcon
            }
          }

          // Takes all the space the slots do not use. Without it the RowLayout spreads that space over
          // the slots, which is what made the padding between slots grow while the gap was open.
          Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
          }

          HoverHandler {
            id: rowHover
            onPointChanged: {
              if (rowHover.hovered)
                dockRoot.updateHover();
            }
            onHoveredChanged: {
              if (rowHover.hovered)
                dockRoot.updateHover();
              else if (!dockRoot.menuOpen && !dockRoot.previewOpen)
                dockRoot.hoverActive = false;
            }
          }
        }
      }

      // Input area of the preview. A plain item of the window with its own geometry, so the input mask
      // follows the panel while it moves.
      Item {
        id: previewHitBox
        x: dockPreview.x
        y: dockPreview.y
        width: dockRoot.previewShown ? dockPreview.width : 0
        height: dockRoot.previewShown ? dockPreview.height : 0
      }

      DockPreview {
        id: dockPreview
        dock: dockRoot
        slot: dockRoot.previewTarget
        shown: dockRoot.previewShown
        warm: dockRoot.previewWarm
      }

      // Tooltip drawn inside the dock window. A popup window is a separate Wayland surface, and
      // creating one under the pointer while the dock auto-hides interferes with the reveal.
      // The window already has headroom above the capsule for this.
      Item {
        id: tooltip

        readonly property bool shown: dockRoot.hoveredSlot !== null && dockRoot.fullyRevealed && !dockRoot.menuOpen && !dockRoot.previewShown
        // Distance between the icon top and the tooltip, px
        readonly property real gap: dockRoot.popupGap
        // Last hovered slot, kept so the tooltip fades out in place
        property Item slot: null

        Connections {
          target: dockRoot
          function onHoveredSlotChanged() {
            if (dockRoot.hoveredSlot)
              tooltip.slot = dockRoot.hoveredSlot;
          }
        }

        width: content.implicitWidth
        height: content.implicitHeight
        x: tooltip.slot ? Math.max(0, Math.min(dockRoot.width - tooltip.width, dockRoot.iconCenterX(tooltip.slot) - tooltip.width / 2)) : 0
        y: tooltip.slot ? dockRoot.iconTop(tooltip.slot) - tooltip.gap - tooltip.height : 0
        z: 100
        opacity: tooltip.shown ? 1 : 0
        visible: tooltip.opacity > 0

        Behavior on opacity {
          NumberAnimation {
            duration: Appearance.animation.hover.duration
            easing.type: Easing.OutQuad
          }
        }

        StyledToolTipContent {
          id: content
          anchors.centerIn: parent
          // File slots expose tooltipText, app slots expose app.name
          text: tooltip.slot?.tooltipText ?? tooltip.slot?.app?.name ?? ""
          shown: true
          horizontalPadding: 10
          verticalPadding: 5
        }
      }
    }
  }
}
