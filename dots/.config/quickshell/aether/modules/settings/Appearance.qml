import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

// Example: modules/settings/Appearance.qml as a list of buttons that each
// open a subpage with a back button, instead of one long scrolling page.
ContentPage {
  forceWidth: true

  ContentSection {
    ConfigComboBox {
      title: Translation.tr("Appearance")
      description: Translation.tr("Choose between light and dark mode")
      textRole: "displayName"
      model: [
        {
          displayName: Translation.tr("Dark"),
          value: "dark"
        },
        {
          displayName: Translation.tr("Light"),
          value: "light"
        }
      ]
      value: Appearance.m3colors.darkmode ? "dark" : "light"
      onSelected: newValue => Quickshell.execDetached(["bash", "-c", `${Directories.wallpaperSwitchScriptPath} --mode ${newValue} --noswitch`])
    }

    ConfigSwitch {
      title: Translation.tr("Transparency")
      checked: Config.options.appearance.transparency.enable
      onCheckedChanged: {
        Config.options.appearance.transparency.enable = checked;
      }
    }

    RowLayout {
      Layout.fillWidth: true
      spacing: 8

      ConfigInput {
        id: accentColorInput
        title: Translation.tr("Accent Color")
        description: Translation.tr("")
        placeholderText: Translation.tr("Example: #000000")
        text: Config.options.appearance.palette.accentColor
        inputWidth: 200
        onFocusChanged: {
          debounceTimer.restart();
        }
        onTextChanged: {
          Config.options.appearance.palette.accentColor = text;
          debounceTimer.restart();
        }
        RippleButtonWithIcon {
          onClicked: {
            Quickshell.execDetached([Directories.wallpaperSwitchScriptPath, "--noswitch", "--color"]);
          }
          contentItem: MaterialSymbol {
            anchors.centerIn: parent
            color: Appearance.colors.colOnLayer1
            iconSize: Appearance.font.pixelSize.normal
            text: "colorize"
          }
        }

        Timer {
          id: debounceTimer
          interval: 600
          repeat: false
          onTriggered: {
            const color = accentColorInput.text.trim();
            const isValidHex = /^#[0-9A-Fa-f]{6}$/.test(color);
            if (!isValidHex)
              return;
            Config.options.appearance.palette.accentColor = accentColorInput.text;
            Quickshell.execDetached([Directories.wallpaperSwitchScriptPath, "--noswitch", "--color", Config.options.appearance.palette.accentColor]);
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

    ConfigSubPageButton {
      Layout.fillWidth: true
      text: Translation.tr("Typography")
      description: Translation.tr("Customize the fonts")
      targetComponent: typographySubPage
    }
  }

  Component {
    id: typographySubPage
    ContentPage {
      forceWidth: true

      ColumnLayout {
        ContentSection {

          ContentSubsection {
            title: Translation.tr("Main font")
            description: Translation.tr("Used for general UI text")

            FontSelector {
              id: mainFontSelector
              selectedFont: Config.options?.appearance?.typography?.main ?? "Roboto Flex"
              onSelectedFontChanged: {
                if (Config.options?.appearance?.typography)
                  Config.setNestedValue("appearance.typography.main", selectedFont);
              }
              Connections {
                target: Config.options?.appearance?.typography ?? null
                function onMainFontChanged() {
                  mainFontSelector.selectedFont = Config.options.appearance.typography.main;
                }
              }
            }
          }

          ContentSubsection {
            title: Translation.tr("Numbers font")
            description: Translation.tr("Used for displaying numbers")

            FontSelector {
              id: numbersFontSelector
              selectedFont: Config.options?.appearance?.typography?.numbers ?? "Roboto Flex"
              onSelectedFontChanged: {
                if (Config.options?.appearance?.typography)
                  Config.setNestedValue("appearance.typography.numbers", selectedFont);
              }
              Connections {
                target: Config.options?.appearance?.typography ?? null
                function onMainFontChanged() {
                  numbersFontSelector.selectedFont = Config.options.appearance.typography.numbers;
                }
              }
            }
          }

          ContentSubsection {
            title: Translation.tr("Title font")
            description: Translation.tr("Used for headings and titles")

            FontSelector {
              id: titleFontSelector
              selectedFont: Config.options?.appearance?.typography?.title ?? "Roboto Flex"
              onSelectedFontChanged: {
                if (Config.options?.appearance?.typography)
                  Config.setNestedValue("appearance.typography.title", selectedFont);
              }
              Connections {
                target: Config.options?.appearance?.typography ?? null
                function onMainFontChanged() {
                  titleFontSelector.selectedFont = Config.options.appearance.typography.title;
                }
              }
            }
          }

          ContentSubsection {
            title: Translation.tr("Monospace font")
            description: Translation.tr("Used for code and terminal")

            FontSelector {
              id: monospaceFontSelector
              selectedFont: Config.options?.appearance?.typography?.monospace ?? "JetBrains Mono NF"
              onSelectedFontChanged: {
                if (Config.options?.appearance?.typography)
                  Config.setNestedValue("appearance.typography.monospace", selectedFont);
              }
              Connections {
                target: Config.options?.appearance?.monospace ?? null
                function onMainFontChanged() {
                  monospaceFontSelector.selectedFont = Config.options.appearance.typography.monospace;
                }
              }
            }
          }

          ContentSubsection {
            title: Translation.tr("Nerd font icons")
            description: Translation.tr("Font used for Nerd Font icons")

            FontSelector {
              id: nerdFontSelector
              selectedFont: Config.options?.appearance?.typography?.iconNerd ?? "JetBrains Mono NF"
              onSelectedFontChanged: {
                if (Config.options?.appearance?.typography)
                  Config.setNestedValue("appearance.typography.iconNerd", selectedFont);
              }
              Connections {
                target: Config.options?.appearance?.iconNerd ?? null
                function onMainFontChanged() {
                  nerdFontSelector.selectedFont = Config.options.appearance.typography.iconNerd;
                }
              }
            }
          }

          ContentSubsection {
            title: Translation.tr("Reading font")
            description: Translation.tr("Used for reading large blocks of text")

            FontSelector {
              id: readingFontSelector
              selectedFont: Config.options?.appearance?.typography?.reading ?? "Readex Pro"
              onSelectedFontChanged: {
                if (Config.options?.appearance?.typography)
                  Config.setNestedValue("appearance.typography.reading", selectedFont);
              }
              Connections {
                target: Config.options?.appearance?.reading ?? null
                function onMainFontChanged() {
                  readingFontSelector.selectedFont = Config.options.appearance.typography.reading;
                }
              }
            }
          }

          ContentSubsection {
            title: Translation.tr("Expressive font")
            description: Translation.tr("Used for decorative/expressive text")

            FontSelector {
              id: expressiveFontSelector
              selectedFont: Config.options?.appearance?.typography?.expressive ?? "Google Sans 17pt"
              onSelectedFontChanged: {
                if (Config.options?.appearance?.typography)
                  Config.setNestedValue("appearance.typography.expressive", selectedFont);
              }
              Connections {
                target: Config.options?.appearance?.expressive ?? null
                function onMainFontChanged() {
                  expressiveFontSelector.selectedFont = Config.options.appearance.typography.expressive;
                }
              }
            }
          }
        }
      }
    }
  }
}
