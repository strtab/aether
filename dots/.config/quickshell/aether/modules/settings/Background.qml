import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

ContentPage {
  forceWidth: true

  // Wallpaper selection
  ContentSection {
    title: Translation.tr("Wallpaper & Colors")
    Layout.fillWidth: true

    RowLayout {
      Layout.fillWidth: true

      Item {
        implicitWidth: 260
        implicitHeight: 160

        StyledImage {
          id: wallpaperPreview
          anchors.fill: parent
          sourceSize.width: parent.implicitWidth
          sourceSize.height: parent.implicitHeight
          fillMode: Image.PreserveAspectCrop
          source: Config.options.background.wallpaperPath
          cache: false
          layer.enabled: true
          layer.effect: OpacityMask {
            maskSource: Rectangle {
              width: 320
              height: 180
              radius: Appearance.rounding.normal
            }
          }
        }
      }

      ColumnLayout {
        Layout.leftMargin: 8
        StyledText {
          id: wallpaperName
          Layout.fillWidth: true
          // height: parent.height

          Layout.margins: 8
          style: Appearance.font.style.callout
          text: {
            const path = Config.options.background.wallpaperPath;
            if (!path)
              return "";
            const fileName = path.split("/").pop();
            const lastDot = fileName.lastIndexOf(".");
            return (lastDot > 0 ? fileName.substring(0, lastDot) : fileName).replace(/_/g, " ");
          }
        }
        Rectangle { // Separator
          visible: root.showResults

          Layout.fillWidth: true
          Layout.alignment: Qt.AlignHCenter

          height: 1
          color: Appearance.colors.colOutlineVariant
        }
        RippleButton {
          Layout.fillWidth: true
          buttonText: Translation.tr("Choose file")
          onClicked: {
            Quickshell.execDetached(["bash", "-c", `${Directories.wallpaperSwitchScriptPath}`]);
          }
        }
      }
    }
  }

  ContentSection {
    title: Translation.tr("General")
    ConfigSwitch {
      title: Translation.tr("Enable")
      checked: Config.options.background.enable
      onCheckedChanged: {
        Config.options.background.enable = checked;
      }
    }
  }

  ContentSection {
    title: Translation.tr("Parallax")

    ConfigSwitch {
      title: Translation.tr("Vertical")
      checked: Config.options.background.parallax.vertical
      onCheckedChanged: {
        Config.options.background.parallax.vertical = checked;
      }
    }

    ConfigSwitch {
      title: Translation.tr("Depends on workspace")
      checked: Config.options.background.parallax.enableWorkspace
      onCheckedChanged: {
        Config.options.background.parallax.enableWorkspace = checked;
      }
    }
    ConfigSwitch {
      title: Translation.tr("Depends on sidebars")
      checked: Config.options.background.parallax.enableSidebar
      onCheckedChanged: {
        Config.options.background.parallax.enableSidebar = checked;
      }
    }
    ConfigSpinBox {
      title: Translation.tr("Preferred wallpaper zoom (%)")
      value: Config.options.background.parallax.workspaceZoom * 100
      from: 100
      to: 150
      stepSize: 1
      onValueChanged: {
        Config.options.background.parallax.workspaceZoom = value / 100;
      }
    }
  }
}
