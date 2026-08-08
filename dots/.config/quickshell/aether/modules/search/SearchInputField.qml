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

  property var searchPrefixType: SearchInputField.SearchPrefixType.DefaultSearch

  Connections {
    target: searchInput
    function onTextChanged() {
      const t = searchInput.text;
      if (t.startsWith(Config.options.search.prefix.action))
        root.searchPrefixType = SearchInputField.SearchPrefixType.Action;
      else if (t.startsWith(Config.options.search.prefix.app))
        root.searchPrefixType = SearchInputField.SearchPrefixType.App;
      else if (t.startsWith(Config.options.search.prefix.clipboard))
        root.searchPrefixType = SearchInputField.SearchPrefixType.Clipboard;
      else if (t.startsWith(Config.options.search.prefix.math))
        root.searchPrefixType = SearchInputField.SearchPrefixType.Math;
      else if (t.startsWith(Config.options.search.prefix.shellCommand))
        root.searchPrefixType = SearchInputField.SearchPrefixType.ShellCommand;
      else if (t.startsWith(Config.options.search.prefix.webSearch))
        root.searchPrefixType = SearchInputField.SearchPrefixType.WebSearch;
      else
        root.searchPrefixType = SearchInputField.SearchPrefixType.DefaultSearch;
    }
  }

  property var activeModeType: SearchInputField.SearchPrefixType.DefaultSearch

  Connections {
    target: LauncherSearch
    function onModeChanged() {
      const mode = LauncherSearch.mode;
      if (mode === Config.options.search.prefix.action)
        root.activeModeType = SearchInputField.SearchPrefixType.Action;
      else if (mode === Config.options.search.prefix.app)
        root.activeModeType = SearchInputField.SearchPrefixType.App;
      else if (mode === Config.options.search.prefix.clipboard)
        root.activeModeType = SearchInputField.SearchPrefixType.Clipboard;
      else if (mode === Config.options.search.prefix.math)
        root.activeModeType = SearchInputField.SearchPrefixType.Math;
      else if (mode === Config.options.search.prefix.shellCommand)
        root.activeModeType = SearchInputField.SearchPrefixType.ShellCommand;
      else if (mode === Config.options.search.prefix.webSearch)
        root.activeModeType = SearchInputField.SearchPrefixType.WebSearch;
      else
        root.activeModeType = SearchInputField.SearchPrefixType.DefaultSearch;
    }
  }

  MaterialSymbol {
    id: searchIcon
    color: Appearance.colors.colOnSurfaceVariant
    Layout.leftMargin: 10
    Layout.rightMargin: 0
    Layout.fillWidth: true
    Layout.fillHeight: true
    iconSize: Appearance.font.pixelSize.hugeass + 5
    text: switch (root.activeModeType) {
    case SearchInputField.SearchPrefixType.Action:
      return "action_key";
    case SearchInputField.SearchPrefixType.App:
      return "apps";
    case SearchInputField.SearchPrefixType.Clipboard:
      return "content_paste_search";
    case SearchInputField.SearchPrefixType.Math:
      return "calculate";
    case SearchInputField.SearchPrefixType.ShellCommand:
      return "terminal";
    case SearchInputField.SearchPrefixType.WebSearch:
      return "travel_explore";
    case SearchInputField.SearchPrefixType.DefaultSearch:
      return "search";
    default:
      return "search";
    }
  }

  // Change mode if prefix is used
  onSearchPrefixTypeChanged: {
    if (LauncherSearch.mode === "" && root.searchPrefixType !== SearchInputField.SearchPrefixType.DefaultSearch) {
      LauncherSearch.mode = searchInput.text.slice(0, 1);
      searchInput.text = searchInput.text.slice(1);
    }
  }

  ToolbarTextField { // Input box
    id: searchInput

    Layout.topMargin: 2
    Layout.bottomMargin: 2
    Layout.leftMargin: 0
    Layout.fillWidth: true

    // Hide TextField background
    background: Item {}

    Layout.fillHeight: true
    implicitWidth: Appearance.sizes.searchWidth
    font.pixelSize: Appearance.font.pixelSize.huge

    focus: GlobalStates.searchOpen

    placeholderText: {
      shape: switch (root.activeModeType) {
      case SearchInputField.SearchPrefixType.Action:
        return Translation.tr("Actions");
      case SearchInputField.SearchPrefixType.App:
        return Translation.tr("Applications");
      case SearchInputField.SearchPrefixType.Clipboard:
        return Translation.tr("Clipboard");
      case SearchInputField.SearchPrefixType.Math:
        return Translation.tr("Calculate");
      case SearchInputField.SearchPrefixType.ShellCommand:
        return Translation.tr("Shell Command");
      case SearchInputField.SearchPrefixType.WebSearch:
        return Translation.tr("Web Search");
      default:
        return Translation.tr("Type a command or search...");
      }
    }

    onTextChanged: LauncherSearch.query = text

    TextMetrics {
      id: inputMetrics
      font: searchInput.font
      text: searchInput.text
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

    // Auto suggestion
    Rectangle {
      visible: Config.options?.search?.autocomplete?.enable ? (suggestionText.suggestion.length > 0) : false
      x: searchInput.leftPadding + inputMetrics.advanceWidth
      // Height must be bound explicitly - Rectangle does not size itself to children,
      // so without this the anchor below centers a 0-height box instead of the text
      height: suggestionText.implicitHeight
      width: suggestionText.implicitWidth
      anchors.verticalCenter: searchInput.verticalCenter
      radius: 8

      // Show background if it is not autocomplete
      color: Config.options?.search?.autocomplete?.showBackground ? (!suggestionText.isAutocomplete ? "transparent" : Appearance.colors.colSurfaceContainerHigh) : "transparent"
      border.color: Config.options?.search?.autocomplete?.showBorder ? (!suggestionText.isAutocomplete ? "transparent" : Appearance.colors.colOutlineVariant) : ""
      border.width: Config.options?.search?.autocomplete?.showBorder ? (!suggestionText.isAutocomplete ? 0 : 1) : ""

      Text {
        id: suggestionText
        // Centers the text within the now-correctly-sized Rectangle
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
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
