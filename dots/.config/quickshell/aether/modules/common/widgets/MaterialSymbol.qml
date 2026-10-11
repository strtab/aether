import qs.modules.common
import QtQuick

StyledText {
  id: root
  property real iconSize: 14
  property real fill: 0
  property real truncatedFill: fill.toFixed(1) // Reduce memory consumption spikes from constant font remapping
  renderType: Text.NativeRendering
  font {
    hintingPreference: Font.PreferNoHinting
    family: Appearance?.font.family.iconMaterial ?? "Material Symbols Rounded"
    weight: Font.Normal + (Font.DemiBold - Font.Normal) * truncatedFill
    pointSize: root.iconSize
    variableAxes: {
      "FILL": root.truncatedFill,
      "opsz": root.iconSize
    }
  }

  Behavior on fill { // Leaky leaky, no good
    NumberAnimation {
      duration: Appearance?.animation.elementMoveFast.duration ?? 200
      easing.type: Appearance?.animation.elementMoveFast.type ?? Easing.BezierSpline
      easing.bezierCurve: Appearance?.animation.elementMoveFast.bezierCurve ?? [0.34, 0.80, 0.34, 1.00, 1, 1]
    }
  }
}
