import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

StyledText {
  Layout.fillWidth: true
  font.pointSize: 20
  font.weight: 350
  styleColor: Appearance.colors.colShadow
  animateChange: Config.options.background.widgets.clock.digital.animateChange
}
