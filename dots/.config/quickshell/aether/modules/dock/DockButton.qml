import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

RippleButton {
  id: root
  property bool vertical: false
  property string dockPosition: "bottom"

  Layout.fillHeight: !vertical
  Layout.fillWidth: vertical

  // Layout.topMargin: Appearance.sizes.elevationMargin - Appearance.sizes.hyprlandGapsOut

  buttonRadius: Appearance.rounding.normal

  implicitWidth: vertical ? (implicitHeight - topInset - bottomInset) : (implicitHeight - topInset - bottomInset)
  // implicitHeight: 50

  colBackgroundHover: Appearance.colors.colLayer0Hover
  colRipple: Appearance.colors.colLayer0Active

  colBackground: "transparent"
  // background.implicitHeight: 50
  background.implicitWidth: 50
}
