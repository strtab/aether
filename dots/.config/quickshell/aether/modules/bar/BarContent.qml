import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower
import qs
import qs.services
import qs.modules.bar
import qs.modules.bar.tray
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

Item { // Bar content region
  id: root

  property int itemSpacing: 22

  // Background shadow
  Loader {
    active: Config.options.bar.background.enable && Config.options.bar.cornerStyle === 1 && Config.options.bar.floatStyleShadow
    anchors.fill: barBackground
    sourceComponent: StyledRectangularShadow {
      anchors.fill: undefined // The loader's anchors act on this, and this should not have any anchor
      target: barBackground
    }
  }

  // Background
  Rectangle {
    id: barBackground
    anchors {
      fill: parent
      margins: Config.options.bar.cornerStyle === 1 ? (Appearance.sizes.hyprlandGapsOut) : 0 // idk why but +1 is needed
    }
    color: Config.options.bar.background.enable ? Appearance.colors.colMenubarBackground : "transparent"
    radius: Config.options.bar.cornerStyle === 1 ? Appearance.rounding.normal : 0
    border.width: Config.options.bar.cornerStyle === 1 ? 1 : 0
    border.color: Appearance.colors.colLayer0Border
  }

  FocusedScrollMouseArea { // Left side
    id: leading

    anchors {
      top: parent.top
      bottom: parent.bottom
      left: parent.left
      right: trailing.left
    }

    implicitWidth: leadingGroup.implicitWidth
    implicitHeight: Appearance.sizes.baseBarHeight

    onScrollDown: Brightness.decreaseBrightness()
    onScrollUp: Brightness.increaseBrightness()
    onMovedAway: GlobalStates.osdBrightnessOpen = false

    // Visual content
    ScrollHint {
      reveal: leading.hovered
      icon: Hyprsunset.gamma === 100 ? "light_mode" : "wb_twilight"
      tooltipText: Translation.tr("Scroll to change brightness")
      side: "left"
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
    }

    RowLayout {
      id: leadingGroup
      anchors.fill: parent
      spacing: itemSpacing

      Workspaces {
        visible: Config.options?.bar?.workspaces?.enable
        Layout.leftMargin: Config.options?.bar?.workspaces?.enable ? Appearance.rounding.screenRounding : 0
      }
      ActiveWindow {
        Layout.leftMargin: Config.options?.bar?.workspaces?.enable ? 0 : Appearance.rounding.screenRounding
        Layout.rightMargin: Appearance.rounding.screenRounding
        Layout.fillWidth: true
        Layout.fillHeight: true
      }
      Item { // Filler
        Layout.fillWidth: true
        Layout.fillHeight: true
      }
    }
  }

  FocusedScrollMouseArea { // Right side
    id: trailing

    anchors {
      top: parent.top
      bottom: parent.bottom
      right: parent.right
    }

    implicitWidth: trailingGroup.implicitWidth
    implicitHeight: Appearance.sizes.baseBarHeight

    onScrollDown: Audio.decrementVolume()
    onScrollUp: Audio.incrementVolume()
    onMovedAway: GlobalStates.osdVolumeOpen = false

    // Visual content
    ScrollHint {
      reveal: trailing.hovered
      icon: "volume_up"
      tooltipText: Translation.tr("Scroll to change volume")
      side: "right"
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
    }

    RowLayout {
      id: trailingGroup
      anchors.fill: parent
      layoutDirection: Qt.RightToLeft
      spacing: 0

      RippleButton { // Clock
        visible: Config.options.bar?.clock?.enable

        Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
        Layout.fillWidth: false
        Layout.rightMargin: Appearance.rounding.screenRounding
        Layout.leftMargin: 0

        implicitWidth: clockWidget.width * 1.2
        implicitHeight: clockWidget.height - 5

        buttonRadius: Appearance.rounding.large
        colBackground: "transparent"
        colBackgroundHover: Appearance.colors.colLayer1Hover
        colRipple: Appearance.colors.colLayer1Active
        colBackgroundToggled: Appearance.colors.colSecondaryContainer
        colBackgroundToggledHover: Appearance.colors.colSecondaryContainerHover
        colRippleToggled: Appearance.colors.colSecondaryContainerActive
        toggled: GlobalStates.notificationCenterOpen

        onPressed: {
          GlobalStates.notificationCenterOpen = !GlobalStates.notificationCenterOpen;
        }

        ClockWidget {
          id: clockWidget
          anchors.centerIn: parent
        }
      }

      RippleButton { // Indicators
        id: rightSidebarButton

        Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
        Layout.rightMargin: Config.options.bar?.clock?.enable ? 0 : Appearance.rounding.screenRounding
        Layout.fillWidth: false

        implicitWidth: indicatorsRowLayout.width + 10 * 2
        implicitHeight: indicatorsRowLayout.height - 5

        buttonRadius: Appearance.rounding.large
        colBackground: "transparent"
        colBackgroundHover: Appearance.colors.colLayer1Hover
        colRipple: Appearance.colors.colLayer1Active
        colBackgroundToggled: Appearance.colors.colSecondaryContainer
        colBackgroundToggledHover: Appearance.colors.colSecondaryContainerHover
        colRippleToggled: Appearance.colors.colSecondaryContainerActive
        toggled: GlobalStates.sidebarRightOpen

        onPressed: {
          GlobalStates.sidebarRightOpen = !GlobalStates.sidebarRightOpen;
        }

        RowLayout {
          id: indicatorsRowLayout
          anchors.centerIn: parent
          property real realSpacing: root.itemSpacing
          spacing: 0

          Revealer {
            reveal: Audio.sink?.audio?.muted ?? false
            Layout.rightMargin: reveal ? indicatorsRowLayout.realSpacing : 0
            Behavior on Layout.rightMargin {
              animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
            }
            MaterialSymbol {
              text: "volume_off"
              iconSize: Appearance.font.pixelSize.larger
              color: Appearance.colors.onMenubarBackground
            }
          }
          Revealer {
            reveal: Audio.source?.audio?.muted ?? false
            Layout.rightMargin: reveal ? indicatorsRowLayout.realSpacing : 0
            Behavior on Layout.rightMargin {
              animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
            }
            MaterialSymbol {
              text: "mic_off"
              iconSize: Appearance.font.pixelSize.larger
              color: Appearance.colors.onMenubarBackground
            }
          }
          HyprlandXkbIndicator {
            Layout.alignment: Qt.AlignVCenter
            Layout.rightMargin: indicatorsRowLayout.realSpacing
          }
          MaterialSymbol {
            text: Network.materialSymbol
            iconSize: Appearance.font.pixelSize.larger
            color: Appearance.colors.onMenubarBackground
          }
        }
      }

      SysTray {
        Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
        Layout.rightMargin: itemSpacing * 0.8
        implicitHeight: indicatorsRowLayout.height - 5 // litle shitty
        Layout.fillWidth: false
        Layout.fillHeight: false
      }

      Item { // Filler
        Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
        Layout.fillWidth: true
        Layout.fillHeight: true
      }
    }
  }
}
