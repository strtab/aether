import qs.modules.common.widgets
import qs.modules.common
import QtQuick
import QtQuick.Layouts

ContentSubsection {
  id: root
  property alias value: spinBoxWidget.value
  property alias stepSize: spinBoxWidget.stepSize
  property alias from: spinBoxWidget.from
  property alias to: spinBoxWidget.to
  spacing: 10
  Layout.margins: 8
  Layout.bottomMargin: 10
  Layout.topMargin: 10

  StyledSpinBox {
    id: spinBoxWidget
    Layout.fillWidth: false
    value: root.value
  }
}
