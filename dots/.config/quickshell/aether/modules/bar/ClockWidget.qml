import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

Item {
  id: root
  property bool showDate: Config.options.bar?.clock?.showDate
  property color color: Appearance.colors.onMenubarBackground

  implicitWidth: rowLayout.implicitWidth
  implicitHeight: Appearance.sizes.barHeight

  RowLayout {
    id: rowLayout
    anchors.centerIn: parent
    spacing: 4

    StyledText {
      Layout.fillHeight: true
      visible: root.showDate
      font.pixelSize: Appearance.font.pixelSize.large
      font.family: Appearance.font.family.numbers
      color: root.color
      text: DateTime.longDate
    }

    StyledText {
      Layout.fillHeight: true
      visible: root.showDate
      font.pixelSize: Appearance.font.pixelSize.large
      color: root.color
      text: " "
    }

    StyledText {
      Layout.fillHeight: true
      font.pixelSize: Appearance.font.pixelSize.large
      font.family: Appearance.font.family.monospaced
      color: root.color
      text: DateTime.time
    }
  }
}
