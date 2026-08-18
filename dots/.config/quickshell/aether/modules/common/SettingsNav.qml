pragma Singleton
import QtQuick
import Quickshell

// Any regular settings page can call SettingsNav.open(title, component) from
// a plain button to have settings.qml display that subpage with a back
// button, without settings.qml needing to know about it in advance.
Singleton {
  id: root

  property string subPageTitle: ""
  property Component subPageComponent: null
  readonly property bool subPageOpen: root.subPageComponent !== null

  function open(title, component) {
    root.subPageTitle = title;
    root.subPageComponent = component;
  }

  function close() {
    root.subPageComponent = null;
    root.subPageTitle = "";
  }
}
