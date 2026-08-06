import QtQuick
import qs.modules.common

/**
 * Aether glass bevel overlay.
 *
 * Approximates the "inset highlight" of a glass pane: a hairline border
 * plus a soft light sheen that fades from the top edge downward, the way
 * CSS box-shadow: inset 1.5px 1.5px 0 0 <bevel-light> reads on a rounded
 * rectangle. Anchor it as a child on top of a background Rectangle that
 * shares the same radius, e.g.:
 *
 *   Rectangle {
 *     id: card
 *     radius: Appearance.rounding.large
 *     color: Appearance.colors.colSurfaceRaised
 *     GlassBevel { anchors.fill: parent; radius: card.radius }
 *   }
 */
Item {
    id: root
    property real radius: 0
    property real borderWidth: 1
    property color borderColor: Appearance.colors.colHairline
    property color sheenColor: Appearance.colors.colBevelLight
    property real sheenOpacity: 0.5
    property real sheenStop: 0.45
    anchors.fill: parent

    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: "transparent"
        border.width: root.borderWidth
        border.color: root.borderColor
    }

    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: "transparent"
        opacity: root.sheenOpacity
        gradient: Gradient {
            GradientStop { position: 0.0; color: root.sheenColor }
            GradientStop { position: root.sheenStop; color: "transparent" }
        }
    }
}
