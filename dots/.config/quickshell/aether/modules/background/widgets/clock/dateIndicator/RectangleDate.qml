
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick

Rectangle {
    id: rect
    readonly property string dialStyle: Config.options.background.widgets.clock.cookie.dialNumberStyle

    StyledText {
        anchors.centerIn: parent
        font.pointSize: 20
        font.weight: 1000
        color: Appearance.colors.colSecondaryHover
        text: Qt.locale().toString(DateTime.clock.date, "dd")
    }
}
