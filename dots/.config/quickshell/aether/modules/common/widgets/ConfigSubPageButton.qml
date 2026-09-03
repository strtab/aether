import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

// A plain, single row-button. Pressing it hands its component up to
// SettingsNav, which settings.qml is listening to.
//
// Usage inside any regular page:
//   SubPageButton {
//     Layout.fillWidth: true
//     text: Translation.tr("Typography")
//     description: Translation.tr("Typography and general options")
//     icon: "text_fields"
//     targetComponent: typographySubPage
//   }
//   Component { id: typographySubPage; ColumnLayout { ... } }
RippleButton {
  id: root

  property string description: ""
  property Component targetComponent: null

  implicitHeight: 50
  colBackgroundHover: Appearance.colors.colLayer2Hover

  onPressed: SettingsNav.open(root.text, root.targetComponent)

  contentItem: RowLayout {
    spacing: 12

    ColumnLayout {
      Layout.fillWidth: true
      spacing: 0

      StyledText {
        Layout.fillWidth: true
        color: Appearance.colors.colOnLayer1
        text: root.text
      }
      StyledText {
        Layout.fillWidth: true
        visible: root.description.length > 0
        color: Appearance.colors.colSubtext
        font.pixelSize: Appearance.font.pixelSize.small
        text: root.description
        wrapMode: Text.WordWrap
      }
    }

    MaterialSymbol {
      color: Appearance.colors.colSubtext
      iconSize: Appearance.font.pixelSize.large
      text: "chevron_right"
    }
  }
}
