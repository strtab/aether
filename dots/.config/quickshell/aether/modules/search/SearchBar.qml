pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

RowLayout {
  id: root
  spacing: 6
  property bool animateWidth: false
  property alias searchInput: searchInput
  property string searchingText: ""

  function forceFocus() {
    searchInput.forceActiveFocus();
  }

  enum SearchPrefixType {
    Action,
    App,
    Clipboard,
    Math,
    ShellCommand,
    WebSearch,
    DefaultSearch
  }

  property var searchPrefixType: SearchBar.SearchPrefixType.DefaultSearch

  Connections {
    target: searchInput
    function onTextChanged() {
      const t = searchInput.text;
      if (t.startsWith(Config.options.search.prefix.action))
        root.searchPrefixType = SearchBar.SearchPrefixType.Action;
      else if (t.startsWith(Config.options.search.prefix.app))
        root.searchPrefixType = SearchBar.SearchPrefixType.App;
      else if (t.startsWith(Config.options.search.prefix.clipboard))
        root.searchPrefixType = SearchBar.SearchPrefixType.Clipboard;
      else if (t.startsWith(Config.options.search.prefix.math))
        root.searchPrefixType = SearchBar.SearchPrefixType.Math;
      else if (t.startsWith(Config.options.search.prefix.shellCommand))
        root.searchPrefixType = SearchBar.SearchPrefixType.ShellCommand;
      else if (t.startsWith(Config.options.search.prefix.webSearch))
        root.searchPrefixType = SearchBar.SearchPrefixType.WebSearch;
      else
        root.searchPrefixType = SearchBar.SearchPrefixType.DefaultSearch;
    }
  }

  property var activeModeType: SearchBar.SearchPrefixType.DefaultSearch

  Connections {
    target: LauncherSearch
    function onModeChanged() {
      const mode = LauncherSearch.mode;
      if (mode === Config.options.search.prefix.action)
        root.activeModeType = SearchBar.SearchPrefixType.Action;
      else if (mode === Config.options.search.prefix.app)
        root.activeModeType = SearchBar.SearchPrefixType.App;
      else if (mode === Config.options.search.prefix.clipboard)
        root.activeModeType = SearchBar.SearchPrefixType.Clipboard;
      else if (mode === Config.options.search.prefix.math)
        root.activeModeType = SearchBar.SearchPrefixType.Math;
      else if (mode === Config.options.search.prefix.shellCommand)
        root.activeModeType = SearchBar.SearchPrefixType.ShellCommand;
      else if (mode === Config.options.search.prefix.webSearch)
        root.activeModeType = SearchBar.SearchPrefixType.WebSearch;
      else
        root.activeModeType = SearchBar.SearchPrefixType.DefaultSearch;
    }
  }

  MaterialShapeWrappedMaterialSymbol {
    id: searchIcon
    Layout.alignment: Qt.AlignVCenter
    iconSize: (Config.options.search.fontSize + 5) ?? Appearance.font.pixelSize.huge
    shape: switch (root.activeModeType) {
    case SearchBar.SearchPrefixType.Action:
      return MaterialShape.Shape.Pill;
    case SearchBar.SearchPrefixType.App:
      return MaterialShape.Shape.Clover4Leaf;
    case SearchBar.SearchPrefixType.Clipboard:
      return MaterialShape.Shape.Gem;
    case SearchBar.SearchPrefixType.Math:
      return MaterialShape.Shape.PuffyDiamond;
    case SearchBar.SearchPrefixType.ShellCommand:
      return MaterialShape.Shape.PixelCircle;
    case SearchBar.SearchPrefixType.WebSearch:
      return MaterialShape.Shape.SoftBurst;
    default:
      return MaterialShape.Shape.Cookie7Sided;
    }
    text: switch (root.activeModeType) {
    case SearchBar.SearchPrefixType.Action:
      return "action_key";
    case SearchBar.SearchPrefixType.App:
      return "apps";
    case SearchBar.SearchPrefixType.Clipboard:
      return "content_paste_search";
    case SearchBar.SearchPrefixType.Math:
      return "calculate";
    case SearchBar.SearchPrefixType.ShellCommand:
      return "terminal";
    case SearchBar.SearchPrefixType.WebSearch:
      return "travel_explore";
    case SearchBar.SearchPrefixType.DefaultSearch:
      return "search";
    default:
      return "search";
    }
  }

  // Change mode if prefix is used
  onSearchPrefixTypeChanged: {
    if (LauncherSearch.mode === "" && root.searchPrefixType !== SearchBar.SearchPrefixType.DefaultSearch) {
      LauncherSearch.mode = searchInput.text.slice(0, 1);
      searchInput.text = searchInput.text.slice(1);
    }
  }

  ToolbarTextField { // Search box
    id: searchInput

    Layout.topMargin: (searchInput.font.pixelSize / 3)
    Layout.bottomMargin: (searchInput.font.pixelSize / 3)
    Layout.leftMargin: (searchInput.font.pixelSize / 8)
    Layout.rightMargin: (searchInput.font.pixelSize / 8)
    Layout.fillWidth: true

    // Hide TextField background
    background: Item {}

    implicitHeight: 40
    implicitWidth: Config.options.search.collapsed ? (root.searchingText == "" ? Appearance.sizes.searchWidthCollapsed : Appearance.sizes.searchWidth) : Appearance.sizes.searchWidth
    font.pixelSize: Config.options.search.fontSize ?? Appearance.font.pixelSize.large

    focus: GlobalStates.searchOpen

    placeholderText: {
      shape: switch (root.activeModeType) {
      case SearchBar.SearchPrefixType.Action:
        return Translation.tr("Actions");
      case SearchBar.SearchPrefixType.App:
        return Translation.tr("Applications");
      case SearchBar.SearchPrefixType.Clipboard:
        return Translation.tr("Clipboard");
      case SearchBar.SearchPrefixType.Math:
        return Translation.tr("Calculate");
      case SearchBar.SearchPrefixType.ShellCommand:
        return Translation.tr("Shell Command");
      case SearchBar.SearchPrefixType.WebSearch:
        return Translation.tr("Web Search");
      default:
        return Translation.tr("Search for anything...");
      }
    }

    Behavior on implicitWidth {
      id: searchWidthBehavior
      enabled: root.animateWidth
      NumberAnimation {
        duration: 300
        easing.type: Appearance.animation.elementMove.type
        easing.bezierCurve: Appearance.animation.elementMove.bezierCurve
      }
    }

    onTextChanged: LauncherSearch.query = text

    TextMetrics {
      id: inputMetrics
      font: searchInput.font
      text: searchInput.text
    }

    // Auto suggestion
    Rectangle {
      visible: Config.options?.search?.autocomplete?.enable ? (suggestionText.suggestion.length > 0) : false
      anchors.verticalCenter: parent.verticalCenter
      x: searchInput.leftPadding + inputMetrics.advanceWidth
      height: suggestionText.implicitHeight + 4
      width: suggestionText.implicitWidth + 8

      // Show background if it is not autocomplete
      radius: !suggestionText.isAutocomplete ? 0 : 8
      color: Config.options?.search?.autocomplete?.showBackground ? (!suggestionText.isAutocomplete ? "transparent" : Appearance.colors.colSurfaceContainerHigh) : "transparent"
      border.color: Config.options?.search?.autocomplete?.showBorder ? (!suggestionText.isAutocomplete ? "transparent" : Appearance.colors.colOutlineVariant) : ""
      border.width: Config.options?.search?.autocomplete?.showBorder ? (!suggestionText.isAutocomplete ? 0 : 1) : ""

      Text {
        id: suggestionText
        property bool isAutocomplete: {
          if (LauncherSearch.results.length === 0 || searchInput.text.length === 0)
            return false;
          const res = LauncherSearch.results[LauncherSearch.selectedIndex];
          if (!res)
            return false;
          const name = res.name.toLowerCase();
          const query = searchInput.text.toLowerCase();
          return (name.startsWith(query) && name !== query) || (name.includes(query) && name !== query);
        }
        property string suggestion: {
          if (LauncherSearch.results.length === 0 || searchInput.text.length === 0)
            return "";
          const res = LauncherSearch.results[LauncherSearch.selectedIndex];
          if (!res)
            return "";
          const name = res.name.toLowerCase();
          const query = searchInput.text.toLowerCase();
          const verb = res.verb ?? "";
          const suffix = verb !== "" ? " — " + verb : "";
          if (isAutocomplete) {
            if (name.startsWith(query))
              return res.name.slice(searchInput.text.length).toLowerCase() + suffix;
            return " — " + res.name;
          }
          return verb !== "" ? " — " + verb : "";
        }
        text: suggestion
        font: searchInput.font
        color: Appearance.colors.colOnSurfaceVariant
        opacity: 0.4
      }
    }

    onAccepted: {
      if (appResults.count > 0) {
        // Get the first visible delegate and trigger its click
        let firstItem = appResults.itemAtIndex(0);
        if (firstItem && firstItem.clicked) {
          firstItem.clicked();
        }
      }
    }

    Keys.onPressed: event => {
      if (event.key === Qt.Key_C && event.modifiers & Qt.ControlModifier) {
        LauncherSearch.query = "";
        LauncherSearch.mode = "";
        root.searchingText = "";
        searchInput.text = "";
        return;
      }

      if (event.key === Qt.Key_D && event.modifiers & Qt.ControlModifier) {
        GlobalStates.searchOpen = false;
        return;
      }

      if (event.key === Qt.Key_Tab) {
        if (LauncherSearch.results.length === 0)
          return;
        const tabbedText = LauncherSearch.results[0].name.toLowerCase();
        LauncherSearch.query = tabbedText;
        searchInput.text = tabbedText;
        event.accepted = true;
      }
      if (event.key === Qt.Key_Backspace && searchInput.activeFocus && searchInput.text.length === 0 && LauncherSearch.mode !== "") {
        LauncherSearch.mode = "";
        event.accepted = true;
      }
    }
  }

  // IconToolbarButton {
  //     Layout.topMargin: 4
  //     Layout.bottomMargin: 4
  //
  //     onClicked: {
  //         GlobalStates.searchOpen = false;
  //         Quickshell.execDetached(["qs", "-p", Quickshell.shellPath(""), "ipc", "call", "region", "search"]);
  //     }
  //     text: "image_search"
  //     StyledToolTip {
  //         text: Translation.tr("Google Lens")
  //     }
  // }

  // IconToolbarButton {
  //     id: songRecButton
  //     Layout.topMargin: 4
  //     Layout.bottomMargin: 4
  //     Layout.rightMargin: 4
  //     toggled: SongRec.running
  //     onClicked: SongRec.toggleRunning()
  //     text: "music_cast"
  //
  //    StyledToolTip {
  //         text: Translation.tr("Recognize music")
  //     }
  //
  //     colText: toggled ? Appearance.colors.colOnPrimary : Appearance.colors.colOnSurfaceVariant
  //     background: MaterialShape {
  //         RotationAnimation on rotation {
  //             running: songRecButton.toggled
  //             duration: 12000
  //             easing.type: Easing.Linear
  //             loops: Animation.Infinite
  //             from: 0
  //             to: 360
  //         }
  //         shape: {
  //             if (songRecButton.down) {
  //                 return songRecButton.toggled ? MaterialShape.Shape.Circle : MaterialShape.Shape.Square
  //             } else {
  //                 return songRecButton.toggled ? MaterialShape.Shape.SoftBurst : MaterialShape.Shape.Circle
  //             }
  //         }
  //         color: {
  //             if (songRecButton.toggled) {
  //                 return songRecButton.hovered ? Appearance.colors.colPrimaryHover : Appearance.colors.colPrimary
  //             } else {
  //                 return songRecButton.hovered ? Appearance.colors.colSurfaceContainerHigh : ColorUtils.transparentize(Appearance.colors.colSurfaceContainerHigh)
  //             }
  //         }
  //         Behavior on color {
  //             animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
  //         }
  //     }
  // }
}
