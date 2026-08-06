pragma ComponentBehavior: Bound
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Effects
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

Item {
  id: root
  property real maxWindowPreviewHeight: 200
  property real maxWindowPreviewWidth: 300
  property real windowControlsHeight: 30
  property real buttonPadding: 5

  property Item lastHoveredButton: null
  property bool buttonHovered: false
  property bool requestDockShow: previewPopup.show

  // Propagated hovered index for neighbor magnify in macOS style
  property int hoveredIndex: -1

  // Deferred reset — avoids the race where buttonHovered=false of the old
  // item arrives after buttonHovered=true of the new item.
  Timer {
    id: hoverResetTimer
    interval: 32   // one frame — enough for the new hover to fire first
    repeat: false
    onTriggered: root.hoveredIndex = -1
  }

  Layout.fillHeight: true
  Layout.topMargin: Appearance.sizes.hyprlandGapsOut

  property real btnSpacing: 2
  property real btnSize: Config.options?.dock?.iconSize ?? 35

  property var _workOrder: []
  property int activeDragVisualIndex: -1
  property bool _dragging: false

  implicitWidth: _workOrder.length * btnSize + Math.max(0, _workOrder.length - 1) * btnSpacing

  Behavior on implicitWidth {
    enabled: Appearance.animationsEnabled ?? true
    animation: NumberAnimation {
      duration: Appearance.animation.elementMoveFast.duration
      easing.type: Appearance.animation.elementMoveFast.type
      easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
    }
  }

  Component.onCompleted: {
    _workOrder = TaskbarApps.apps.map(a => a.appId);
  }

  function swapSlots(fromPos, toPos) {
    if (fromPos === toPos)
      return;
    const arr = _workOrder.slice();
    const tmp = arr[fromPos];
    arr[fromPos] = arr[toPos];
    arr[toPos] = tmp;
    _workOrder = arr;
  }

  Connections {
    target: TaskbarApps
    function onAppsChanged() {
      if (root._dragging)
        return;
      const ids = TaskbarApps.apps.map(a => a.appId);
      let next = root._workOrder.filter(id => ids.includes(id));
      for (const a of TaskbarApps.apps)
        if (!next.includes(a.appId))
          next.push(a.appId);
      root._workOrder = next;
    }
  }

  function popupCenterXForButton(button) {
    if (!button || !root.QsWindow)
      return 0;
    return root.QsWindow.mapFromItem(button, button.width / 2, 0).x;
  }

  Repeater {
    id: slotRepeater
    model: root._workOrder.length

    delegate: Item {
      id: slotItem
      required property int index

      property string appId: root._workOrder[index] ?? ""
      property var appEntry: TaskbarApps.apps.find(a => a.appId === appId) ?? null

      width: slotItem.appEntry.appId === "SEPARATOR" ? 1 : root.btnSize
      height: root.height - 10

      x: index * (root.btnSize + root.btnSpacing)
      opacity: root.activeDragVisualIndex === index ? 0.0 : 1.0

      Behavior on opacity {
        NumberAnimation {
          duration: 110
        }
      }

      Item {
        visible: dragHandler.active
        z: 1000
        width: root.btnSize
        height: root.btnSize
        anchors.verticalCenter: parent.verticalCenter

        x: {
          if (!dragHandler.active)
            return 0;
          const lp = slotItem.mapFromItem(null, dragHandler.centroid.scenePosition.x, dragHandler.centroid.scenePosition.y);
          return lp.x - width / 2;
        }
        IconImage {
          anchors.centerIn: parent
          implicitSize: root.btnSize * 0.65
          source: Quickshell.iconPath(AppSearch.guessIcon(root._workOrder[root.activeDragVisualIndex] ?? ""), "image-missing")
          opacity: 0.85
          layer.enabled: true
          layer.effect: MultiEffect {
            shadowEnabled: true
            shadowVerticalOffset: 4
            shadowBlur: 0.65
            shadowColor: "#80000000"
          }
        }
      }

      DockAppButton {
        id: dockAppBtn
        anchors.fill: parent
        appToplevel: slotItem.appEntry
        appListRoot: root
        listIndex: slotItem.index

        topInset: Appearance.sizes.hyprlandGapsOut + root.buttonPadding
        bottomInset: Appearance.sizes.hyprlandGapsOut + root.buttonPadding

        onHoveredChanged: {
          if (!root._dragging && buttonHovered) {
            hoverResetTimer.stop();
            root.hoveredIndex = slotItem.index;
          } else {
            hoverResetTimer.restart();
          }
        }
      }

      DragHandler {
        id: dragHandler
        target: null
        grabPermissions: PointerHandler.CanTakeOverFromAnything

        onActiveChanged: {
          if (active) {
            root._dragging = true;
            root.activeDragVisualIndex = index;
            root.buttonHovered = false;
            root.hoveredIndex = -1;
            return;
          }
          root.activeDragVisualIndex = -1;
          root._dragging = false;
        }

        onCentroidChanged: {
          if (!active)
            return;
          const curIdx = root.activeDragVisualIndex;
          if (curIdx < 0)
            return;
          const dragX = dragHandler.centroid.scenePosition.x;
          let minDist = Infinity;
          let nearestIdx = curIdx;

          for (let i = 0; i < slotRepeater.count; i++) {
            if (i === curIdx)
              continue;
            const child = slotRepeater.itemAt(i);
            if (!child)
              continue;
            const cc = child.mapToItem(null, child.width / 2, child.height / 2);
            const dist = Math.abs(dragX - cc.x);
            if (dist < minDist) {
              minDist = dist;
              nearestIdx = i;
            }
          }

          if (nearestIdx !== curIdx) {
            const nb = slotRepeater.itemAt(nearestIdx);
            if (!nb)
              return;
            const nc = nb.mapToItem(null, nb.width / 2, nb.height / 2);
            const shouldSwap = nearestIdx > curIdx ? dragX >= nc.x : dragX <= nc.x;
            if (shouldSwap) {
              root.swapSlots(curIdx, nearestIdx);
              root.activeDragVisualIndex = nearestIdx;
            }
          }
        }
      }
    }
  }

  PopupWindow {
    id: previewPopup
    property var appTopLevel: root.lastHoveredButton?.appToplevel

    property bool shouldShow: (popupMouseArea.containsMouse || root.buttonHovered) && appTopLevel && appTopLevel.toplevels && appTopLevel.toplevels.length > 0

    property bool show: false
    property real cachedCenterX: 0

    Connections {
      target: root
      function onLastHoveredButtonChanged() {
        if (root.lastHoveredButton && root.QsWindow)
          previewPopup.cachedCenterX = root.popupCenterXForButton(root.lastHoveredButton);
      }
      function onButtonHoveredChanged() {
        if (root.buttonHovered && root.lastHoveredButton && root.QsWindow)
          previewPopup.cachedCenterX = root.popupCenterXForButton(root.lastHoveredButton);
        updateTimer.restart();
      }
    }

    onShouldShowChanged: {
      updateTimer.restart();
    }

    Timer {
      id: updateTimer
      interval: 100
      onTriggered: {
        previewPopup.show = previewPopup.shouldShow;
      }
    }

    anchor {
      window: root.QsWindow.window
      adjustment: PopupAdjustment.None
      gravity: Edges.Top | Edges.Right
      edges: Edges.Top | Edges.Left
    }

    visible: popupBackground.opacity > 0 && (Config.options?.dock?.showPreview ?? true)
    color: "transparent"
    implicitWidth: root.QsWindow.window?.width ?? 1
    implicitHeight: popupMouseArea.implicitHeight + root.windowControlsHeight + Appearance.sizes.elevationMargin * 2

    MouseArea {
      id: popupMouseArea
      anchors.bottom: parent.bottom
      implicitWidth: popupBackground.implicitWidth + Appearance.sizes.elevationMargin * 2
      implicitHeight: root.maxWindowPreviewHeight + root.windowControlsHeight + Appearance.sizes.elevationMargin * 2
      hoverEnabled: true
      x: previewPopup.cachedCenterX - width / 2

      StyledRectangularShadow {
        target: popupBackground
        opacity: previewPopup.show ? 1 : 0
        visible: opacity > 0
        Behavior on opacity {
          animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }
      }

      Rectangle {
        id: popupBackground
        property real padding: 5
        opacity: previewPopup.show ? 1 : 0
        visible: opacity > 0
        Behavior on opacity {
          animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }
        clip: true
        color: Appearance.m3colors.m3surfaceContainer
        radius: Appearance.rounding.normal
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Appearance.sizes.elevationMargin
        anchors.horizontalCenter: parent.horizontalCenter
        implicitHeight: previewRowLayout.implicitHeight + padding * 2
        implicitWidth: previewRowLayout.implicitWidth + padding * 2

        Behavior on implicitWidth {
          animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }
        Behavior on implicitHeight {
          animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }

        RowLayout {
          id: previewRowLayout
          anchors.centerIn: parent
          Repeater {
            model: ScriptModel {
              values: previewPopup.appTopLevel?.toplevels ?? []
            }
            RippleButton {
              id: windowButton
              Layout.fillHeight: true
              required property var modelData
              padding: 0
              middleClickAction: () => {
                windowButton.modelData?.close();
              }
              onClicked: {
                windowButton.modelData?.activate();
              }
              contentItem: ColumnLayout {
                implicitWidth: screencopyView.implicitWidth
                implicitHeight: screencopyView.implicitHeight

                ButtonGroup {
                  contentWidth: parent.width - anchors.margins * 2
                  StyledText {
                    Layout.margins: 5
                    Layout.fillWidth: true
                    font.pixelSize: Appearance.font.pixelSize.small
                    text: windowButton.modelData?.title ?? ""
                    elide: Text.ElideRight
                    color: Appearance.m3colors.m3onSurface
                  }
                  GroupButton {
                    id: closeButton
                    colBackground: ColorUtils.transparentize(Appearance.colors.colSurfaceContainer)
                    baseWidth: root.windowControlsHeight
                    baseHeight: root.windowControlsHeight
                    buttonRadius: Appearance.rounding.full
                    contentItem: MaterialSymbol {
                      anchors.centerIn: parent
                      horizontalAlignment: Text.AlignHCenter
                      text: "close"
                      iconSize: Appearance.font.pixelSize.normal
                      color: Appearance.m3colors.m3onSurface
                    }
                    onClicked: {
                      windowButton.modelData?.close();
                    }
                  }
                }
                Item {
                  Layout.fillWidth: true
                  Layout.fillHeight: true
                  implicitHeight: screencopyView.height
                  implicitWidth: screencopyView.width
                  ScreencopyView {
                    id: screencopyView
                    anchors.centerIn: parent
                    captureSource: windowButton.modelData
                    live: true
                    paintCursor: true
                    constraintSize: Qt.size(root.maxWindowPreviewWidth, root.maxWindowPreviewHeight)
                    layer.enabled: true
                    layer.effect: OpacityMask {
                      maskSource: Rectangle {
                        width: screencopyView.width
                        height: screencopyView.height
                        radius: Appearance.rounding.small
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
