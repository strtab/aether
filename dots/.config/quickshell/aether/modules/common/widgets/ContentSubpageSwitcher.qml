import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

// Drop this inside any ContentPage to split it into ripple-button-switchable
// subpages, without needing separate .qml files for each one.
//
// Usage:
//   ContentSubPageSwitcher {
//     Layout.fillWidth: true
//     Layout.fillHeight: true
//     subPages: [
//       { name: "General", icon: "settings", component: generalSubPage },
//       { name: "Colors",  icon: "palette",  component: colorsSubPage }
//     ]
//   }
//   Component { id: generalSubPage; ColumnLayout { ... } }
//   Component { id: colorsSubPage;  ColumnLayout { ... } }
ColumnLayout {
  id: root

  // Each entry: { name: string, icon?: string, component: Component }
  property var subPages: []
  property int currentSubPage: 0

  spacing: 12

  RowLayout {
    id: tabBar
    Layout.fillWidth: true
    spacing: 4

    Repeater {
      model: root.subPages

      delegate: RippleButton {
        id: tabButton
        required property var modelData
        required property int index

        Layout.fillWidth: true
        rippleEnabled: false

        toggled: root.currentSubPage === index
        onPressed: root.currentSubPage = index

        colBackgroundHover: Appearance.colors.colLayer2Hover
        colBackgroundToggled: Appearance.colors.colSecondaryContainer
        colBackgroundToggledHover: Appearance.colors.colSecondaryContainerHover
        colRippleToggled: Appearance.colors.colSecondaryContainerActive

        contentItem: RowLayout {
          spacing: 6
          Layout.alignment: Qt.AlignHCenter

          MaterialSymbol {
            visible: tabButton.modelData.icon !== undefined
            color: tabButton.toggled ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnLayer1
            iconSize: Appearance.font.pixelSize.large
            text: tabButton.modelData.icon ?? ""
            fill: tabButton.toggled ? 1 : 0
          }
          StyledText {
            color: tabButton.toggled ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnLayer1
            text: tabButton.modelData.name
          }
        }
      }
    }
  }

  Loader {
    id: subPageLoader
    Layout.fillWidth: true
    Layout.fillHeight: true
    opacity: 1.0

    Component.onCompleted: sourceComponent = root.subPages[root.currentSubPage]?.component

    Connections {
      target: root
      function onCurrentSubPageChanged() {
        switchAnim.complete();
        switchAnim.start();
      }
    }

    // Same fade-out/swap/fade-in pattern used for the top-level pageLoader in settings.qml
    SequentialAnimation {
      id: switchAnim

      NumberAnimation {
        target: subPageLoader
        properties: "opacity"
        from: 1
        to: 0
        duration: 100
        easing.type: Appearance.animation.elementMoveExit.type
        easing.bezierCurve: Appearance.animationCurves.emphasizedFirstHalf
      }
      ParallelAnimation {
        PropertyAction {
          target: subPageLoader
          property: "sourceComponent"
          value: root.subPages[root.currentSubPage]?.component
        }
      }
      ParallelAnimation {
        NumberAnimation {
          target: subPageLoader
          properties: "opacity"
          from: 0
          to: 1
          duration: 200
          easing.type: Appearance.animation.elementMoveEnter.type
          easing.bezierCurve: Appearance.animationCurves.emphasizedLastHalf
        }
      }
    }
  }
}
