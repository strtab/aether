import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

// Drop this inside a ContentPage. It first shows a plain list of buttons
// (one per subpage). Pressing one replaces the view with that subpage's
// content and a back button that returns to the list.
//
// Usage:
//   ContentSubPageNav {
//     Layout.fillWidth: true
//     Layout.fillHeight: true
//     subPages: [
//       { name: "General", icon: "settings", description: "Basic options", component: generalSubPage },
//       { name: "Colors",  icon: "palette",  description: "Palette and accent color", component: colorsSubPage }
//     ]
//   }
//   Component { id: generalSubPage; ColumnLayout { ... } }
//   Component { id: colorsSubPage;  ColumnLayout { ... } }
ColumnLayout {
  id: root

  // Each entry: { name: string, icon?: string, description?: string, component: Component }
  property var subPages: []
  // -1 means "showing the overview list"
  property int currentSubPage: -1

  spacing: 8

  // Overview: list of entry buttons
  ColumnLayout {
    id: overview
    Layout.fillWidth: true
    visible: opacity > 0
    opacity: root.currentSubPage === -1 ? 1 : 0
    spacing: 4

    Behavior on opacity {
      animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }

    Repeater {
      model: root.subPages

      delegate: RippleButton {
        id: entryButton
        required property var modelData
        required property int index

        Layout.fillWidth: true
        implicitHeight: 56
        rippleEnabled: false

        colBackgroundHover: Appearance.colors.colLayer2Hover

        onPressed: root.currentSubPage = index

        contentItem: RowLayout {
          spacing: 12

          ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
              Layout.fillWidth: true
              color: Appearance.colors.colOnLayer1
              text: entryButton.modelData.name
            }
            StyledText {
              Layout.fillWidth: true
              visible: entryButton.modelData.description !== undefined
              color: Appearance.colors.colSubtext
              font.pixelSize: Appearance.font.pixelSize.smaller
              text: entryButton.modelData.description ?? ""
              wrapMode: Text.WordWrap
            }
          }

          MaterialSymbol {
            color: Appearance.colors.colSubtext
            iconSize: Appearance.font.pixelSize.large
            text: "chevron_right"
          }
        }
      }
    }
  }

  // Opened subpage: header with a back button, then the subpage content
  ColumnLayout {
    id: subPageView
    Layout.fillWidth: true
    Layout.fillHeight: true
    visible: opacity > 0
    opacity: root.currentSubPage !== -1 ? 1 : 0
    spacing: 8

    Behavior on opacity {
      animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }

    RowLayout {
      Layout.fillWidth: true
      spacing: 8

      RippleButton {
        implicitWidth: 32
        implicitHeight: 32
        rippleEnabled: false
        colBackgroundHover: Appearance.colors.colLayer2Hover
        onPressed: root.currentSubPage = -1

        contentItem: MaterialSymbol {
          anchors.centerIn: parent
          color: Appearance.colors.colOnLayer1
          iconSize: Appearance.font.pixelSize.large
          text: "arrow_back"
        }
      }

      StyledText {
        font.pixelSize: Appearance.font.pixelSize.larger
        color: Appearance.colors.colOnLayer1
        text: root.currentSubPage !== -1 ? (root.subPages[root.currentSubPage]?.name ?? "") : ""
      }
    }

    Loader {
      id: subPageLoader
      Layout.fillWidth: true
      Layout.fillHeight: true
      opacity: 1.0

      active: root.currentSubPage !== -1

      Component.onCompleted: {
        if (root.currentSubPage !== -1)
          sourceComponent = root.subPages[root.currentSubPage]?.component;
      }

      // Listen on root, not on the loader itself, so the PropertyAction below
      // does not re-trigger this same animation (that caused an infinite loop).
      Connections {
        target: root
        function onCurrentSubPageChanged() {
          if (root.currentSubPage === -1)
            return; // going back, subPageView itself is fading out already
          switchAnim.complete();
          switchAnim.start();
        }
      }

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
}
