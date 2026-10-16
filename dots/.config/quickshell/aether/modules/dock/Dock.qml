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

      visible: (Config.options?.dock?.enable ?? true) && !GlobalStates.screenLocked

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

      // Capsule and resting widths are both summed straight from the slots. Reading the layout's
      // implicitWidth instead would lag behind the slot properties and leave a transient
      // difference between the two, which shows up as the capsule shaking while it resizes.
      function liveRowWidth() {
        let w = dockRoot.separatorWidth;
        for (const item of dockRoot.slotItems())
          w += dockRoot.slotWidth * (item.iconPx / dockRoot.iconSize) * item.widthFactor;
        return w;
      }

      // Width of the slots without any magnification (follows the leave animation)
      function restRowWidth() {
        let w = dockRoot.separatorWidth;
        for (const item of dockRoot.slotItems())
          w += dockRoot.slotWidth * item.widthFactor;
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
      // A file from another application is dragged over the dock
      property bool dropHover: false

      readonly property bool menuOpen: slotMenu.open || fileMenu.open
      // Only the menu that is open names its target, so the other kind of slot is never dimmed
      readonly property string menuAppId: slotMenu.open ? slotMenu.appId : ""
      readonly property string menuFileKey: fileMenu.open ? fileMenu.slotKey : ""

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

      // A drag from another application sends no pointer hover events, so dropHover keeps the dock open
      property bool reveal: root.pinned || (Config.options?.dock?.hoverToReveal?.enable && dockRoot.dockHovered) || dockRoot.menuOpen || dockRoot.dropHover || (!ToplevelManager.activeToplevel?.activated)

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
            "w": dockRoot.slotWidth * item.widthFactor
          });
        }
        // Order by the model index. Reading the index also re-evaluates this function when a slot
        // is moved: a move changes neither the slot count nor any width, and without this the
        // centers kept the old order until the next slot was added or removed.
        entries.sort((a, b) => a.order - b.order);
        const sep = dockRoot.separatorWidth;
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
        for (const item of dockRoot.slotItems()) {
          if (item.hovered && !item.leaving)
            return item;
        }
        return null;
      }
      readonly property Item hoveredSlot: dockRoot.findHoveredSlot()

      function openSlotMenu(slot) {
        fileMenu.dismiss();
        slotMenu.openFor(slot.app.appId, slot);
      }

      function openFileMenu(slot) {
        slotMenu.dismiss();
        fileMenu.openFor(slot);
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

      // Files dropped anywhere on the dock are added to the file section. It covers the same
      // area as the hover area, so a drag also reveals a hidden dock. The trash has its own
      // DropArea on top of this one.
      DropArea {
        anchors.fill: hitArea
        enabled: DockFiles.enabled
        keys: ["text/uri-list"]
        onEntered: drag => {
          drag.accept(Qt.CopyAction);
          dockRoot.dropHover = true;
        }
        onExited: dockRoot.dropHover = false
        onDropped: drop => {
          dockRoot.dropHover = false;
          if (!drop.hasUrls)
            return;
          // Copy, so the source file manager never removes the original itself
          drop.accept(Qt.CopyAction);
          DockFiles.addUrls(drop.urls);
        }
      }

      DockSlotMenu {
        id: slotMenu
        dockWindow: dockRoot
      }

      DockFileSlotMenu {
        id: fileMenu
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
          border.width: dockRoot.dropHover ? 2 : 1
          border.color: dockRoot.dropHover ? Appearance.colors.colPrimary : Appearance.colors.colLayer0Border
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

          Item {
            id: fileSeparator
            Layout.preferredWidth: dockRoot.separatorWidth
            Layout.fillHeight: true
            visible: dockRoot.separatorWidth > 0
            opacity: dockRoot.separatorWidth / dockRoot.separatorFullWidth

            DockSeparator {
              anchors.centerIn: parent
              height: dockRoot.iconSize 
            }
          }

          // Files and directories from Config.options.dock.files.items
          Repeater {
            id: fileRepeater
            model: DockFiles.enabled ? DockFiles.itemsModel : null
            onItemAdded: dockRoot.layoutRevision++
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
              iconSource: fileSlot.preview ? DockFiles.fileUrl(fileSlot.path) : DockFiles.iconFor(fileSlot.meta.isDir, fileSlot.meta.suffix)
              fallbackSource: fileSlot.preview ? DockFiles.iconFor(fileSlot.meta.isDir, fileSlot.meta.suffix) : ""
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
