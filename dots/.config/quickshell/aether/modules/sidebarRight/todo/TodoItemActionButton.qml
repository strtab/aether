import qs.modules.common
import qs.modules.common.widgets
import QtQuick

RippleButton {
    id: button
    property string buttonText: ""
    property string tooltipText: ""

    implicitHeight: 30
    implicitWidth: implicitHeight

    Behavior on implicitWidth {
        SmoothedAnimation {
            velocity: Appearance.animation.elementMove.velocity
        }
    }

    buttonRadius: Appearance.rounding.small

    contentItem: StyledText {
        style: Appearance.font.style.title2
        text: buttonText
        horizontalAlignment: Text.AlignHCenter
        color: Appearance.colors.colOnLayer1
    }

    StyledToolTip {
        text: tooltipText
        extraVisibleCondition: tooltipText.length > 0
    }
}