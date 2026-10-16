import QtQuick
import qs.modules.common

Rectangle {
  // Hovered or being dragged
  property bool active: false

  implicitWidth: 1
  radius: width / 2
  color: Appearance.colors.colOutlineVariant

  Behavior on implicitWidth {
    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
  }
  Behavior on color {
    animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
  }
}
