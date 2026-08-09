import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.modules.common
import qs.modules.common.widgets

TextField {
  id: root

  property alias colBackground: background.color

  Layout.fillHeight: true
  implicitWidth: 200
  padding: 10

  placeholderTextColor: Appearance.colors.colSubtext
  color: Appearance.colors.colOnLayer1
  selectedTextColor: Appearance.colors.colOnSecondaryContainer
  selectionColor: Appearance.colors.colSecondaryContainer

  renderType: Text.NativeRendering

  font {
    family: Appearance.font.family.main
    pixelSize: Appearance.font.pixelSize.small
    hintingPreference: Font.PreferFullHinting
    variableAxes: Appearance.font.variableAxes.main
  }

  Keys.onPressed: event => {
    if (event.key === Qt.Key_Escape) {
      root.focus = false;
    }
  }

  background: Rectangle {
    id: background
    color: Appearance.colors.colGlassStrong
    radius: Appearance.rounding.small
    border.width: root.activeFocus ? 2 : 1
    border.color: root.activeFocus ? Appearance.colors.colTertiary : Appearance.colors.colHairline

    Behavior on border.color {
      animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
    }
  }
}
