import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

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

      visible: (Config.options?.dock?.enable ?? true) && !GlobalStates.screenLocked && TaskbarApps.slotIds.length > 1

      readonly property real iconSize: Config.options?.dock?.iconSize ?? 65
      readonly property bool monochrome: Config.options?.dock?.monochromeIcons ?? true
      // Extra icon size at the cursor. Set Config.options.dock.magnification to false to disable.
      readonly property real zoomPx: (Config.options?.dock?.magnification.enable ?? true) ? (Config.options?.dock?.magnification.strength ?? 30) : 0
      // Magnetism reach in resting slot widths
      readonly property real zoomRadius: Config.options?.dock?.magnification.radius ?? 2.5
      readonly property real zoomPlateau: Config.options?.dock?.magnification.plateau ?? 0.5

      // Slot width at rest. A magnified slot is wider in the same proportion as its icon.
      readonly property real slotWidth: dockRoot.iconSize + (dockRoot.iconSize / 4)
      readonly property real capsulePadding: 10
      readonly property real capsuleHeight: dockRoot.iconSize + (dockRoot.iconSize / 2)
      readonly property real iconBottomMargin: (dockRoot.capsuleHeight - dockRoot.iconSize) / 2
      readonly property int slotCount: slotRepeater.count

      // Bumped whenever a slot is created or destroyed. The functions below read it, so
      // bindings that use them are re-evaluated for slots that did not exist before.
      property int layoutRevision: 0

      // Capsule and resting widths are both summed straight from the slots. Reading the layout's
      // implicitWidth instead would lag behind the slot properties and leave a transient
      // difference between the two, which shows up as the capsule shaking while it resizes.
      function liveRowWidth() {
        dockRoot.layoutRevision;
        let w = 0;
        for (let i = 0; i < slotRepeater.count; i++) {
          const item = slotRepeater.itemAt(i);
          if (item)
            w += dockRoot.slotWidth * (item.iconPx / dockRoot.iconSize) * item.widthFactor;
        }
        return w;
      }

      // Width of the slots without any magnification (follows the leave animation)
      function restRowWidth() {
        dockRoot.layoutRevision;
        let w = 0;
        for (let i = 0; i < slotRepeater.count; i++) {
          const item = slotRepeater.itemAt(i);
          if (item)
            w += dockRoot.slotWidth * item.widthFactor;
        }
        return w;
      }

      // Shift of the capsule center from the window center
      readonly property real capsuleOffset: (0.5 - dockRoot.pivot) * (dockRoot.capsuleWidth - dockRoot.restCapsuleWidth)
      readonly property real capsuleWidth: dockRoot.liveRowWidth() + dockRoot.capsulePadding * 2
      readonly property real restCapsuleWidth: dockRoot.restRowWidth() + dockRoot.capsulePadding * 2
      readonly property var restCenters: dockRoot.computeRestCenters()

      // Where the cursor is along the resting capsule: 0 = left end, 1 = right end.
      // The capsule grows away from the cursor: the side the cursor is on stays in place.
      property real pivot: 0.5
      readonly property real tooltipHeadroom: 34

      // The window spans the whole screen width and never resizes, so slots coming and going
      // cannot move the capsule. The capsule is centered by an anchor, and the input mask
      // limits input to the capsule.
      anchors.left: true
      anchors.right: true
      anchors.bottom: true
      implicitHeight: dockRoot.capsuleHeight + dockRoot.zoomPx + dockRoot.tooltipHeadroom + Appearance.sizes.elevationMargin + Appearance.sizes.hyprlandGapsOut
      exclusiveZone: root.pinned ? dockRoot.capsuleHeight + Appearance.sizes.hyprlandGapsOut * 2 : 0

      WlrLayershell.namespace: "quickshell:dock"
      WlrLayershell.layer: Appearance.layers.dock
      color: "transparent"

      // Cursor offset from the center of the resting capsule, in px. It is a physical offset, so
      // it stays valid while the capsule moves, grows or shrinks and when slots come and go.
      property real hoverOffset: 0
      property bool hoverActive: false
      property int dragSourceIndex: -1
      property int dragTargetIndex: -1

      readonly property bool menuOpen: slotMenu.open
      readonly property string menuAppId: slotMenu.appId

      // Magnification is disabled only while dragging. With an open menu the last position is kept.
      readonly property bool zoomActive: dockRoot.hoverActive && dockRoot.dragSourceIndex === -1

      onMenuOpenChanged: {
        if (!dockRoot.menuOpen && !rowHover.hovered)
          dockRoot.hoverActive = false;
      }

      // The pointer is over the dock. rowHover is checked as well as hitArea: a HoverHandler blocks
      // hover for the items behind it, so while the pointer is over the slots, hitArea.containsMouse
      // is false. Without rowHover the dock hid again as soon as the rising capsule reached the pointer.
      readonly property bool dockHovered: hitArea.containsMouse || rowHover.hovered

      property bool reveal: root.pinned || (Config.options?.dock?.hoverToReveal?.enable && dockRoot.dockHovered) || dockRoot.menuOpen || (!ToplevelManager.activeToplevel?.activated)

      // Where the capsule slides to, and whether it has actually arrived in the revealed position.
      // Tooltips wait for that: a popup created while the capsule is still sliding up sits in a
      // half-hidden dock, near the pointer, and interferes with the reveal.
      readonly property real capsuleBottomTarget: dockRoot.reveal ? Appearance.sizes.hyprlandGapsOut : -(dockRoot.capsuleHeight + Appearance.sizes.elevationMargin)
      readonly property bool fullyRevealed: dockRoot.reveal && Math.abs(capsule.anchors.bottomMargin - dockRoot.capsuleBottomTarget) < 1

      // Slot centers in the resting layout (no magnification), measured from the row center and
      // keyed by app id. Keyed by id, not by index, so a removed slot cannot shift the others.
      function computeRestCenters() {
        dockRoot.layoutRevision;
        const entries = [];
        for (let i = 0; i < slotRepeater.count; i++) {
          const item = slotRepeater.itemAt(i);
          if (!item)
            continue;
          entries.push({
            "id": item.appId,
            "index": item.index,
            "w": dockRoot.slotWidth * item.widthFactor
          });
        }
        // Order by the model index. Reading the index also re-evaluates this function when a slot
        // is moved: a move changes neither the slot count nor any width, and without this the
        // centers kept the old order until the next slot was added or removed.
        entries.sort((a, b) => a.index - b.index);
        let total = 0;
        for (const e of entries)
          total += e.w;
        const centers = {};
        let x = -total / 2;
        for (const e of entries) {
          centers[e.id] = x + e.w / 2;
          x += e.w;
        }
        return centers;
      }

      function updateHover() {
        // Offset from the live capsule center, corrected by the capsule shift
        const local = rowHover.point.position.x - dockRow.width / 2;
        dockRoot.hoverOffset = local + dockRoot.capsuleOffset;
        const rest = dockRoot.restCapsuleWidth;
        dockRoot.pivot = rest > 0 ? Math.max(0, Math.min(1, 0.5 + dockRoot.hoverOffset / rest)) : 0.5;
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

      // Top edge of a slot icon in window coordinates. Only plain property reads,
      // so every binding that calls this stays live.
      function iconTop(slot) {
        return capsule.y + dockRow.y + slot.y + slot.iconTop;
      }

      // Horizontal center of a slot in window coordinates
      function iconCenterX(slot) {
        return capsule.x + dockRow.x + slot.x + slot.width / 2;
      }

      // Slot under the cursor, or null. Reads each slot's own `hovered`, so it stays live.
      function findHoveredSlot() {
        dockRoot.layoutRevision;
        for (let i = 0; i < slotRepeater.count; i++) {
          const item = slotRepeater.itemAt(i);
          if (item && item.hovered && !item.leaving)
            return item;
        }
        return null;
      }
      readonly property Item hoveredSlot: dockRoot.findHoveredSlot()

      function openSlotMenu(slot) {
        slotMenu.openFor(slot.app.appId, slot);
      }

      // Only the hover area receives input; it follows the capsule and grows while the dock is revealed
      mask: Region {
        item: hitArea
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

      DockSlotMenu {
        id: slotMenu
        dockWindow: dockRoot
      }

      Item {
        id: capsule
        width: dockRoot.capsuleWidth
        height: dockRoot.capsuleHeight
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.horizontalCenterOffset: dockRoot.capsuleOffset
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
          radius: (Config.options?.dock?.iconSize / 2.2)
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
            onItemAdded: dockRoot.layoutRevision++
            onItemRemoved: dockRoot.layoutRevision++
            delegate: DockSlot {
              dock: dockRoot
            }
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
              else if (!dockRoot.menuOpen)
                dockRoot.hoverActive = false;
            }
          }
        }
      }

      // Tooltip drawn inside the dock window. A popup window is a separate Wayland surface, and
      // creating one under the pointer while the dock auto-hides interferes with the reveal.
      // The window already has headroom above the capsule for this.
      Item {
        id: tooltip

        readonly property bool shown: dockRoot.hoveredSlot !== null && dockRoot.fullyRevealed && !dockRoot.menuOpen
        // Distance between the icon top and the tooltip, px
        readonly property real gap: 10
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
          text: tooltip.slot?.app?.name ?? ""
          shown: true
          horizontalPadding: 10
          verticalPadding: 5
        }
      }
    }
  }
}
