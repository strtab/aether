import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

ColumnLayout {
  id: root
  property string title
  property string icon: ""
  default property alias contentData: sectionContent.data

  Layout.fillWidth: true
  spacing: 6

  RowLayout {
    spacing: 6
    Layout.leftMargin: 10
    StyledText {
      text: root.title
      font.pixelSize: Appearance.font.pixelSize.larger
      color: Appearance.colors.colOnSecondaryContainer
    }
  }

  Item {
    Layout.fillWidth: true
    implicitWidth: sectionContent.implicitWidth + sectionContent.anchors.margins * 2
    implicitHeight: sectionContent.implicitHeight + sectionContent.anchors.margins * 2

    anchors {
      margins: 10
    }

    StyledRectangularShadow {
      target: card
    }

    Rectangle {
      id: card
      anchors.fill: parent
      radius: Appearance.rounding.small
      color: Appearance.colors.colBackgroundSurfaceContainer

      ColumnLayout {
        id: sectionContent
        anchors {
          left: parent.left
          right: parent.right
          top: parent.top
          margins: 15
        }
        spacing: 8
      }
    }
  }
}
