//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.modules.common
import qs.modules.common.widgets

ApplicationWindow {
  id: root

  visible: true
  title: "Appearance Color Palette"
  width: 1100
  height: 800
  color: Appearance.m3colors.m3background

  // Collect the names of all "color" typed properties on a QtObject.
  // QML meta-object properties are enumerable via for-in on the JS wrapper,
  // so this stays in sync automatically if Appearance gains/loses colors.
  function colorPropertyNames(obj) {
    const names = [];
    for (const key in obj) {
      const value = obj[key];
      // QColor values come through as JS objects exposing r/g/b/a (0..1).
      if (value !== null && typeof value === "object" && value.r !== undefined && value.g !== undefined && value.b !== undefined) {
        names.push(key);
      }
    }
    names.sort();
    return names;
  }

  // Simple relative-luminance check to pick a readable label color per swatch.
  function readableTextColor(bg) {
    const luminance = 0.2126 * bg.r + 0.7152 * bg.g + 0.0722 * bg.b;
    return luminance > 0.5 ? "#000000" : "#ffffff";
  }

  readonly property var m3ColorNames: colorPropertyNames(Appearance.m3colors)
  readonly property var semanticColorNames: colorPropertyNames(Appearance.colors)

  component ColorSwatch: Rectangle {
    id: swatch
    required property string swatchName
    required property color swatchColor

    implicitWidth: 300
    implicitHeight: 100
    radius: Appearance.rounding.verysmall
    color: swatch.swatchColor
    border.width: 1
    border.color: Qt.rgba(0, 0, 0, 0.25)

    StyledText {
      anchors.centerIn: parent
      width: parent.width - 12
      horizontalAlignment: Text.AlignHCenter
      wrapMode: Text.WordWrap
      font.pixelSize: Appearance.font.pixelSize.normal
      color: root.readableTextColor(swatch.swatchColor)
      text: swatch.swatchName
    }
  }

  component PaletteSection: ColumnLayout {
    id: section
    required property string sectionTitle
    required property var names
    required property QtObject sourceObject

    Layout.fillWidth: true
    spacing: 10

    StyledText {
      text: section.sectionTitle
      font.bold: true
      font.pixelSize: Appearance.font.pixelSize.larger
      color: Appearance.colors.colOnLayer1
    }

    Flow {
      Layout.fillWidth: true
      spacing: 8

      Repeater {
        model: section.names
        delegate: ColorSwatch {
          required property string modelData
          swatchName: modelData
          swatchColor: section.sourceObject[modelData]
        }
      }
    }
  }

  ScrollView {
    anchors.fill: parent
    clip: true

    ColumnLayout {
      width: root.width
      spacing: 24

      Item {
        Layout.preferredHeight: 10
      }

      PaletteSection {
        Layout.fillWidth: true
        Layout.leftMargin: 20
        Layout.rightMargin: 20
        sectionTitle: "m3colors (" + root.m3ColorNames.length + ")"
        names: root.m3ColorNames
        sourceObject: Appearance.m3colors
      }

      PaletteSection {
        Layout.fillWidth: true
        Layout.leftMargin: 20
        Layout.rightMargin: 20
        sectionTitle: "colors (" + root.semanticColorNames.length + ")"
        names: root.semanticColorNames
        sourceObject: Appearance.colors
      }

      Item {
        Layout.preferredHeight: 20
      }
    }
  }
}
