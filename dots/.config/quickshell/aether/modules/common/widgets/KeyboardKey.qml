import qs.modules.common
import QtQuick

Rectangle {
  id: root
  property string key

  property real horizontalPadding: 6
  property real verticalPadding: 1
  property real borderWidth: 1
  property real borderRadius: 8
  property real pixelSize: Appearance.font.pixelSize.smaller

  property color borderColor: Appearance.m3colors.m3onSecondaryFixedVariant
  property color keyColor: Appearance.m3colors.m3surfaceContainerLow
  property color fontColor: Appearance.m3colors.m3outline

  implicitWidth: keyFace.implicitWidth + borderWidth * 2
  implicitHeight: keyFace.implicitHeight + borderWidth * 2
  radius: borderRadius
  color: borderColor

  Rectangle {
    id: keyFace
    anchors {
      fill: parent
      topMargin: borderWidth
      leftMargin: borderWidth
      rightMargin: borderWidth
      bottomMargin: borderWidth
    }
    implicitWidth: keyText.implicitWidth + horizontalPadding * 2
    implicitHeight: keyText.implicitHeight + verticalPadding * 2
    color: keyColor
    radius: borderRadius - borderWidth

    StyledText {
      id: keyText
      anchors.centerIn: parent
      font.family: Appearance.font.family.monospace
      color: root.fontColor
      font.pixelSize: root.pixelSize
      text: key
    }
  }
}
