pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import Qt5Compat.GraphicalEffects
import qs.services
import qs.modules.bar
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

RippleButton {
  id: root
  required property SystemTrayItem item
  property bool targetMenuOpen: false
  signal menuOpened(qsWindow: var)
  signal menuClosed

  hoverEnabled: true
  buttonRadius: Appearance.rounding.normal

  implicitWidth: 22 * 2
  implicitHeight: 18

  colBackground: "transparent"
  colBackgroundHover: Appearance.colors.colLayer1Hover
  colRipple: Appearance.colors.colLayer1Active
  colBackgroundToggled: Appearance.colors.colSecondaryContainer
  colBackgroundToggledHover: Appearance.colors.colSecondaryContainerHover
  colRippleToggled: Appearance.colors.colSecondaryContainerActive
  toggled: menu.active

  downAction: () => {
    item.activate();
  }

  altAction: () => {
    if (item.hasMenu) {
      if (menu.active && menu.item && typeof menu.item.close === "function")
        menu.item.close();
      else
        menu.open();
    }
  }

  onHoveredChanged: {
    if (root.hovered)
      tooltip.text = TrayService.getTooltipForItem(root.item);
  }

  Loader {
    id: menu
    function open() {
      menu.active = true;
    }
    active: false
    sourceComponent: SysTrayMenu {
      Component.onCompleted: this.open()
      trayItemMenuHandle: root.item.menu
      trayItemId: root.item.id
      anchor {
        window: root.QsWindow.window
        item: root
        gravity: Edges.Bottom
        edges: Edges.Bottom
      }
      onMenuOpened: window => root.menuOpened(window)
      onMenuClosed: {
        root.menuClosed();
        menu.active = false;
      }
    }
  }

  IconImage {
    id: trayIcon
    visible: !Config.options.tray.monochromeIcons
    source: root.item.icon
    anchors.centerIn: parent
    width: 18
    height: 18
  }

  Loader {
    active: Config.options.tray.monochromeIcons
    anchors.fill: trayIcon
    sourceComponent: Item {
      Desaturate {
        id: desaturatedIcon
        visible: false // There's already a color overlay
        anchors.fill: parent
        source: trayIcon
        desaturation: 0.8 // 1.0 means fully grayscale
      }
      ColorOverlay {
        anchors.fill: desaturatedIcon
        source: desaturatedIcon
        color: Appearance.colors.onMenubarBackground
      }
    }
  }

  PopupToolTip {
    id: tooltip
    extraVisibleCondition: root.hovered
    alternativeVisibleCondition: extraVisibleCondition
    anchorEdges: Edges.Bottom
  }
}
