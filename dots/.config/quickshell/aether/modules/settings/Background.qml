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
          font.pixelSize: Appearance.font.pixelSize.small
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

  ContentSection {
    id: settingsClock
    title: Translation.tr("Widget: Clock")

    function stylePresent(styleName) {
      if (!Config.options.background.widgets.clock.showOnlyWhenLocked && Config.options.background.widgets.clock.style === styleName) {
        return true;
      }
      if (Config.options.background.widgets.clock.styleLocked === styleName) {
        return true;
      }
      return false;
    }

    readonly property bool digitalPresent: stylePresent("digital")
    readonly property bool cookiePresent: stylePresent("cookie")

    ConfigSwitch {
      title: Translation.tr("Enable")
      checked: Config.options.background.widgets.clock.enable
      onCheckedChanged: {
        Config.options.background.widgets.clock.enable = checked;
      }
    }

    ConfigComboBox {
      title: Translation.tr("Placement")
      description: Translation.tr("Where the clock widget is positioned on the desktop")
      value: Config.options.background.widgets.clock.placementStrategy
      onSelected: newValue => {
        Config.options.background.widgets.clock.placementStrategy = newValue;
      }
      model: [
        {
          displayName: Translation.tr("Draggable"),
          value: "free"
        },
        {
          displayName: Translation.tr("Least busy"),
          value: "leastBusy"
        },
        {
          displayName: Translation.tr("Most busy"),
          value: "mostBusy"
        },
      ]
    }

    ConfigSwitch {
      title: Translation.tr("Show only when locked")
      checked: Config.options.background.widgets.clock.showOnlyWhenLocked
      onCheckedChanged: {
        Config.options.background.widgets.clock.showOnlyWhenLocked = checked;
      }
    }

    ConfigComboBox {
      visible: !Config.options.background.widgets.clock.showOnlyWhenLocked
      title: Translation.tr("Clock style")
      description: Translation.tr("The clock style shown while the screen is unlocked")
      value: Config.options.background.widgets.clock.style
      onSelected: newValue => {
        Config.options.background.widgets.clock.style = newValue;
      }
      model: [
        {
          displayName: Translation.tr("Digital"),
          value: "digital"
        },
        {
          displayName: Translation.tr("Cookie"),
          value: "cookie"
        }
      ]
    }

    ConfigComboBox {
      title: Translation.tr("Clock style (locked)")
      description: Translation.tr("The clock style shown on the lock screen")
      value: Config.options.background.widgets.clock.styleLocked
      onSelected: newValue => {
        Config.options.background.widgets.clock.styleLocked = newValue;
      }
      model: [
        {
          displayName: Translation.tr("Digital"),
          value: "digital"
        },
        {
          displayName: Translation.tr("Cookie"),
          value: "cookie"
        }
      ]
    }
    ConfigSwitch {
      title: Translation.tr("Enable quote")
      checked: Config.options.background.widgets.clock.quote.enable
      onCheckedChanged: {
        Config.options.background.widgets.clock.quote.enable = checked;
      }
    }
    ConfigInput {
      title: Translation.tr("Quote text")
      description: Translation.tr("This text will be showed under the clock")
      enabled: Config.options.background.widgets.clock.quote.enable
      placeholderText: Translation.tr("Quote")
      text: Config.options.background.widgets.clock.quote.text
      onTextChanged: {
        Config.options.background.widgets.clock.quote.text = text;
      }
    }
  }
  ContentSection {
    visible: settingsClock.digitalPresent
    title: Translation.tr("Digital clock settings")

    ConfigSwitch {
      title: Translation.tr("Vertical")
      checked: Config.options.background.widgets.clock.digital.vertical
      onCheckedChanged: {
        Config.options.background.widgets.clock.digital.vertical = checked;
      }
    }
    ConfigSwitch {
      title: Translation.tr("Animate time change")
      checked: Config.options.background.widgets.clock.digital.animateChange
      onCheckedChanged: {
        Config.options.background.widgets.clock.digital.animateChange = checked;
      }
    }

    ConfigSwitch {
      title: Translation.tr("Show date")
      checked: Config.options.background.widgets.clock.digital.showDate
      onCheckedChanged: {
        Config.options.background.widgets.clock.digital.showDate = checked;
      }
    }
    ConfigSwitch {
      title: Translation.tr("Use adaptive alignment")
      checked: Config.options.background.widgets.clock.digital.adaptiveAlignment
      onCheckedChanged: {
        Config.options.background.widgets.clock.digital.adaptiveAlignment = checked;
      }
      StyledToolTip {
        text: Translation.tr("Aligns the date and quote to left, center or right depending on its position on the screen.")
      }
    }

    ConfigInput {
      title: Translation.tr("Font family")
      description: Translation.tr("The font family used for the digital clock display")
      placeholderText: Translation.tr("Font family")
      text: Config.options.background.widgets.clock.digital.font.family
      onTextChanged: {
        Config.options.background.widgets.clock.digital.font.family = text;
      }
    }

    ConfigSlider {
      text: Translation.tr("Font weight")
      value: Config.options.background.widgets.clock.digital.font.weight
      usePercentTooltip: false
      from: 1
      to: 1000
      stopIndicatorValues: [350]
      onValueChanged: {
        Config.options.background.widgets.clock.digital.font.weight = value;
      }
    }

    ConfigSlider {
      text: Translation.tr("Font size")
      value: Config.options.background.widgets.clock.digital.font.size
      usePercentTooltip: false
      from: 70
      to: 150
      stopIndicatorValues: [90]
      onValueChanged: {
        Config.options.background.widgets.clock.digital.font.size = value;
      }
    }

    ConfigSlider {
      text: Translation.tr("Font width")
      value: Config.options.background.widgets.clock.digital.font.width
      usePercentTooltip: false
      from: 25
      to: 125
      stopIndicatorValues: [100]
      onValueChanged: {
        Config.options.background.widgets.clock.digital.font.width = value;
      }
    }
    ConfigSlider {
      text: Translation.tr("Font roundness")
      value: Config.options.background.widgets.clock.digital.font.roundness
      usePercentTooltip: false
      from: 0
      to: 100
      onValueChanged: {
        Config.options.background.widgets.clock.digital.font.roundness = value;
      }
    }
  }

  ContentSection {
    visible: settingsClock.cookiePresent
    title: Translation.tr("Cookie clock settings")

    ConfigSwitch {
      title: Translation.tr("Use old sine wave cookie implementation")
      checked: Config.options.background.widgets.clock.cookie.useSineCookie
      onCheckedChanged: {
        Config.options.background.widgets.clock.cookie.useSineCookie = checked;
      }
      StyledToolTip {
        text: "Looks a bit softer and more consistent with different number of sides,\nbut has less impressive morphing"
      }
    }

    ConfigSpinBox {
      title: Translation.tr("Sides")
      value: Config.options.background.widgets.clock.cookie.sides
      from: 0
      to: 40
      stepSize: 1
      onValueChanged: {
        Config.options.background.widgets.clock.cookie.sides = value;
      }
    }

    ConfigSwitch {
      title: Translation.tr("Constantly rotate")
      checked: Config.options.background.widgets.clock.cookie.constantlyRotate
      onCheckedChanged: {
        Config.options.background.widgets.clock.cookie.constantlyRotate = checked;
      }
      StyledToolTip {
        text: "Makes the clock always rotate. This is extremely expensive\n(expect 50% usage on Intel UHD Graphics) and thus impractical."
      }
    }

    ConfigSwitch {
      enabled: Config.options.background.widgets.clock.cookie.dialNumberStyle === "dots" || Config.options.background.widgets.clock.cookie.dialNumberStyle === "full"
      title: Translation.tr("Hour marks")
      checked: Config.options.background.widgets.clock.cookie.hourMarks
      onEnabledChanged: {
        checked = Config.options.background.widgets.clock.cookie.hourMarks;
      }
      onCheckedChanged: {
        Config.options.background.widgets.clock.cookie.hourMarks = checked;
      }
      StyledToolTip {
        text: "Can only be turned on using the 'Dots' or 'Full' dial style for aesthetic reasons"
      }
    }

    ConfigSwitch {
      enabled: Config.options.background.widgets.clock.cookie.dialNumberStyle !== "numbers"
      title: Translation.tr("Digits in the middle")
      checked: Config.options.background.widgets.clock.cookie.timeIndicators
      onEnabledChanged: {
        checked = Config.options.background.widgets.clock.cookie.timeIndicators;
      }
      onCheckedChanged: {
        Config.options.background.widgets.clock.cookie.timeIndicators = checked;
      }
      StyledToolTip {
        text: "Can't be turned on when using 'Numbers' dial style for aesthetic reasons"
      }
    }

    ConfigComboBox {
      visible: settingsClock.cookiePresent
      title: Translation.tr("Dial style")
      description: Translation.tr("The style of the hour markings around the clock face")
      value: Config.options.background.widgets.clock.cookie.dialNumberStyle
      onSelected: newValue => {
        Config.options.background.widgets.clock.cookie.dialNumberStyle = newValue;
        if (newValue !== "dots" && newValue !== "full") {
          Config.options.background.widgets.clock.cookie.hourMarks = false;
        }
        if (newValue === "numbers") {
          Config.options.background.widgets.clock.cookie.timeIndicators = false;
        }
      }
      model: [
        {
          displayName: "",
          value: "none"
        },
        {
          displayName: Translation.tr("Dots"),
          value: "dots"
        },
        {
          displayName: Translation.tr("Full"),
          value: "full"
        },
        {
          displayName: Translation.tr("Numbers"),
          value: "numbers"
        }
      ]
    }

    ConfigComboBox {
      visible: settingsClock.cookiePresent
      title: Translation.tr("Hour hand")
      description: Translation.tr("The style of the hour hand")
      value: Config.options.background.widgets.clock.cookie.hourHandStyle
      onSelected: newValue => {
        Config.options.background.widgets.clock.cookie.hourHandStyle = newValue;
      }
      model: [
        {
          displayName: "",
          value: "hide"
        },
        {
          displayName: Translation.tr("Classic"),
          value: "classic"
        },
        {
          displayName: Translation.tr("Hollow"),
          value: "hollow"
        },
        {
          displayName: Translation.tr("Fill"),
          value: "fill"
        },
      ]
    }

    ConfigComboBox {
      visible: settingsClock.cookiePresent
      title: Translation.tr("Minute hand")
      description: Translation.tr("The style of the minute hand")
      value: Config.options.background.widgets.clock.cookie.minuteHandStyle
      onSelected: newValue => {
        Config.options.background.widgets.clock.cookie.minuteHandStyle = newValue;
      }
      model: [
        {
          displayName: "",
          value: "hide"
        },
        {
          displayName: Translation.tr("Classic"),
          value: "classic"
        },
        {
          displayName: Translation.tr("Thin"),
          value: "thin"
        },
        {
          displayName: Translation.tr("Medium"),
          value: "medium"
        },
        {
          displayName: Translation.tr("Bold"),
          value: "bold"
        },
      ]
    }

    ConfigComboBox {
      visible: settingsClock.cookiePresent
      title: Translation.tr("Second hand")
      description: Translation.tr("The style of the second hand")
      value: Config.options.background.widgets.clock.cookie.secondHandStyle
      onSelected: newValue => {
        Config.options.background.widgets.clock.cookie.secondHandStyle = newValue;
      }
      model: [
        {
          displayName: "",
          value: "hide"
        },
        {
          displayName: Translation.tr("Classic"),
          value: "classic"
        },
        {
          displayName: Translation.tr("Line"),
          value: "line"
        },
        {
          displayName: Translation.tr("Dot"),
          value: "dot"
        },
      ]
    }

    ConfigComboBox {
      visible: settingsClock.cookiePresent
      title: Translation.tr("Date style")
      description: Translation.tr("How the date is displayed on the clock face")
      value: Config.options.background.widgets.clock.cookie.dateStyle
      onSelected: newValue => {
        Config.options.background.widgets.clock.cookie.dateStyle = newValue;
      }
      model: [
        {
          displayName: "",
          value: "hide"
        },
        {
          displayName: Translation.tr("Bubble"),
          value: "bubble"
        },
        {
          displayName: Translation.tr("Border"),
          value: "border"
        },
        {
          displayName: Translation.tr("Rect"),
          value: "rect"
        }
      ]
    }
  }

  ContentSection {
    title: Translation.tr("Widget: Weather")

    ConfigSwitch {
      title: Translation.tr("Enable")
      checked: Config.options.background.widgets.weather.enable
      onCheckedChanged: {
        Config.options.background.widgets.weather.enable = checked;
      }
    }
    ConfigComboBox {
      Layout.fillWidth: false
      title: Translation.tr("Placement")
      description: Translation.tr("Where the weather widget is positioned on the desktop")
      value: Config.options.background.widgets.weather.placementStrategy
      onSelected: newValue => {
        Config.options.background.widgets.weather.placementStrategy = newValue;
      }
      model: [
        {
          displayName: Translation.tr("Draggable"),
          value: "free"
        },
        {
          displayName: Translation.tr("Least busy"),
          value: "leastBusy"
        },
        {
          displayName: Translation.tr("Most busy"),
          value: "mostBusy"
        },
      ]
    }
  }
}
