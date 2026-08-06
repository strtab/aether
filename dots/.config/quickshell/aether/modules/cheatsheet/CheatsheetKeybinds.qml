pragma ComponentBehavior: Bound

import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell

Item {
  id: root
  property real padding: 4
  implicitWidth: QsWindow?.window?.screen.width * 0.6 ?? 0
  implicitHeight: QsWindow?.window?.screen.height * 0.7 ?? 0

  StyledFlickable {
    id: flickable
    clip: true
    anchors.fill: parent
    anchors.margins: Appearance.rounding.small
    contentHeight: height
    contentWidth: contentContainer.width

    Item {
      id: contentContainer
      // Never smaller than the visible area, so the Flow has room to be centered
      width: Math.max(flickable.width, flow.implicitWidth)
      height: flickable.height

      Flow {
        id: flow
        anchors.horizontalCenter: parent.horizontalCenter
        height: flickable.height
        flow: Flow.TopToBottom
        spacing: 10
        Repeater {
          model: [...HyprlandKeybinds.keybindCategories, ""]
          delegate: CheatsheetKeybindsCategory {
            required property var modelData
            categoryName: modelData
          }
        }
      }
    }
  }

  ScrollEdgeFade {
    target: flickable
    vertical: false
    color: Appearance.colors.colLayer0Base
  }
}
