import QtQuick
import qs.modules.common

// PopupMenuItem with a check mark at the right while checked is true
PopupMenuItem {
  id: toggle

  property bool checked: false

  labelRightMargin: 32

  // Material Symbols ligature name
  Text {
    anchors.right: parent.right
    anchors.rightMargin: 10
    anchors.verticalCenter: parent.verticalCenter
    visible: toggle.checked
    text: "check"
    font.family: Appearance.font.family.iconMaterial
    font.pixelSize: 16
    color: toggle.danger ? Appearance.colors.colError : Appearance.colors.colOnLayer1
  }
}
