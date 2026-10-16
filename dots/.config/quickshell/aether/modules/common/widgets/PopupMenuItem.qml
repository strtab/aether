import QtQuick
import QtQuick.Layouts
import qs.modules.common

// Row of a PopupMenu. A click closes the menu first, then emits triggered.
Rectangle {
  id: item

  property string label: ""
  property bool danger: false
  // Space kept free at the right of the label, for example for a check mark
  property real labelRightMargin: 10
  signal triggered

  Layout.fillWidth: true
  Layout.preferredHeight: 28
  radius: Appearance.rounding.unsharpen
  color: area.containsMouse ? Appearance.colors.colLayer1Hover : "transparent"

  // Walks up to the column of the PopupMenu that holds this row
  function closeMenu() {
    for (let p = item.parent; p; p = p.parent) {
      if (p.popupMenu) {
        p.popupMenu.dismiss();
        return;
      }
    }
  }

  StyledText {
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.leftMargin: 10
    anchors.rightMargin: item.labelRightMargin
    anchors.verticalCenter: parent.verticalCenter
    text: item.label
    elide: Text.ElideRight
    color: item.danger ? Appearance.colors.colError : Appearance.colors.colOnLayer1
    style: Appearance.font.style.menu
  }

  MouseArea {
    id: area
    anchors.fill: parent
    hoverEnabled: true
    onClicked: {
      item.closeMenu();
      item.triggered();
    }
  }
}
