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
    OptionalMaterialSymbol {
      icon: root.icon
      iconSize: Appearance.font.pixelSize.hugeass
    }
    StyledText {
      text: root.title
      font.pixelSize: Appearance.font.pixelSize.larger
      font.weight: Font.Medium
      color: Appearance.colors.colOnSecondaryContainer
    }
  }

  Item {
    Layout.fillWidth: true
    implicitWidth: sectionContent.implicitWidth + sectionContent.anchors.margins * 2
    implicitHeight: sectionContent.implicitHeight + sectionContent.anchors.margins * 2

    anchors {
      leftMargin: 16
      rightMargin: 16
    }

    StyledRectangularShadow {
      target: card
    }

    Rectangle {
      id: card
      anchors.fill: parent
      radius: Appearance.rounding.large
      color: Appearance.colors.colSurfaceRaised

      GlassBevel {
        anchors.fill: parent
        radius: card.radius
      }

      ColumnLayout {
        id: sectionContent
        anchors {
          left: parent.left
          right: parent.right
          top: parent.top
          margins: 8
        }
        spacing: 8
      }
    }
  }
}
