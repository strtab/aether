import QtQuick
import qs.modules.common

Rectangle {
  // Hovered or being dragged
  property bool active: false

  implicitWidth: 1
  radius: width / 2
  color: Appearance.colors.colOutlineVariant
}
