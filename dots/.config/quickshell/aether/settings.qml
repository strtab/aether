//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000

// Adjust this to make the app smaller or larger
//@ pragma Env QT_SCALE_FACTOR=1

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions as CF

ApplicationWindow {
  id: root
  property real contentPadding: 8
  property var pages: [
    {
      name: Translation.tr("General"),
      icon: "settings",
      component: "modules/settings/General.qml"
    },
    {
      name: Translation.tr("Appearance"),
      icon: "invert_colors",
      component: "modules/settings/Appearance.qml"
    },
    {
      name: Translation.tr("Menu Bar"),
      icon: "menu",
      component: "modules/settings/MenuBar.qml"
    },
    {
      name: Translation.tr("Desktop & Dock"),
      icon: "toast",
      component: "modules/settings/Desktop.qml"
    },
    {
      name: Translation.tr("Background"),
      icon: "texture",
      component: "modules/settings/Background.qml"
    },
    {
      name: Translation.tr("Interface"),
      icon: "bottom_app_bar",
      component: "modules/settings/Interface.qml"
    },
    {
      name: Translation.tr("Search"),
      icon: "search",
      component: "modules/settings/Search.qml"
    },
    {
      name: Translation.tr("Hyprland"),
      icon: "select_window_2",
      component: "modules/settings/Hyprland.qml"
    },
    {
      name: Translation.tr("Services"),
      icon: "settings",
      component: "modules/settings/Services.qml"
    }
  ]
  property int currentPage: 0

  visible: true
  onClosing: Qt.quit()
  title: "aether Settings"

  Component.onCompleted: {
    MaterialThemeLoader.reapplyTheme();
    Config.readWriteDelay = 0; // Settings app always only sets one var at a time so delay isn't needed
  }

  maximumWidth: 1100
  minimumWidth: 900
  maximumHeight: 900
  minimumHeight: 600
  height: 800
  color: Appearance.m3colors.m3background

  ColumnLayout {
    anchors.fill: parent

    RowLayout { // Window content with sidebar and content pane
      spacing: 0
      Layout.fillWidth: true
      Layout.fillHeight: true

      Rectangle { // sideBar background
        Layout.fillHeight: true

        border.width: 1
        border.color: Appearance.colors.colLayer0Border

        implicitWidth: sideBar.implicitWidth
        implicitHeight: sideBar.implicitHeight

        color: Appearance.colors.colLayer1

        ColumnLayout {
          id: sideBar
          anchors.fill: parent
          Layout.margins: 15

          StyledText {
            Layout.margins: 25
            Layout.topMargin: 30
            Layout.bottomMargin: 0
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: Appearance.colors.colSubtext
            text: Translation.tr("Options")
          }

          ListView {
            Layout.fillHeight: true
            Layout.margins: 4
            Layout.leftMargin: 10
            Layout.rightMargin: 10
            implicitWidth: 180
            clip: true
            model: root.pages
            delegate: RippleButton {
              id: sideBarButton
              required property var modelData
              required property var index

              anchors {
                left: parent.left
                right: parent.right
              }

              Layout.margins: 0

              rippleEnabled: false

              toggled: root.currentPage === index
              onPressed: {
                root.currentPage = index;
                SettingsNav.close(); // leaving the page, any open subpage no longer applies
              }

              colBackgroundHover: Appearance.colors.colLayer2Hover
              colBackgroundToggled: Appearance.colors.colSecondaryContainer
              colBackgroundToggledHover: Appearance.colors.colSecondaryContainerHover
              colRippleToggled: Appearance.colors.colSecondaryContainerActive

              contentItem: RowLayout {
                MaterialSymbol {
                  color: sideBarButton.toggled ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnLayer1
                  iconSize: Appearance.font.pixelSize.large
                  text: sideBarButton.modelData.icon
                  fill: sideBarButton.toggled ? 1 : 0
                }
                StyledText {
                  Layout.fillWidth: true
                  horizontalAlignment: Text.AlignLeft
                  color: sideBarButton.toggled ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnLayer1
                  text: sideBarButton.modelData.name
                }
              }
            }
          }
          Item { // filler
            Layout.fillHeight: true
          }
          StyledText {
            id: distroDescription

            Layout.margins: 20
            Layout.bottomMargin: 10
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: Appearance.colors.colSubtext

            Process {
              command: ["bash", "-c", "source /etc/os-release && echo $PRETTY_NAME"]
              running: true
              stdout: SplitParser {
                onRead: data => distroDescription.text = data.trim()
              }
            }
          }
        }
      }

      ColumnLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true

        Rectangle { // Header: back button appears only while a subpage is open
          Layout.fillWidth: true
          implicitHeight: SettingsNav.subPageOpen ? 60 : 0
          clip: true
          visible: opacity > 0
          opacity: SettingsNav.subPageOpen ? 1 : 0

          color: "transparent"

          // Same fade used by the content wrappers below, plus a height
          // reveal so the page underneath doesn't jump when the header
          // appears/disappears.
          Behavior on implicitHeight {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
          }
          Behavior on opacity {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
          }

          RowLayout {
            id: header
            anchors.fill: parent
            anchors.leftMargin: 50
            spacing: 10

            RippleButton {
              buttonRadius: Appearance.rounding.small
              colBackgroundHover: Appearance.colors.colLayer2Hover

              onPressed: SettingsNav.close()

              contentItem: MaterialSymbol {
                anchors.centerIn: parent
                color: Appearance.colors.colOnLayer1
                iconSize: Appearance.font.pixelSize.large
                text: "chevron_left"
              }
            }

            StyledText {
              Layout.fillWidth: true
              font.pixelSize: Appearance.font.pixelSize.large
              color: Appearance.colors.colOnLayer1
              text: SettingsNav.subPageOpen ? SettingsNav.subPageTitle : (root.pages[root.currentPage]?.name ?? "")
            }
          }
        }

        Rectangle { // Content container
          Layout.fillWidth: true
          Layout.fillHeight: true
          color: Appearance.m3colors.m3background

          // Regular page content, loaded from a file path as before.
          Item {
            id: mainContentWrapper
            anchors.fill: parent
            visible: opacity > 0
            opacity: SettingsNav.subPageOpen ? 0 : 1

            Behavior on opacity {
              animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
            }

            Loader {
              id: pageLoader
              anchors.fill: parent
              opacity: 1.0

              active: Config.ready
              Component.onCompleted: {
                source = root.pages[0].component;
              }

              Connections {
                target: root
                function onCurrentPageChanged() {
                  switchAnim.complete();
                  switchAnim.start();
                }
              }

              SequentialAnimation {
                id: switchAnim

                NumberAnimation {
                  target: pageLoader
                  properties: "opacity"
                  from: 1
                  to: 0
                  duration: 100
                  easing.type: Appearance.animation.elementMoveExit.type
                  easing.bezierCurve: Appearance.animationCurves.emphasizedFirstHalf
                }
                ParallelAnimation {
                  PropertyAction {
                    target: pageLoader
                    property: "source"
                    value: root.pages[root.currentPage].component
                  }
                }
                ParallelAnimation {
                  NumberAnimation {
                    target: pageLoader
                    properties: "opacity"
                    from: 0
                    to: 1
                    duration: 200
                    easing.type: Appearance.animation.elementMoveEnter.type
                    easing.bezierCurve: Appearance.animationCurves.emphasizedLastHalf
                  }
                }
              }
            }
          }

          // Subpage content, opened dynamically by ConfigSubPageButton.onPressed
          // (or any code) calling SettingsNav.open(title, component) from
          // inside whatever page is currently loaded above.
          Item {
            id: subPageWrapper
            anchors.fill: parent
            visible: opacity > 0
            opacity: SettingsNav.subPageOpen ? 1 : 0

            Behavior on opacity {
              animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
            }

            Loader {
              id: subPageLoader
              anchors.fill: parent
              opacity: 1.0

              active: SettingsNav.subPageOpen

              Connections {
                target: SettingsNav
                function onSubPageComponentChanged() {
                  if (!SettingsNav.subPageOpen)
                    return; // being closed, subPageWrapper's own fade handles this
                  subPageSwitchAnim.complete();
                  subPageSwitchAnim.start();
                }
              }

              SequentialAnimation {
                id: subPageSwitchAnim

                NumberAnimation {
                  target: subPageLoader
                  properties: "opacity"
                  from: 1
                  to: 0
                  duration: 100
                  easing.type: Appearance.animation.elementMoveExit.type
                  easing.bezierCurve: Appearance.animationCurves.emphasizedFirstHalf
                }
                ParallelAnimation {
                  PropertyAction {
                    target: subPageLoader
                    property: "sourceComponent"
                    value: SettingsNav.subPageComponent
                  }
                }
                ParallelAnimation {
                  NumberAnimation {
                    target: subPageLoader
                    properties: "opacity"
                    from: 0
                    to: 1
                    duration: 200
                    easing.type: Appearance.animation.elementMoveEnter.type
                    easing.bezierCurve: Appearance.animationCurves.emphasizedLastHalf
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
