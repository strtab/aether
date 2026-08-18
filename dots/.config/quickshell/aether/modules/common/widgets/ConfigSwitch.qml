import qs.modules.common.widgets
import qs.modules.common
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

RippleButton {
  id: root

  property string title: ""
  property string description: ""

  colBackgroundHover: "transparent"

  Layout.fillWidth: true
  implicitHeight: contentItem.implicitHeight + 15
  font.pixelSize: Appearance.font.pixelSize.small

  onClicked: checked = !checked

  contentItem: ContentSubsection {
    title: root.title
    description: root.description

    StyledSwitch {
      id: switchWidget
      down: root.down
      Layout.fillWidth: false
      checked: root.checked
      onClicked: root.clicked()
    }
  }
}
