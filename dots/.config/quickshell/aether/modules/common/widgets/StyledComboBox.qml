pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

ComboBox {
  id: root

  property string buttonIcon: ""
  property int itemHeight: 30
  property real buttonRadius: Appearance.rounding.verysmall
  property color colBackground: Appearance?.m3colors.m3surfaceContainerHighest
  property color colBackgroundHover: Appearance.m3colors.m3surfaceBright
  property color colBackgroundActive: Appearance.colors.colSecondaryContainerActive
  // Border color for the compact "input field" look from the screenshot
  property color colBorder: Appearance.colors.colOutlineVariant ?? Appearance.colors.colOnLayer3

  // Compact by default instead of stretching to fill the row.
  // Content-driven width, capped by minimumWidth/maximumWidth if set by the parent.
  implicitWidth: Math.max(contentLayout.implicitWidth + leftPadding + rightPadding, 160)
  implicitHeight: root.itemHeight
  Layout.fillWidth: false

  leftPadding: 12
  rightPadding: 12

  background: Rectangle {
    radius: root.buttonRadius
    color: (root.down && !root.popup.visible) ? root.colBackgroundActive : root.hovered ? root.colBackgroundHover : root.colBackground
    border.width: 1
    border.color: root.colBorder

    Behavior on color {
      animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
    }

    MouseArea {
      anchors.fill: parent
      acceptedButtons: Qt.NoButton
      cursorShape: Qt.PointingHandCursor
    }
  }

  indicator: MaterialSymbol {
    x: root.width - width - 10
    y: root.height / 2 - height / 2
    text: "unfold_more"
    iconSize: Appearance.font.pixelSize.large
    color: Appearance.colors.colOnSecondaryContainer
  }

  contentItem: Item {
    implicitWidth: contentLayout.implicitWidth
    implicitHeight: contentLayout.implicitHeight

    RowLayout {
      id: contentLayout
      anchors.fill: parent
      Layout.alignment: Qt.AlignVCenter
      spacing: 4

      StyledText {
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignVCenter
        color: Appearance.colors.colOnSecondaryContainer
        text: root.displayText
        elide: Text.ElideRight
        verticalAlignment: Text.AlignVCenter
      }
    }
  }

  delegate: ItemDelegate {
    id: itemDelegate
    width: ListView.view ? ListView.view.width : root.width
    implicitHeight: root.itemHeight

    required property var model
    required property int index
    property color color: {
      if (itemDelegate.down)
        return Appearance.colors.colLayer3Active;
      if (itemDelegate.hovered)
        return Appearance.colors.colLayer3Hover;
      return ColorUtils.transparentize(Appearance.colors.colLayer3);
    }
    property color colText: (root.currentIndex === itemDelegate.index) ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnLayer3

    background: Rectangle {
      anchors.fill: parent
      radius: Appearance.rounding.verysmall
      color: itemDelegate.color

      Behavior on color {
        animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
      }

      MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        cursorShape: Qt.PointingHandCursor
      }
    }

    // anchors.fill: parent makes the leftMargin/rightMargin below actually apply;
    // without an active anchor, margin properties are no-ops.
    contentItem: RowLayout {
      anchors.fill: parent
      anchors.leftMargin: 8
      anchors.rightMargin: 6
      spacing: 8

      Loader {
        Layout.alignment: Qt.AlignVCenter
        Layout.preferredHeight: Appearance.font.pixelSize.larger
        active: typeof itemDelegate.model === 'object' && itemDelegate.model?.icon?.length > 0
        visible: active

        sourceComponent: Item {
          implicitWidth: icon.implicitWidth
          implicitHeight: Appearance.font.pixelSize.larger

          MaterialSymbol {
            id: icon
            anchors.centerIn: parent
            text: itemDelegate.model?.icon ?? ""
            iconSize: Appearance.font.pixelSize.larger
            color: itemDelegate.colText
          }
        }
      }

      StyledText {
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignVCenter
        color: itemDelegate.colText
        text: itemDelegate.model[root.textRole]
        elide: Text.ElideRight
        verticalAlignment: Text.AlignVCenter
      }
      MaterialSymbol {
        visible: root.currentIndex === itemDelegate.index
        text: "check"
        iconSize: Appearance.font.pixelSize.large
        color: Appearance.colors.colOnSecondaryContainer
      }
    }
  }

  popup: Popup {
    y: root.height + 4
    width: root.width
    height: Math.min(listView.contentHeight + topPadding + bottomPadding, 300)
    padding: 6

    enter: Transition {
      PropertyAnimation {
        properties: "opacity"
        to: 1
        duration: Appearance.animation.elementMoveFast.duration
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
      }
    }

    exit: Transition {
      PropertyAnimation {
        properties: "opacity"
        to: 0
        duration: Appearance.animation.elementMoveFast.duration
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
      }
    }

    background: Item {
      StyledRectangularShadow {
        target: popupBackground
      }

      Rectangle {
        id: popupBackground
        anchors.fill: parent
        radius: Appearance.rounding.small
        color: Appearance.m3colors.m3surfaceContainerHigh
        border.width: 1
        border.color: root.colBorder
      }
    }

    contentItem: StyledListView {
      id: listView
      clip: true
      implicitHeight: contentHeight
      spacing: 2
      model: root.popup.visible ? root.delegateModel : null
      currentIndex: root.highlightedIndex
    }
  }
}
