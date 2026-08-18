import qs.modules.common.widgets
import qs.modules.common
import QtQuick
import QtQuick.Layouts

ContentSubsection {
  id: root

  property alias text: input.text
  property alias placeholderText: input.placeholderText
  property int inputWidth: 200

  opacity: root.enabled ? 1 : 0.4

  // Redeclaring default property here overrides the one inherited from
  // ContentSubsection. Any child written inside "ConfigInput { ... }" by
  // the caller now goes into extraContent instead of being appended after Input.
  default property alias extraContent: extraContainer.data

  ColumnLayout {
    id: extraContainer
    Layout.fillWidth: true
    // caller's items land here, rendered before Input
  }

  Input {
    id: input
    Layout.fillHeight: false
    implicitWidth: root.inputWidth
    implicitHeight: 35
    opacity: root.enabled ? 1 : 0.4
  }
}
