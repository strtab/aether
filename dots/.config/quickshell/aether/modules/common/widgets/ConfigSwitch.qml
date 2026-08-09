import qs.modules.common.widgets
import qs.modules.common
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

RippleButton {
  id: root
  property string buttonIcon
  property string description: ""
  property alias iconSize: iconWidget.iconSize
  colBackgroundHover: "transparent"

  Layout.fillWidth: true
  implicitHeight: contentItem.implicitHeight + 15
  font.pixelSize: Appearance.font.pixelSize.small

  onClicked: checked = !checked

  contentItem: RowLayout {
    spacing: 0
    OptionalMaterialSymbol {
      id: iconWidget
      icon: root.buttonIcon
      opacity: root.enabled ? 1 : 0.4
      iconSize: Appearance.font.pixelSize.larger
      Layout.rightMargin: 20
    }
    ColumnLayout {
      Layout.fillWidth: true
      spacing: 2

      StyledText {
        id: labelWidget
        Layout.fillWidth: true
        text: root.text
        font: root.font
        color: Appearance.colors.colOnSecondaryContainer
        opacity: root.enabled ? 1 : 0.4
      }

      StyledText {
        Layout.fillWidth: true
        Layout.leftMargin: 2
        color: Appearance.colors.colSubtext
        visible: root.description && root.description.length > 0
        text: root.description
        wrapMode: Text.WordWrap
      }
    }
    StyledSwitch {
      id: switchWidget
      down: root.down
      Layout.fillWidth: false
      checked: root.checked
      onClicked: root.clicked()
    }
  }
}
