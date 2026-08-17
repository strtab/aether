import QtQuick
import QtQuick.Layouts
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

    ConfigSubPageButton {
      Layout.fillWidth: true
      text: Translation.tr("Appearance")
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
