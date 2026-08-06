pragma ComponentBehavior: Bound
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.services
import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell.Widgets

Slider {
  id: root

  property color trackColor: Appearance.colors.colSecondaryContainer
  property color highlightColor: Appearance.colors.colTertiaryHover
  property color handleColor: "#FFFFFF"
  property color dotColor: Appearance.m3colors.m3onSecondaryContainer
  property color dotColorHighlighted: Appearance.m3colors.m3onPrimary

  property real trackWidth: 6
  property real trackRadius: Appearance.rounding.full
  property real trackDotSize: 3
  property real trackDotBelowGap: 5

  property real handleHeight: 18
  property real handleWidth: 18

  property list<real> stopIndicatorValues: []

  property bool ticks: false
  property list<real> tickMarks: [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9]

  property bool usePercentTooltip: true
  property string tooltipContent: usePercentTooltip ? `${Math.round(((value - from) / (to - from)) * 100)}%` : `${Math.round(value)}`

  property bool icons: false
  property string leftIcon: ""
  property string rightIcon: ""
  readonly property bool showLeftIcon: leftIcon.length > 0 && icons
  readonly property bool showRightIcon: rightIcon.length > 0 && icons
  readonly property real leftIconSpace: (showLeftIcon) ? iconSize + iconGap : 0
  readonly property real rightIconSpace: (showRightIcon) ? iconSize + iconGap : 0
  property real iconSize: 20
  property real iconGap: 2

  property real effectiveDraggingWidth: Math.max(0, width - leftPadding - rightPadding)

  Layout.fillWidth: true
  from: 0
  to: 1
  implicitHeight: Math.max(handleHeight + 4, trackWidth + 8, iconSize + 4) * 1.5

  leftPadding: (handle.implicitWidth / 2) + leftIconSpace
  rightPadding: (handle.implicitWidth / 2) + rightIconSpace

  MouseArea {
    anchors.fill: parent
    z: 10
    onPressed: mouse => mouse.accepted = false
    cursorShape: root.pressed ? Qt.ClosedHandCursor : Qt.PointingHandCursor
  }

  SideIcon {
    isLeft: true
  }
  SideIcon {
    isLeft: false
  }

  background: Item {
    id: background
    anchors.verticalCenter: parent.verticalCenter
    width: root.width
    // Extra height so dots under the track are not clipped
    implicitHeight: Math.max(root.trackWidth, root.handleHeight, root.iconSize)

    // Inactive track (full width) — shifted up a bit when ticks sit below
    Rectangle {
      id: inactiveTrack
      x: root.leftPadding
      y: (parent.height - height) / 2
      width: root.effectiveDraggingWidth
      height: root.trackWidth
      radius: root.trackRadius
      color: root.trackColor
    }

    Rectangle {
      id: activeTrack
      x: root.leftPadding
      y: inactiveTrack.y
      width: Math.max(0, root.visualPosition * root.effectiveDraggingWidth)
      height: root.trackWidth
      radius: root.trackRadius
      color: root.highlightColor
    }

    Repeater {
      model: root.stopIndicatorValues
      Dot {
        required property real modelData
        value: modelData
      }
    }

    Repeater {
      model: root.tickMarks
      Rectangle {
        visible: root.ticks
        required property real modelData
        readonly property real normalizedValue: (modelData - root.from) / (root.to - root.from)
        x: root.leftPadding + normalizedValue * root.effectiveDraggingWidth - width / 2
        y: inactiveTrack.y + inactiveTrack.height + root.trackDotBelowGap
        width: 2
        height: 2
        color: root.trackColor
      }
    }
  }

  handle: Rectangle {
    id: handle

    implicitWidth: root.handleWidth
    implicitHeight: root.handleHeight
    anchors.verticalCenter: parent.verticalCenter
    x: root.leftPadding + (root.visualPosition * root.effectiveDraggingWidth) - (handle.implicitWidth / 2)
    radius: Appearance.rounding.normal
    color: root.handleColor

    layer.enabled: true
    layer.effect: MultiEffect {
      shadowEnabled: true
      shadowColor: Qt.rgba(0, 0, 0, 0.55)
      shadowVerticalOffset: 3
      shadowHorizontalOffset: 0
      shadowBlur: 0.55
    }

    Behavior on implicitWidth {
      animation: Appearance.animation.smooth.numberAnimation.createObject(this)
    }
    Behavior on width {
      animation: Appearance.animation.smooth.numberAnimation.createObject(this)
    }
    Behavior on x {
      animation: Appearance.animation.hover.numberAnimation.createObject(this)
    }
    StyledToolTip {
      extraVisibleCondition: root.pressed
      text: root.tooltipContent
      font {
        family: Appearance.font.family.numbers
        variableAxes: Appearance.font.variableAxes.numbers
      }
    }
  }

  component Dot: Rectangle {
    required property real value
    property real normalizedValue: (value - root.from) / (root.to - root.from)
    anchors.verticalCenter: parent.verticalCenter
    x: root.leftPadding + (normalizedValue * root.effectiveDraggingWidth) - (width / 2)
    y: inactiveTrack.y + (inactiveTrack.height - height) / 2
    width: root.trackDotSize
    height: root.trackDotSize
    color: normalizedValue > root.visualPosition ? root.dotColor : root.dotColorHighlighted
  }

  component SideIcon: MaterialSymbol {
    id: sideIcon
    required property bool isLeft
    visible: isLeft ? root.showLeftIcon : root.showRightIcon
    text: isLeft ? root.leftIcon : root.rightIcon
    iconSize: root.iconSize
    color: root.trackColor
    width: root.iconSize

    anchors.verticalCenter: parent.verticalCenter

    // Horizontal: sides outside track, or inset on track ends
    x: {
      if (isLeft)
        return 0;
      return root.width - width;
    }
  }
}
