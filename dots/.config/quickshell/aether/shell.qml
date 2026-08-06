//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000

// Remove two slashes below and adjust the value to change the UI scale
//@ pragma Env QT_SCALE_FACTOR=1

import "modules/common"
import "services"

import QtQuick
import QtQuick.Window
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.modules.common
import qs.modules.background
import qs.modules.bar
import qs.modules.cheatsheet
import qs.modules.dock
import qs.modules.lock
import qs.modules.search
import qs.modules.notificationCenter
import qs.modules.mediaControls
import qs.modules.notificationPopup
import qs.modules.onScreenDisplay
import qs.modules.onScreenKeyboard
// import qs.modules.overview
import qs.modules.polkit
import qs.modules.regionSelector
import qs.modules.screenCorners
import qs.modules.sessionScreen
import qs.modules.sidebarRight
import qs.modules.wallpaperSelector

ShellRoot {
  id: root

  ReloadPopup {}

  Component.onCompleted: {
    MaterialThemeLoader.reapplyTheme();
    Hyprsunset.load();
    FirstRunExperience.load();
    ConflictKiller.load();
    Cliphist.refresh();
    Wallpapers.load();
  }
  Scope {
    PanelLoader {
      component: Lock {}
    }
    PanelLoader {
      extraCondition: Config.options.background.enable
      component: Background {}
    }
    PanelLoader {
      extraCondition: Config.options.bar.enable
      component: Bar {}
    }
    PanelLoader {
      extraCondition: Config.options.dock.enable
      component: Dock {}
    }
    PanelLoader {
      component: Polkit {}
    }
    PanelLoader {
      extraCondition: Config.options.search.enable
      component: Search {}
    }
    PanelLoader {
      component: SessionScreen {}
    }
    PanelLoader {
      component: ScreenCorners {}
    }
    PanelLoader {
      component: SidebarRight {}
    }
    PanelLoader {
      component: NotificationPopup {}
    }
    PanelLoader {
      component: OnScreenDisplay {}
    }
    // PanelLoader {
    //   component: Overview {}
    // }
    PanelLoader {
      component: OnScreenKeyboard {}
    }
    PanelLoader {
      component: RegionSelector {}
    }
    PanelLoader {
      component: MediaControls {}
    }
    PanelLoader {
      extraCondition: Config.options.background.enable
      component: WallpaperSelector {}
    }
    PanelLoader {
      component: NotificationCenter {}
    }
    PanelLoader {
      component: Cheatsheet {}
    }
  }
}
