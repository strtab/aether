import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import Qt.labs.synchronizer
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
  id: root
  property bool dontAutoCancelSearch: false

  PanelWindow {
    id: panelWindow
    property string searchingText: ""
    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(panelWindow.screen)
    property bool monitorIsFocused: (Hyprland.focusedMonitor?.id == monitor?.id)
    visible: GlobalStates.searchOpen

    WlrLayershell.namespace: "quickshell:search"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: GlobalStates.searchOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    color: "transparent"

    mask: Region {
      item: GlobalStates.searchOpen ? columnLayout : null
    }

    anchors {
      top: true
      bottom: true
      left: true
      right: true
    }

    Connections {
      target: GlobalStates
      function onSearchOpenChanged() {
        if (!GlobalStates.searchOpen) {
          searchWidget.disableExpandAnimation();
          root.dontAutoCancelSearch = false;
          GlobalFocusGrab.dismiss();
        } else {
          if (!root.dontAutoCancelSearch && panelWindow.searchingText === "") {
            searchWidget.cancelSearch();
          }
          GlobalFocusGrab.addDismissable(panelWindow);
        }
      }
    }

    Connections {
      target: GlobalFocusGrab
      function onDismissed() {
        GlobalStates.searchOpen = false;
      }
    }
    implicitWidth: columnLayout.implicitWidth
    implicitHeight: columnLayout.implicitHeight

    function setSearchingText(text) {
      searchWidget.setSearchingText(text);
      searchWidget.focusFirstItem();
    }

    function setSearchingMode(text) {
      searchWidget.setSearchingMode(text);
      searchWidget.focusFirstItem();
    }

    Column {
      id: columnLayout
      visible: GlobalStates.searchOpen
      anchors {
        horizontalCenter: parent.horizontalCenter
        top: parent.top
      }
      spacing: -8

      add: Transition {}
      populate: Transition {}
      move: Transition {}

      Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) {
          GlobalStates.searchOpen = false;
        }
      }

      SearchWidget {
        id: searchWidget
        anchors.horizontalCenter: parent.horizontalCenter
        Synchronizer on searchingText {
          property alias source: panelWindow.searchingText
        }
      }
    }
  }

  function toggleClipboard() {
    if (GlobalStates.searchOpen && root.dontAutoCancelSearch) {
      GlobalStates.searchOpen = false;
      return;
    }
    root.dontAutoCancelSearch = true;
    panelWindow.setSearchingMode(Config.options.search.prefix.clipboard);
    GlobalStates.searchOpen = true;
  }

  IpcHandler {
    target: "search"

    function toggle() {
      GlobalStates.searchOpen = !GlobalStates.searchOpen;
    }
    function workspacesToggle() {
      GlobalStates.searchOpen = !GlobalStates.searchOpen;
    }
    function close() {
      GlobalStates.searchOpen = false;
    }
    function open() {
      GlobalStates.searchOpen = true;
    }
    function toggleReleaseInterrupt() {
      GlobalStates.superReleaseMightTrigger = false;
    }
    function clipboardToggle() {
      root.toggleClipboard();
    }
  }

  GlobalShortcut {
    name: "searchToggle"
    description: "Toggles search on press"

    onPressed: {
      GlobalStates.searchOpen = !GlobalStates.searchOpen;
    }
  }
  GlobalShortcut {
    name: "searchToggleRelease"
    description: "Toggles search on release"

    onPressed: {
      GlobalStates.superReleaseMightTrigger = true;
    }

    onReleased: {
      if (!GlobalStates.superReleaseMightTrigger) {
        GlobalStates.superReleaseMightTrigger = true;
        return;
      }
      GlobalStates.searchOpen = !GlobalStates.searchOpen;
    }
  }
  GlobalShortcut {
    name: "searchToggleReleaseInterrupt"
    description: "Interrupts possibility of search being toggled on release. " + "This is necessary because GlobalShortcut.onReleased in quickshell triggers whether or not you press something else while holding the key. " + "To make sure this works consistently, use binditn = MODKEYS, catchall in an automatically triggered submap that includes everything."

    onPressed: {
      GlobalStates.superReleaseMightTrigger = false;
    }
  }
  GlobalShortcut {
    name: "searchClipboardToggle"
    description: "Toggle clipboard query on search widget"

    onPressed: {
      root.toggleClipboard();
    }
  }
}
