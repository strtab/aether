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

      readonly property real slotWidth: dockRoot.iconSize + (dockRoot.iconSize / 4)
      readonly property real capsulePadding: 10
      readonly property real capsuleHeight: dockRoot.iconSize + (dockRoot.iconSize / 2)
      readonly property real iconBottomMargin: (dockRoot.capsuleHeight - dockRoot.iconSize) / 2
      readonly property int iconSlots: DockApps.slotIds.length
      property real capsuleWidth: dockRoot.iconSlots * dockRoot.slotWidth + dockRoot.capsulePadding * 2

      readonly property real tooltipHeadroom: 34

      Behavior on capsuleWidth {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
      }

      // Anchored to the bottom edge only, so the compositor centers the surface horizontally
      anchors.bottom: true
      implicitWidth: dockRoot.capsuleWidth + Appearance.sizes.elevationMargin * 2
      implicitHeight: dockRoot.capsuleHeight + dockRoot.zoomPx + dockRoot.tooltipHeadroom + Appearance.sizes.elevationMargin + Appearance.sizes.hyprlandGapsOut
      exclusiveZone: root.pinned ? dockRoot.capsuleHeight + Appearance.sizes.hyprlandGapsOut * 2 : 0

      WlrLayershell.namespace: "quickshell:dock"
      WlrLayershell.layer: WlrLayer.Top
      color: "transparent"

      // Cursor x inside dockRow, -1 when the cursor is outside
      property real hoverX: -1
      property int dragSourceIndex: -1
      property int dragTargetIndex: -1
      readonly property bool menuOpen: slotMenu.open
      // Cursor position used for magnification; disabled while dragging or with an open menu
      readonly property real zoomHoverX: dockRoot.dragSourceIndex === -1 && !dockRoot.menuOpen ? dockRoot.hoverX : -1

      property bool reveal: root.pinned || (Config.options?.dock?.hoverToReveal && hitArea.containsMouse) || dockRoot.menuOpen || (!ToplevelManager.activeToplevel?.activated)

      Connections {
        target: DockApps
        function onSlotIdsChanged() {
          dockRoot.hoverX = -1;
        }
      }

      function slotIndexAt(x) {
        for (let i = 0; i < slotRepeater.count; i++) {
          const item = slotRepeater.itemAt(i);
          if (item && x >= item.x && x < item.x + item.width)
            return i;
        }
        return x < 0 ? 0 : Math.max(0, slotRepeater.count - 1);
      }

      function openSlotMenu(slot) {
        // Window coordinates of the slot center
        const center = slot.mapToItem(null, slot.width / 2, 0);
        slotMenu.openFor(slot.app.appId, center.x, capsule.y - 10);
      }

      // Only the hover area receives input; it grows while the dock is revealed
      mask: Region {
        item: hitArea
      }

      MouseArea {
        id: hitArea
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        width: parent.width
        height: dockRoot.reveal ? dockRoot.capsuleHeight + Appearance.sizes.hyprlandGapsOut * 2 + Appearance.sizes.elevationMargin + (dockRoot.zoomHoverX >= 0 ? dockRoot.zoomPx + dockRoot.tooltipHeadroom : 0) : (Config.options?.dock?.hoverRegionHeight ?? 2)
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
            model: DockApps.slotIds
            delegate: DockSlot {
              dock: dockRoot
            }
          }

          HoverHandler {
            id: rowHover
            onPointChanged: dockRoot.hoverX = rowHover.point.position.x
            onHoveredChanged: {
              if (!rowHover.hovered)
                dockRoot.hoverX = -1;
            }
          }
        }
      }
    }
  }
}
