import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

RowLayout {
  id: root

  property string title: ""
  property string description: ""
  // Anything placed inside <ContentSubsectionRow>...</ContentSubsectionRow>
  // goes into the right-side control slot (e.g. a ComboBox, TextField, Switch).
  default property alias contentData: controlSlot.data

  Layout.fillWidth: true
  Layout.bottomMargin: 10
  spacing: 16

  // Left side: title + description stacked vertically
  ColumnLayout {
    Layout.fillWidth: true
    spacing: 2

    ContentSubsectionLabel {
      id: label
      Layout.fillWidth: true
      color: Appearance.colors.colOnSecondaryContainer
      visible: root.title && root.title.length > 0
      text: root.title
    }

    StyledText {
      id: description
      Layout.fillWidth: true
      Layout.leftMargin: 2
      color: Appearance.colors.colSubtext
      visible: root.description && root.description.length > 0
      text: root.description
      wrapMode: Text.WordWrap
    }
  }

  // Right side: a single control (kept at its own natural/compact width,
  // vertically centered against the two-line text block on the left)
  RowLayout {
    id: controlSlot
    Layout.alignment: Qt.AlignVCenter
    spacing: 8
  }
}
