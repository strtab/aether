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

      visible: (Config.options?.dock?.enable ?? true) && !GlobalStates.screenLocked && TaskbarApps.apps.length > 1

      readonly property real iconSize: Config.options?.dock?.iconSize ?? 65
      readonly property bool monochrome: Config.options?.dock?.monochromeIcons ?? true
      // Extra icon size at the cursor. Set Config.options.dock.magnification to false to disable.
      readonly property real zoomPx: (Config.options?.dock?.magnification ?? true) ? (Config.options?.dock?.magnificationZoom ?? 30) : 0
      // Magnetism reach in resting slot widths. Used by the slots and to size the window.
      readonly property real zoomRadius: Config.options?.dock?.magnificationRadius ?? 2.5

      // Slot width at rest. A magnified slot is wider in the same proportion as its icon.
      readonly property real slotWidth: dockRoot.iconSize + (dockRoot.iconSize / 4)
      readonly property real capsulePadding: 10
      readonly property real capsuleHeight: dockRoot.iconSize + (dockRoot.iconSize / 2)
      readonly property real iconBottomMargin: (dockRoot.capsuleHeight - dockRoot.iconSize) / 2
      readonly property int slotCount: slotRepeater.count

      // Live capsule width. The slots animate their own width, so it follows them frame by frame.
      readonly property real capsuleWidth: dockRow.implicitWidth + dockRoot.capsulePadding * 2

      // Width of the slots without any magnification (follows the enter/leave animations)
      function restRowWidth() {
        let w = 0;
        for (let i = 0; i < slotRepeater.count; i++) {
          const item = slotRepeater.itemAt(i);
          if (item)
            w += dockRoot.slotWidth * item.presence;
        }
        return w;
      }
      readonly property real restCapsuleWidth: dockRoot.restRowWidth() + dockRoot.capsulePadding * 2

      // Largest width the magnification can add. The sum of the zoom multipliers of all slots
      // stays below about 1 + zoomRadius, and one px of icon growth adds slotWidth / iconSize px of width.
      readonly property real maxZoomExtra: dockRoot.zoomPx * (dockRoot.slotWidth / dockRoot.iconSize) * Math.min(dockRoot.slotCount, 1 + dockRoot.zoomRadius)

      // Where the cursor is along the resting capsule: 0 = left end, 1 = right end.
      // The capsule grows away from the cursor: the side the cursor is on stays in place.
      property real pivot: 0.5
      // Capsule left edge in window coordinates. Without magnification the capsule is centered.
      readonly property real capsuleX: (dockRoot.width - dockRoot.restCapsuleWidth) / 2 - dockRoot.pivot * (dockRoot.capsuleWidth - dockRoot.restCapsuleWidth)

      readonly property real tooltipHeadroom: 34

      // Anchored to the bottom edge only, so the compositor centers the surface horizontally.
      // The window is wide enough for the largest magnified capsule, so it never resizes while
      // zooming; the capsule moves inside it and the input mask limits input to the capsule.
      anchors.bottom: true
      implicitWidth: dockRoot.slotCount * dockRoot.slotWidth + dockRoot.capsulePadding * 2 + dockRoot.maxZoomExtra * 2 + Appearance.sizes.elevationMargin * 2
      implicitHeight: dockRoot.capsuleHeight + dockRoot.zoomPx + dockRoot.tooltipHeadroom + Appearance.sizes.elevationMargin + Appearance.sizes.hyprlandGapsOut
      exclusiveZone: root.pinned ? dockRoot.capsuleHeight + Appearance.sizes.hyprlandGapsOut * 2 : 0

      WlrLayershell.namespace: "quickshell:dock"
      WlrLayershell.layer: WlrLayer.Top
      color: "transparent"

      // Cursor offset from the window center, in px. The window is centered on screen and the
      // resting capsule is centered in it, so this is also the offset from the resting capsule center.
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

      property bool reveal: root.pinned || (Config.options?.dock?.hoverToReveal && hitArea.containsMouse) || dockRoot.menuOpen || (!ToplevelManager.activeToplevel?.activated)

      Connections {
        target: DockApps
        function onSlotIdsChanged() {
          dockRoot.hoverActive = false;
        }
      }

      function updateHover() {
        // Physical cursor position in window coordinates, independent of where the capsule is now
        const x = dockRow.mapToItem(null, rowHover.point.position.x, 0).x;
        dockRoot.hoverOffset = x - dockRoot.width / 2;
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

      function openSlotMenu(slot) {
        slotMenu.openFor(slot.app.appId, slot);
      }

      // Only the hover area receives input; it follows the capsule and grows while the dock is revealed
      mask: Region {
        item: hitArea
      }

      MouseArea {
        id: hitArea
        x: capsule.x - Appearance.sizes.elevationMargin
        width: capsule.width + Appearance.sizes.elevationMargin * 2
        anchors.bottom: parent.bottom
        height: dockRoot.reveal ? dockRoot.capsuleHeight + Appearance.sizes.hyprlandGapsOut * 2 + Appearance.sizes.elevationMargin + (dockRoot.zoomActive ? dockRoot.zoomPx + dockRoot.tooltipHeadroom : 0) : (Config.options?.dock?.hoverRegionHeight ?? 2)
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
      }

      DockSlotMenu {
        id: slotMenu
        dockWindow: dockRoot
      }

      Item {
        id: capsule
        x: dockRoot.capsuleX
        width: dockRoot.capsuleWidth
        height: dockRoot.capsuleHeight
        anchors.bottom: parent.bottom
        // Slides below the screen edge when hidden
        anchors.bottomMargin: dockRoot.reveal ? Appearance.sizes.hyprlandGapsOut : -(dockRoot.capsuleHeight + Appearance.sizes.elevationMargin)

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
    }
  }
}
