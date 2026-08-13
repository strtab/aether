import qs.modules.common.widgets
import qs.modules.common
import QtQuick
import QtQuick.Layouts

ContentSubsection {
  id: root

  property string text: ""
  property string placeholderText: ""

  opacity: root.enabled ? 1 : 0.4

  Input {
    wrapMode: TextEdit.Wrap
    Layout.fillWidth: root.title.visible & root.description.visible ? false : true
    text: root.text
    placeholderText: root.placeholderText
    opacity: root.enabled ? 1 : 0.4
  }
}
