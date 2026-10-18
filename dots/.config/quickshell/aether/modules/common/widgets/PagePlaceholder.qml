import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

Item {
    id: root

    property bool shown: true
    property alias icon: shapeWidget.text
    property alias title: widgetNameText.text
    property alias description: widgetDescriptionText.text
    property alias shape: shapeWidget.shape
    property alias descriptionHorizontalAlignment: widgetDescriptionText.horizontalAlignment

    opacity: shown ? 1 : 0
    visible: opacity > 0
    anchors {
        fill: parent
        topMargin: -30 * (1 - opacity)
        bottomMargin: 30 * (1 - opacity)
    }

    Behavior on opacity {
        animation: Appearance.animation.elementMoveEnter.numberAnimation.createObject(this)
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 5

        MaterialShapeWrappedMaterialSymbol {
            id: shapeWidget
            Layout.alignment: Qt.AlignHCenter
            padding: 12
            iconSize: 56
            rotation: -30 * (1 - root.opacity)
        }
        StyledText {
            id: widgetNameText
            style: Appearance.font.style.title2
            visible: title !== ""
            Layout.alignment: Qt.AlignHCenter
            color: Appearance.m3colors.m3outline
            horizontalAlignment: Text.AlignHCenter
        }
        StyledText {
            id: widgetDescriptionText
            style: Appearance.font.style.callout
            visible: description !== ""
            Layout.fillWidth: true
            color: Appearance.m3colors.m3outline
            horizontalAlignment: Text.AlignLeft
            wrapMode: Text.Wrap
        }
    }
}
