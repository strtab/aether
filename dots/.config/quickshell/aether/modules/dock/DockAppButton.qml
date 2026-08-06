import qs.services
import qs.modules.common
import qs.modules.common.functions
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

DockButton {
  id: root
  property var appToplevel
  property var appListRoot
  property int delegateIndex: 0
  property int lastFocused: -1
  property int listIndex: -1       // set by the DockApps delegate (required property int index)

  readonly property var toplevels: appToplevel?.toplevels ?? []

  property real iconSize: Config.options?.dock?.iconSize ?? 35
  property bool appIsActive: (toplevels?.find(t => t.activated === true) ?? undefined) !== undefined

  readonly property bool isSeparator: appToplevel.appId === "SEPARATOR"
  readonly property var desktopEntry: DesktopEntries.heuristicLookup(appToplevel.appId)

  enabled: !isSeparator
  implicitWidth: isSeparator ? 1 : implicitHeight - topInset - bottomInset

  colBackgroundHover: "transparent"

  Behavior on iconSize {
    enabled: Appearance.animationsEnabled ?? true
    NumberAnimation {
      duration: Appearance.animation.elementMoveFast.duration
      easing.type: Appearance.animation.elementMoveFast.type
    }
  }

  scale: (appIsActive) ? 1.05 : 1.0

  Behavior on scale {
    enabled: Appearance.animationsEnabled ?? true
    animation: NumberAnimation {
      duration: Appearance.animation.elementMoveFast.duration
      easing.type: Appearance.animation.elementMoveFast.type
      easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
    }
  }

  DockIconOverlay {
    id: overlay
    anchors.fill: parent
    property bool appIsActive: root.appIsActive
    hasWindows: appToplevel.toplevels.length > 0
    buttonHovered: appListRoot?.buttonHovered && appListRoot?.lastHoveredButton === root
    previewVisible: appListRoot?.requestDockShow && appListRoot?.lastHoveredButton === root
    neighborDistance: {
      const hi = root.appListRoot?.hoveredIndex ?? -1;
      return (hi < 0 || root.listIndex < 0) ? 99 : Math.abs(root.listIndex - hi);
    }

    windowCount: appToplevel.toplevels.length
    focusedWindowIndex: root.lastFocused
  }

  // Timer for hover delay before showing preview
  property alias hoverTimer: hoverDelayTimer
  Timer {
    id: hoverDelayTimer
    interval: Config.options?.dock?.hoverPreviewDelay ?? 400
    onTriggered: {
      if (root.hasWindows && root.buttonHovered) {
        root.hoverPreviewRequested();
      }
    }
  }

  // Use RippleButton's built-in buttonHovered instead of separate MouseArea
  onHoveredChanged: {
    if (toplevels.length > 0) {
      if (buttonHovered) {
        appListRoot.lastHoveredButton = root;
        appListRoot.buttonHovered = true;
        // Start hover timer for preview
        if (Config.options?.dock?.hoverPreview !== false) {
          hoverDelayTimer.restart();
        }
      } else {
        if (appListRoot.lastHoveredButton === root) {
          appListRoot.buttonHovered = false;
        }
        hoverDelayTimer.stop();
        // Don't dismiss preview here - let the popup's timer handle it
        // This allows mouse to move from button to popup without closing
      }
    } else {
      hoverDelayTimer.stop();
    }
  }

  Loader {
    active: isSeparator
    anchors {
      fill: parent
      bottomMargin: dockRow.padding + Appearance.rounding.normal
      topMargin: dockRow.padding + Appearance.rounding.normal
    }
    anchors.verticalCenter: parent.verticalCenter
    sourceComponent: DockSeparator {}
  }

  Loader {
    anchors.fill: parent
    active: appToplevel.toplevels.length > 0
    sourceComponent: MouseArea {
      anchors.fill: parent
      hoverEnabled: true
      acceptedButtons: Qt.NoButton
      onEntered: {
        appListRoot.lastHoveredButton = root;
        appListRoot.buttonHovered = true;
        lastFocused = appToplevel.toplevels.length - 1;
      }
      onExited: {
        if (appListRoot.lastHoveredButton === root) {
          appListRoot.buttonHovered = false;
        }
      }
    }
  }

  // onPressed: overlay.clickPulse()
  onClicked: {
    overlay.clickPulse();
    if (appToplevel.toplevels.length === 0) {
      root.desktopEntry?.execute();
      return;
    }
    lastFocused = (lastFocused + 1) % appToplevel.toplevels.length;
    appToplevel.toplevels[lastFocused].activate();
  }

  middleClickAction: () => {
    root.desktopEntry?.execute();
  }
  altAction: () => {
    TaskbarApps.togglePin(appToplevel.appId);
  }

  contentItem: Loader {
    active: !isSeparator
    sourceComponent: Item {
      implicitWidth: root.iconSize
      implicitHeight: root.iconSize
      anchors.centerIn: parent
      scale: overlay.iconScale
      Loader {
        id: iconImageLoader
        anchors.fill: parent
        active: !root.isSeparator
        sourceComponent: IconImage {
          source: Quickshell.iconPath(AppSearch.guessIcon(appToplevel.appId), "archive-manager")
          implicitSize: root.iconSize
        }
      }

      Loader {
        active: Config.options.dock.monochromeIcons
        anchors.fill: iconImageLoader
        sourceComponent: Item {
          Desaturate {
            id: desaturatedIcon
            visible: false
            anchors.fill: parent
            source: iconImageLoader
            desaturation: 0.8
          }
          ColorOverlay {
            anchors.fill: desaturatedIcon
            source: desaturatedIcon
            color: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.9)
          }
        }
      }
    }
  }
}
