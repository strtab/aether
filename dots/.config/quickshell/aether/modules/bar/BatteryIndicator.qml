import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

Item {
  id: root
  property color color: Config.options.bar.background.enable ? Appearance.colors.colOnLayer1 : Appearance.colors.onMenubarBackground

  readonly property var chargeState: Battery.chargeState
  readonly property bool isCharging: Battery.isCharging
  readonly property bool isPluggedIn: Battery.isPluggedIn
  readonly property real percentage: Battery.percentage
  readonly property bool isLow: percentage <= Config.options.battery.low / 100

  implicitWidth: rowLayout.implicitWidth
  implicitHeight: Appearance.sizes.barHeight

  RowLayout {
    id: rowLayout
    anchors.centerIn: parent
    Layout.fillHeight: true

    MaterialSymbol {
      id: batteryIcon
      text: Icons.getBatteryIcon(percentage)
      color: root.color
      iconSize: Appearance.font.pixelSize.larger + 2
      Layout.alignment: Qt.AlignVCenter
      Layout.preferredHeight: Appearance.font.pixelSize.larger + 2
    }

    // StyledText {
    //   Layout.leftMargin: 2
    //   Layout.alignment: Qt.AlignVCenter
    //   font.pixelSize: Appearance.font.pixelSize.small
    //   text: root.percentage + "%"
    // }
  }
}
