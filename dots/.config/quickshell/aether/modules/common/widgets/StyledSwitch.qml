import qs.modules.common
import QtQuick
import QtQuick.Controls

Switch {
  id: root
  property real scale: 0.75
  implicitHeight: 32 * root.scale
  implicitWidth: 64 * root.scale

  property color activeHandleColor: "#FFFFFF"
  property color inactiveHandleColor: Appearance.m3colors.m3outline
  property color activeColor: Appearance.colors.colSecondaryContainerActive
  property color inactiveColor: Appearance?.m3colors.m3surfaceBright

  PointingHandInteraction {}

  background: Rectangle {
    width: parent.width
    height: parent.height
    radius: Appearance?.rounding.full
    color: root.checked ? root.activeColor : root.inactiveColor

    Behavior on color {
      animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
    }
    Behavior on border.color {
      animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
    }
  }

  indicator: Rectangle {
    readonly property real thumbSize: 28 * root.scale
    readonly property real pad: 2 * root.scale
    readonly property real stretchExtra: 4 * root.scale

    width: thumbSize
    height: thumbSize
    radius: Appearance.rounding.full
    color: root.checked ? root.activeHandleColor : root.inactiveHandleColor
    anchors.verticalCenter: parent.verticalCenter
    anchors.left: parent.left
    anchors.leftMargin: root.checked ? root.width - width - pad : pad

    Behavior on anchors.leftMargin {
      NumberAnimation {
        duration: 320
        easing.type: Easing.BezierSpline
        easing.bezierCurve: [0.42, 1.5, 0.28, 0.95, 1, 1]
      }
    }
    Behavior on color {
      animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
    }
  }
}
