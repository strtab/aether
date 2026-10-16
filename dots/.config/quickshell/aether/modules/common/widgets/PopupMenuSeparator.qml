import QtQuick
import QtQuick.Layouts
import qs.modules.common

// Thin line between groups of rows in a PopupMenu
Rectangle {
  Layout.fillWidth: true
  Layout.preferredHeight: 1
  Layout.topMargin: 3
  Layout.bottomMargin: 3
  color: Appearance.colors.colOutlineVariant
}
