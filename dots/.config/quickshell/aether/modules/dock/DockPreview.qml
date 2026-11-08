pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

// Window preview of an app slot: a live thumbnail per window of the app.
// A single header with the icon and the name of the app sits at the top of the panel.
// It is drawn inside the dock window. A popup window would be a separate Wayland surface, and
// creating one under the pointer while the dock auto-hides interferes with the reveal.
//
// - The windows are laid out in a grid: at most maxColumns per line and maxRows lines.
// - The layout is plain arithmetic, no positioner and no implicit sizes: the size of the panel is known
//   in the same moment as the number of windows, so there is no frame with a half-built panel.
// - The panel is placed against the resting layout of the dock (Dock.restCenters), so it does not move
//   with the magnification.
// - Cards are matched to windows by identity (ScriptModel). A rebuild of the dock data keeps them alive,
//   switching to another app replaces them.
// - All input goes through one MouseArea. Nested hover items would steal hover from each other.
//   Left click focuses the window, middle click or the close button closes it.
// The state machine (when to open and close) lives in Dock.qml; this item only draws.
Item {
  id: root

  // Dock PanelWindow: metrics, config values and the layout helpers
  required property var dock
  // App slot the panel is placed on (DockSlot). It may be null.
  property Item slot: null
  property bool shown: false
  // Not shown yet, but the windows are already captured, so the thumbnails are ready when the panel appears
  property bool warm: false

  // The pointer is over the panel
  readonly property bool hovered: panelArea.containsMouse

  readonly property var app: root.slot?.app ?? null
  readonly property var toplevels: Array.from(root.app?.toplevels ?? []).slice(0, root.dock.previewMaxColumns * root.dock.previewMaxRows)
  readonly property int count: root.toplevels.length
  readonly property int columns: Math.max(1, Math.min(root.count, root.dock.previewMaxColumns))
  readonly property int rows: root.count > 0 ? Math.ceil(root.count / root.columns) : 1

  readonly property real padding: 14
  readonly property real spacing: 14
  readonly property real rowSpacing: 12
  readonly property real screenMargin: 8

  readonly property real thumbHeight: root.dock.previewThumbHeight
  // Header with the app icon and name, shared by all windows
  readonly property real headerHeight: 20
  readonly property real headerGap: 10
  readonly property real headerIconSize: 21
  // Top edge of the card grid
  readonly property real gridTop: root.padding + root.headerHeight + root.headerGap
  readonly property real cardHeight: root.thumbHeight
  // Cards have a fixed size and the thumbnail is fitted into them, so a window that is still
  // loading or changes its shape never moves the layout. Many columns make the cards narrower.
  readonly property real cardWidth: {
    const natural = Math.round(root.thumbHeight * 16 / 9);
    const available = Math.floor((root.dock.width - root.screenMargin * 2 - root.padding * 2 - root.spacing * (root.columns - 1)) / root.columns);
    return Math.max(80, Math.min(natural, available));
  }
  readonly property real panelWidth: root.columns * root.cardWidth + (root.columns - 1) * root.spacing + root.padding * 2
  readonly property real panelHeight: root.gridTop + root.rows * root.cardHeight + (root.rows - 1) * root.rowSpacing + root.padding

  // The panel is above the icon at rest. The gap also clears an icon magnified to the full strength.
  readonly property real gap: root.dock.popupGap + root.dock.zoomPx

  // Center of the slot at rest in window coordinates. The panel slides to it when it moves to another app.
  readonly property real targetCenter: root.slot ? root.dock.width / 2 + (root.dock.restCenters[root.slot.appId] ?? 0) : 0
  property real center: root.targetCenter

  width: root.panelWidth
  height: root.panelHeight
  x: Math.round(Math.max(root.screenMargin, Math.min(root.dock.width - root.width - root.screenMargin, root.center - root.width / 2)))
  y: Math.max(0, Math.round(root.dock.iconRestTop - root.gap - root.height))
  z: 100

  opacity: root.shown ? 1 : 0
  // Warm means visible but transparent: captures run only for visible views
  visible: root.shown || root.warm || root.opacity > 0
  scale: 0.96 + 0.04 * root.opacity
  transformOrigin: Item.Bottom

  Behavior on opacity {
    NumberAnimation {
      duration: Appearance.animation.hover.duration
      easing.type: Easing.OutQuad
    }
  }

  // Vertical offset of the slide: the panel rises from below by this many pixels when it appears
  readonly property real slideDistance: 10
  property real slideOffset: root.shown ? 0 : root.slideDistance

  Behavior on slideOffset {
    NumberAnimation {
      duration: 180
      easing.type: Easing.OutCubic
    }
  }

  StyledRectangularShadow {
    target: panel
  }

  Rectangle {
    id: panel
    width: root.panelWidth
    height: root.panelHeight
    color: Appearance.colors.colLayer1
    border.width: 1
    border.color: Appearance.colors.colLayer0Border
    radius: Appearance.rounding.normal

    // Header: one icon and the name of the app for all windows
    Item {
      id: header
      x: root.padding
      y: root.padding
      width: root.panelWidth - root.padding * 2
      height: root.headerHeight

      DockIcon {
        id: headerIcon
        x: 0
        y: (header.height - height) / 2
        width: root.headerIconSize
        height: root.headerIconSize
        iconSource: root.app?.icon ?? ""
        resetToken: DockApps.iconEpoch
        sourceSize: Qt.size(42, 42)
      }
      StyledRectangularShadow {
        target: headerIcon
      }

      StyledText {
        x: root.headerIconSize + 8
        width: header.width - root.headerIconSize - 8
        height: header.height
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
        text: root.slot?.app?.name ?? ""
        color: Appearance.colors.colOnLayer0
        style: Appearance.font.style.caption1
      }
    }

    Repeater {
      id: cards

      // No windows while the panel is hidden: the captures stop and nothing is kept alive
      model: ScriptModel {
        values: root.visible ? root.toplevels : []
      }

      delegate: Item {
        id: card

        required property var modelData
        required property int index

        readonly property var toplevel: card.modelData
        readonly property bool hovered: panelArea.hoverIndex === card.index
        readonly property bool closeHot: card.hovered && panelArea.overClose
        readonly property bool active: card.toplevel === root.dock.focusedToplevel
        // The window is being closed from here. Its capture must end before the compositor drops the
        // window, otherwise the capture request points at an object that is already gone
        // (a fatal "invalid object" error of the Wayland connection).
        property bool closing: false

        x: root.padding + (card.index % root.columns) * (root.cardWidth + root.spacing)
        y: root.gridTop + Math.floor(card.index / root.columns) * (root.cardHeight + root.rowSpacing)
        width: root.cardWidth
        height: root.cardHeight
        opacity: card.closing ? 0 : 1

        Behavior on opacity {
          NumberAnimation {
            duration: 120
            easing.type: Easing.OutQuad
          }
        }

        function requestClose() {
          if (card.closing)
            return;
          card.closing = true;
          closeTimer.restart();
        }

        // The point is in card coordinates
        function hitClose(p) {
          return closeButton.opacity > 0 && p.x >= closeButton.x && p.x < closeButton.x + closeButton.width && p.y >= closeButton.y && p.y < closeButton.y + closeButton.height;
        }

        Timer {
          id: closeTimer
          interval: 150
          repeat: false
          onTriggered: card.toplevel?.close()
        }

        // Thumbnail with rounded corners
        Item {
          id: thumb
          width: card.width
          height: root.thumbHeight

          layer.enabled: true
          layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: thumbMask
            maskThresholdMin: 0.5
            maskSpreadAtMin: 1.0
          }

          Rectangle {
            anchors.fill: parent
            color: Appearance.m3colors.m3surfaceContainerLowest
          }

          // The thumbnail is fitted into the card with the shape the frame itself reports
          ScreencopyView {
            id: view

            readonly property bool sized: view.hasContent && view.sourceSize.width > 0 && view.sourceSize.height > 0
            readonly property real fit: view.sized ? Math.min(thumb.width / view.sourceSize.width, thumb.height / view.sourceSize.height) : 1

            anchors.centerIn: parent
            width: view.sized ? Math.round(view.sourceSize.width * view.fit) : thumb.width
            height: view.sized ? Math.round(view.sourceSize.height * view.fit) : thumb.height
            captureSource: card.closing ? null : card.toplevel
            live: true
            opacity: view.hasContent ? 1 : 0

            Behavior on opacity {
              NumberAnimation {
                duration: 160
                easing.type: Easing.OutQuad
              }
            }
          }
        }

        Item {
          id: thumbMask
          width: thumb.width
          height: thumb.height
          visible: false
          layer.enabled: true

          Rectangle {
            anchors.fill: parent
            radius: Appearance.rounding.small
            color: "black"
          }
        }

        // Ring around the thumbnail: the hovered window, or the focused one
        Rectangle {
          width: thumb.width
          height: thumb.height
          radius: Appearance.rounding.small
          color: "transparent"

          Behavior on border.width {
            NumberAnimation {
              duration: Appearance.animation.hover.duration
              easing.type: Easing.OutQuad
            }
          }
        }

        // Gray close button in the top left corner of the thumbnail, only while the card is hovered
        Rectangle {
          id: closeButton
          x: -6
          y: -6
          width: 20
          height: 20
          radius: width / 2
          opacity: card.hovered ? 1 : 0
          visible: opacity > 0
          color: card.hovered ? Appearance.m3colors.m3surfaceContainerHigh : "transparent"

          Behavior on opacity {
            NumberAnimation {
              duration: Appearance.animation.hover.duration
              easing.type: Easing.OutQuad
            }
          }

          MaterialSymbol {
            anchors.centerIn: parent
            text: "close"
            iconSize: 11
            font.weight: Font.DemiBold
            color: Appearance.m3colors.m3onSurfaceVariant
          }
        }
      }
    }

    // Cards come and go: forget the hover of a card that is gone
    Connections {
      target: cards
      function onCountChanged() {
        panelArea.hoverIndex = -1;
        panelArea.overClose = false;
      }
    }

    MouseArea {
      id: panelArea
      anchors.fill: parent
      hoverEnabled: true
      acceptedButtons: Qt.LeftButton | Qt.MiddleButton

      property int hoverIndex: -1
      property bool overClose: false

      function refresh(x, y) {
        let index = -1;
        let close = false;
        for (let i = 0; i < cards.count; i++) {
          const item = cards.itemAt(i);
          if (!item)
            continue;
          const p = item.mapFromItem(panelArea, x, y);
          if (p.x >= 0 && p.y >= 0 && p.x < item.width && p.y < item.height) {
            index = i;
            close = item.hitClose(p);
            break;
          }
        }
        panelArea.hoverIndex = index;
        panelArea.overClose = close;
      }

      onPositionChanged: mouse => panelArea.refresh(mouse.x, mouse.y)

      onExited: {
        panelArea.hoverIndex = -1;
        panelArea.overClose = false;
      }

      onClicked: mouse => {
        panelArea.refresh(mouse.x, mouse.y);
        const item = panelArea.hoverIndex >= 0 ? cards.itemAt(panelArea.hoverIndex) : null;
        const toplevel = item?.toplevel ?? null;
        if (!toplevel || item.closing)
          return;
        if (mouse.button === Qt.MiddleButton || panelArea.overClose) {
          item.requestClose();
        } else {
          // The grab goes first, so it cannot override the focus request that follows
          root.dock.dismissPreview();
          toplevel.activate();
        }
      }
    }
  }
}
