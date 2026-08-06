import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

/**
 * Aether checkbox: a rounded-square glass box that fills with ink and
 * shows a check glyph when checked. Companion to StyledRadioButton, for
 * lists where individually toggleable (rather than mutually exclusive)
 * options are needed.
 */
CheckBox {
    id: root
    padding: 4
    implicitHeight: contentItem.implicitHeight + padding * 2
    property string description
    property color checkedColor: Appearance?.colors.colPrimary ?? "#1d1d1f"
    property color checkedOnColor: Appearance?.colors.colOnPrimary ?? "#f5f5f7"

    PointingHandInteraction {}

    indicator: Item {}

    contentItem: RowLayout {
        id: contentItem
        Layout.fillWidth: true
        spacing: 12

        Rectangle {
            id: box
            Layout.alignment: Qt.AlignVCenter
            width: 22
            height: 22
            radius: Appearance?.rounding.unsharpenmore ?? 6
            color: root.checked ? root.checkedColor : (Appearance?.colors.colGlassStrong ?? "transparent")
            border.width: 1
            border.color: root.checked ? "transparent" : (Appearance?.colors.colHairline ?? "transparent")

            Behavior on color {
                animation: Appearance?.animation.elementMoveFast.colorAnimation.createObject(this)
            }
            Behavior on border.color {
                animation: Appearance?.animation.elementMoveFast.colorAnimation.createObject(this)
            }

            MaterialSymbol {
                anchors.centerIn: parent
                text: "check"
                iconSize: 14
                color: root.checkedOnColor
                opacity: root.checked ? 1 : 0
                scale: root.checked ? 1 : 0.5

                Behavior on opacity {
                    animation: Appearance?.animation.elementMoveFast.numberAnimation.createObject(this)
                }
                Behavior on scale {
                    animation: Appearance?.animation.clickBounce.numberAnimation.createObject(this)
                }
            }
        }

        StyledText {
            text: root.description
            Layout.alignment: Qt.AlignVCenter
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            color: Appearance?.m3colors.m3onSurface
        }
    }
}
