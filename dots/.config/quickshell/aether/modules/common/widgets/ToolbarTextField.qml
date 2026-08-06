import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.modules.common
import qs.modules.common.widgets

TextField {
  id: filterField

  property alias colBackground: background.color

  Layout.fillHeight: true
  implicitWidth: 200
  padding: 10

  placeholderTextColor: Appearance.colors.colSubtext
  color: Appearance.colors.colOnLayer1
  font {
    family: Appearance.font.family.main
    pixelSize: Appearance.font.pixelSize.small
    hintingPreference: Font.PreferFullHinting
    variableAxes: Appearance.font.variableAxes.main
  }
  renderType: Text.NativeRendering
  selectedTextColor: Appearance.colors.colOnSecondaryContainer
  selectionColor: Appearance.colors.colSecondaryContainer

  background: Rectangle {
    id: background
    color: Appearance.colors.colGlassStrong
    radius: Appearance.rounding.full
    border.width: 1
    border.color: filterField.activeFocus ? Appearance.colors.colTertiary : Appearance.colors.colHairline

    Behavior on border.color {
      animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
    }

    GlassBevel {
      anchors.fill: parent
      radius: background.radius
    }
  }
}
