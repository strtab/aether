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

  component SmallLightDarkPreferenceButton: RippleButton {
    id: smallLightDarkPreferenceButton
    required property bool dark
    property color colText: toggled ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer2
    padding: 5
    Layout.fillWidth: true
    toggled: Appearance.m3colors.darkmode === dark
    colBackground: Appearance.colors.colLayer2
    onClicked: {
      Quickshell.execDetached(["bash", "-c", `${Directories.wallpaperSwitchScriptPath} --mode ${dark ? "dark" : "light"} --noswitch`]);
    }
    contentItem: Item {
      anchors.centerIn: parent
      ColumnLayout {
        anchors.centerIn: parent
        spacing: 0
        MaterialSymbol {
          Layout.alignment: Qt.AlignHCenter
          text: dark ? "dark_mode" : "light_mode"
          color: smallLightDarkPreferenceButton.colText
        }
        StyledText {
          Layout.alignment: Qt.AlignHCenter
          text: dark ? Translation.tr("Dark") : Translation.tr("Light")
          font.pixelSize: Appearance.font.pixelSize.smaller
          color: smallLightDarkPreferenceButton.colText
        }
      }
    }
  }

  // Wallpaper selection
  ContentSection {
    title: Translation.tr("Wallpaper & Colors")
    Layout.fillWidth: true

    RowLayout {
      Layout.fillWidth: true

      Item {
        implicitWidth: 300
        implicitHeight: 180

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
              width: 360
              height: 200
              radius: Appearance.rounding.normal
            }
          }
        }
      }

      ColumnLayout {
        RippleButtonWithIcon {
          Layout.fillWidth: true
          materialIcon: "wallpaper"
          mainText: Translation.tr("Choose file")
          onClicked: {
            Quickshell.execDetached(["bash", "-c", `${Directories.wallpaperSwitchScriptPath}`]);
          }
          StyledToolTip {
            text: Translation.tr("Pick wallpaper image on your system")
          }
        }
        RowLayout {
          Layout.alignment: Qt.AlignHCenter
          Layout.fillWidth: true
          Layout.fillHeight: true
          uniformCellSizes: true

          SmallLightDarkPreferenceButton {
            Layout.fillHeight: true
            dark: false
          }
          SmallLightDarkPreferenceButton {
            Layout.fillHeight: true
            dark: true
          }
        }
        RowLayout {
          Layout.fillWidth: true
          spacing: 8

          Input {
            Layout.fillWidth: true
            placeholderText: Translation.tr("Accent Color")
            text: Config.options.appearance.palette.accentColor
            wrapMode: TextEdit.Wrap
            onTextChanged: {
              Config.options.appearance.palette.accentColor = text;
              debounceTimer.restart();
            }
            Timer {
              id: debounceTimer
              interval: 600
              repeat: false
              onTriggered: {
                const color = parent.text.trim();
                const isValidHex = /^#[0-9A-Fa-f]{6}$/.test(color);
                if (!isValidHex)
                  return;
                Config.options.appearance.palette.accentColor = parent.text;
                Quickshell.execDetached([Directories.wallpaperSwitchScriptPath, "--noswitch", "--color", color]);
              }
            }
          }

          ToolbarPairedFab {
            onClicked: {
              Quickshell.execDetached([Directories.wallpaperSwitchScriptPath, "--noswitch", "--color"]);
            }
          }
        }
      }
    }

    ConfigComboBox {
      title: Translation.tr("Palette")
      description: Translation.tr("Select the color palette to use for the system.")
      textRole: "displayName"
      model: [
        {
          "value": "auto",
          "displayName": Translation.tr("Auto")
        },
        {
          "value": "scheme-content",
          "displayName": Translation.tr("Content")
        },
        {
          "value": "scheme-expressive",
          "displayName": Translation.tr("Expressive")
        },
        {
          "value": "scheme-fidelity",
          "displayName": Translation.tr("Fidelity")
        },
        {
          "value": "scheme-fruit-salad",
          "displayName": Translation.tr("Fruit Salad")
        },
        {
          "value": "scheme-monochrome",
          "displayName": Translation.tr("Monochrome")
        },
        {
          "value": "scheme-neutral",
          "displayName": Translation.tr("Neutral")
        },
        {
          "value": "scheme-rainbow",
          "displayName": Translation.tr("Rainbow")
        },
        {
          "value": "scheme-tonal-spot",
          "displayName": Translation.tr("Tonal Spot")
        }
      ]
      value: Config.options.appearance.palette.type
      onSelected: newValue => {
        Config.options.appearance.palette.type = newValue;
        Quickshell.execDetached(["bash", "-c", `${Directories.wallpaperSwitchScriptPath} --noswitch`]);
      }
    }

    ConfigSwitch {
      text: Translation.tr("Transparency")
      checked: Config.options.appearance.transparency.enable
      onCheckedChanged: {
        Config.options.appearance.transparency.enable = checked;
      }
    }
  }

  NoticeBox {
    Layout.fillWidth: true
    text: Translation.tr('Not all options are available in this app. You should also check the config file by hitting the "Config file" button on the topleft corner or opening %1 manually.').arg(Directories.shellConfigPath)

    Item {
      Layout.fillWidth: true
    }
    RippleButtonWithIcon {
      id: copyPathButton
      property bool justCopied: false
      Layout.fillWidth: false
      buttonRadius: Appearance.rounding.small
      materialIcon: justCopied ? "check" : "content_copy"
      mainText: justCopied ? Translation.tr("Path copied") : Translation.tr("Copy path")
      onClicked: {
        copyPathButton.justCopied = true;
        Quickshell.clipboardText = FileUtils.trimFileProtocol(`${Directories.config}/aether/config.json`);
        revertTextTimer.restart();
      }
      colBackground: ColorUtils.transparentize(Appearance.colors.colPrimaryContainer)
      colBackgroundHover: Appearance.colors.colPrimaryContainerHover
      colRipple: Appearance.colors.colPrimaryContainerActive

      Timer {
        id: revertTextTimer
        interval: 1500
        onTriggered: {
          copyPathButton.justCopied = false;
        }
      }
    }
  }
}
