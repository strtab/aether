import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

Row {
  id: root
  required property var icon
  required property var label
  spacing: 5

  MaterialSymbol {
    anchors.verticalCenter: parent.verticalCenter
    fill: 0
    font.weight: Font.DemiBold
    text: root.icon
    iconSize: Appearance.font.pixelSize.large
    color: Appearance.colors.colOnSurfaceVariant
  }

  StyledText {
    anchors.verticalCenter: parent.verticalCenter
    style: Appearance.font.style.title2
    text: root.label
    color: Appearance.colors.colOnSurfaceVariant
  }
}
