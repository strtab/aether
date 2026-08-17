import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Quickshell
import qs.modules.common.functions
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.models.hyprland

ContentPage {
  id: page
  forceWidth: true

  function goTo(term) {
    const t = term.toLowerCase().trim();

    function findTarget(rootItem) {
      for (let i = 0; i < rootItem.children.length; i++) {
        let child = rootItem.children[i];
        if (child.title && child.title.toLowerCase().includes(t)) {
          return child;
        }
      }
      for (let i = 0; i < rootItem.children.length; i++) {
        let found = findTarget(rootItem.children[i]);
        if (found)
          return found;
      }
      return null;
    }

    let target = findTarget(mainLayout);
    if (target) {
      let pos = target.mapToItem(mainLayout, 0, 0);
      page.contentY = Math.max(0, pos.y - 0);
    }
  }

  Component.onCompleted: {
    const h = Config.options.hyprland;
    HyprlandConfig.setMany({
      "decoration:rounding": h.decoration.rounding,
      "decoration:blur:enabled": h.decoration.blur.enabled ? 1 : 0,
      "decoration:blur:size": h.decoration.blur.size,
      "decoration:blur:passes": h.decoration.blur.passes,
      "decoration:active_opacity": h.decoration.activeOpacity,
      "decoration:inactive_opacity": h.decoration.inactiveOpacity,
      "general:border_size": h.general.borderSize,
      "general:gaps_in": h.general.gapsIn,
      "general:gaps_out": h.general.gapsOut,
      "general:layout": h.general.layout,
      "animations:enabled": h.animations.enable ? 1 : 0,
      "input:kb_layout": h.input.kbLayout,
      "input:numlock_by_default": h.input.numlock ? 1 : 0,
      "input:repeat_delay": h.input.repeatDelay,
      "input:repeat_rate": h.input.repeatRate,
      "input:follow_mouse": h.input.followMouse,
      "input:touchpad:natural_scroll": h.input.touchpad.naturalScroll ? 1 : 0,
      "input:touchpad:disable_while_typing": h.input.touchpad.disableWhileTyping ? 1 : 0,
      "input:touchpad:clickfinger_behavior": h.input.touchpad.clickfingerBehavior ? 1 : 0,
      "input:touchpad:scroll_factor": h.input.touchpad.scrollFactor
    });
  }

  MonitorConfigOption {
    id: monitorConfig
  }

  ColumnLayout {
    id: mainLayout
    Layout.fillWidth: true
    Layout.fillHeight: true
    spacing: 20

    // ── Displays ──────────────────────────────────────────────────────────
    ContentSection {
      title: Translation.tr("Displays")
      visible: monitorConfig.monitors.length > 0

      MonitorCanvas {
        id: monitorCanvas
        Layout.fillWidth: true
        monitorConfig: monitorConfig
      }

      ContentSubsection {
        title: (monitorConfig.monitors[monitorCanvas.selectedIndex]?.name ?? "") + " · " + (monitorConfig.monitors[monitorCanvas.selectedIndex]?.description ?? "")

        ConfigSwitch {
          text: Translation.tr("Enabled")
          checked: !(monitorConfig.monitors[monitorCanvas.selectedIndex]?.disabled ?? false)
          onCheckedChanged: {
            monitorConfig.updateMonitor(monitorCanvas.selectedIndex, {
              disabled: !checked
            });
            monitorConfig.applyAndSave(monitorCanvas.selectedIndex);
          }
        }

        ContentSubsection {
          title: Translation.tr("Resolution & Refresh Rate")
          StyledComboBoxSearch {
            model: (monitorConfig.monitors[monitorCanvas.selectedIndex]?.availableModes ?? []).map(mode => ({
                  display: mode,
                  value: mode
                }))
            textRole: "display"
            currentIndex: (monitorConfig.monitors[monitorCanvas.selectedIndex]?.availableModes ?? []).indexOf(monitorConfig.monitors[monitorCanvas.selectedIndex]?.currentMode ?? "")
            onActivated: {
              const mon = monitorConfig.monitors[monitorCanvas.selectedIndex];
              const mode = mon.availableModes[currentIndex];
              const parts = mode.match(/(\d+)x(\d+)@([\d.]+)Hz/);
              monitorConfig.updateMonitor(monitorCanvas.selectedIndex, {
                currentMode: mode,
                width: parseInt(parts[1]),
                height: parseInt(parts[2]),
                refreshRate: parseFloat(parts[3])
              });
              monitorConfig.applyAndSave(monitorCanvas.selectedIndex);
            }
          }
        }

        ConfigComboBox {
          title: Translation.tr("Orientation")
          description: Translation.tr("Rotation applied to the selected display")
          value: monitorConfig.monitors[monitorCanvas.selectedIndex]?.transform ?? 0
          onSelected: newValue => {
            monitorConfig.updateMonitor(monitorCanvas.selectedIndex, {
              transform: newValue
            });
            monitorConfig.applyAndSave(monitorCanvas.selectedIndex);
          }
          model: [
            {
              displayName: Translation.tr("Normal"),
              value: 0
            },
            {
              displayName: "90°",
              value: 1
            },
            {
              displayName: "180°",
              value: 2
            },
            {
              displayName: "270°",
              value: 3
            },
          ]
        }

        ConfigSpinBox {
          text: Translation.tr("Scale")
          value: Math.round((monitorConfig.monitors[monitorCanvas.selectedIndex]?.scale ?? 1.0) * 100)
          from: 50
          to: 300
          stepSize: 20
          onValueChanged: {
            monitorConfig.updateMonitor(monitorCanvas.selectedIndex, {
              scale: value / 100.0
            });
            monitorConfig.applyAndSave(monitorCanvas.selectedIndex);
          }
        }

        ConfigSpinBox {
          text: Translation.tr("Position X")
          value: monitorConfig.monitors[monitorCanvas.selectedIndex]?.x ?? 0
          from: 0
          to: 7680
          stepSize: 1
          onValueChanged: {
            monitorConfig.updateMonitor(monitorCanvas.selectedIndex, {
              x: value
            });
            monitorConfig.applyAndSave(monitorCanvas.selectedIndex);
          }
        }

        ConfigSpinBox {
          text: Translation.tr("Position Y")
          value: monitorConfig.monitors[monitorCanvas.selectedIndex]?.y ?? 0
          from: 0
          to: 4320
          stepSize: 1
          onValueChanged: {
            monitorConfig.updateMonitor(monitorCanvas.selectedIndex, {
              y: value
            });
            monitorConfig.applyAndSave(monitorCanvas.selectedIndex);
          }
        }
      }
    }

    // ── Layout ────────────────────────────────────────────────────────────
    ContentSection {
      title: Translation.tr("Layout")

      ConfigComboBox {
        title: Translation.tr("Tiling Layout")
        description: Translation.tr("The algorithm Hyprland uses to arrange your windows")
        value: Config.options.hyprland.general.layout
        onSelected: newValue => {
          Config.options.hyprland.general.layout = newValue;
          HyprlandConfig.set("general:layout", newValue);
        }
        model: [
          {
            displayName: Translation.tr("Dwindle"),
            value: "dwindle"
          },
          {
            displayName: Translation.tr("Master"),
            value: "master"
          },
          {
            displayName: Translation.tr("Scrolling"),
            value: "scrolling"
          },
        ]
      }
    }

    // ── Input ─────────────────────────────────────────────────────────────
    ContentSection {
      title: Translation.tr("Input")

      ContentSubsection {
        title: Translation.tr("Keyboard")

        ConfigInput {
          title: Translation.tr("Keyboard layout")
          description: Translation.tr("Examples: us, es, latam")
          placeholderText: Translation.tr("Keyboard layout")
          text: Config.options.hyprland.input.kbLayout
          onTextChanged: {
            Config.options.hyprland.input.kbLayout = text;
            HyprlandConfig.set("input:kb_layout", text);
          }
        }

        ConfigSwitch {
          text: Translation.tr("Numlock by default")
          checked: Config.options.hyprland.input.numlock
          onCheckedChanged: {
            Config.options.hyprland.input.numlock = checked;
            HyprlandConfig.set("input:numlock_by_default", checked ? 1 : 0);
          }
        }

        ConfigSpinBox {
          text: Translation.tr("Repeat delay (ms)")
          value: Config.options.hyprland.input.repeatDelay
          from: 100
          to: 1000
          stepSize: 10
          onValueChanged: {
            Config.options.hyprland.input.repeatDelay = value;
            HyprlandConfig.set("input:repeat_delay", value);
          }
        }

        ConfigSpinBox {
          text: Translation.tr("Repeat rate")
          value: Config.options.hyprland.input.repeatRate
          from: 10
          to: 100
          stepSize: 1
          onValueChanged: {
            Config.options.hyprland.input.repeatRate = value;
            HyprlandConfig.set("input:repeat_rate", value);
          }
        }

        ConfigComboBox {
          title: Translation.tr("Follow mouse")
          description: Translation.tr("How moving the cursor affects window focus")
          value: Config.options.hyprland.input.followMouse
          onSelected: newValue => {
            Config.options.hyprland.input.followMouse = newValue;
            HyprlandConfig.set("input:follow_mouse", newValue);
          }
          model: [
            {
              displayName: Translation.tr("Disabled"),
              value: 0
            },
            {
              displayName: Translation.tr("Full"),
              value: 1
            },
            {
              displayName: Translation.tr("Loose"),
              value: 2
            },
            {
              displayName: Translation.tr("Explicit"),
              value: 3
            },
          ]
        }
      }

      ContentSubsection {
        title: Translation.tr("Touchpad")

        ConfigSwitch {
          text: Translation.tr("Natural scroll")
          checked: Config.options.hyprland.input.touchpad.naturalScroll
          onCheckedChanged: {
            Config.options.hyprland.input.touchpad.naturalScroll = checked;
            HyprlandConfig.set("input:touchpad:natural_scroll", checked ? 1 : 0);
          }
        }

        ConfigSwitch {
          text: Translation.tr("Disable while typing")
          checked: Config.options.hyprland.input.touchpad.disableWhileTyping
          onCheckedChanged: {
            Config.options.hyprland.input.touchpad.disableWhileTyping = checked;
            HyprlandConfig.set("input:touchpad:disable_while_typing", checked ? 1 : 0);
          }
        }

        ConfigSwitch {
          text: Translation.tr("Clickfinger behavior")
          checked: Config.options.hyprland.input.touchpad.clickfingerBehavior
          onCheckedChanged: {
            Config.options.hyprland.input.touchpad.clickfingerBehavior = checked;
            HyprlandConfig.set("input:touchpad:clickfinger_behavior", checked ? 1 : 0);
          }
        }

        ConfigSpinBox {
          text: Translation.tr("Scroll factor")
          value: Math.round(Config.options.hyprland.input.touchpad.scrollFactor * 10)
          from: 1
          to: 30
          stepSize: 1
          onValueChanged: {
            Config.options.hyprland.input.touchpad.scrollFactor = value / 10.0;
            HyprlandConfig.set("input:touchpad:scroll_factor", value / 10.0);
          }
        }
      }
    }

    // ── Visual & Aesthetics ───────────────────────────────────────────────
    ContentSection {
      title: Translation.tr("Visual & Aesthetics")

      ConfigSpinBox {
        text: Translation.tr("Window Rounding")
        value: Config.options.hyprland.decoration.rounding
        from: 0
        to: 30
        stepSize: 1
        onValueChanged: {
          Config.options.hyprland.decoration.rounding = value;
          HyprlandConfig.set("decoration:rounding", value);
        }
      }

      ConfigSpinBox {
        text: Translation.tr("Border Size")
        value: Config.options.hyprland.general.borderSize
        from: 0
        to: 10
        stepSize: 1
        onValueChanged: {
          Config.options.hyprland.general.borderSize = value;
          HyprlandConfig.set("general:border_size", value);
        }
      }

      ContentSubsection {
        title: Translation.tr("Blur")
        ConfigSwitch {
          text: Translation.tr("Blur")
          checked: Config.options.hyprland.decoration.blur.enabled
          onCheckedChanged: {
            Config.options.hyprland.decoration.blur.enabled = checked;
            HyprlandConfig.set("decoration:blur:enabled", checked ? 1 : 0);
          }
        }

        ConfigSpinBox {
          text: Translation.tr("Blur Size")
          value: Config.options.hyprland.decoration.blur.size
          from: 1
          to: 20
          stepSize: 1
          onValueChanged: {
            Config.options.hyprland.decoration.blur.size = value;
            HyprlandConfig.set("decoration:blur:size", value);
          }
        }

        ConfigSpinBox {
          text: Translation.tr("Blur Passes")
          value: Config.options.hyprland.decoration.blur.passes
          from: 1
          to: 6
          stepSize: 1
          onValueChanged: {
            Config.options.hyprland.decoration.blur.passes = value;
            HyprlandConfig.set("decoration:blur:passes", value);
          }
        }
      }

      ContentSubsection {
        title: Translation.tr("Gaps")

        ConfigSpinBox {
          text: Translation.tr("Gaps In")
          value: Config.options.hyprland.general.gapsIn
          from: 0
          to: 40
          stepSize: 1
          onValueChanged: {
            Config.options.hyprland.general.gapsIn = value;
            HyprlandConfig.set("general:gaps_in", value);
          }
        }

        ConfigSpinBox {
          text: Translation.tr("Gaps Out")
          value: Config.options.hyprland.general.gapsOut
          from: 0
          to: 60
          stepSize: 1
          onValueChanged: {
            Config.options.hyprland.general.gapsOut = value;
            HyprlandConfig.set("general:gaps_out", value);
          }
        }
      }

      ContentSubsection {
        title: Translation.tr("Opacity")

        ConfigSpinBox {
          text: Translation.tr("Active Opacity")
          value: Math.round(Config.options.hyprland.decoration.activeOpacity * 100)
          from: 10
          to: 100
          stepSize: 5
          onValueChanged: {
            Config.options.hyprland.decoration.activeOpacity = value / 100.0;
            HyprlandConfig.set("decoration:active_opacity", value / 100.0);
          }
        }

        ConfigSpinBox {
          text: Translation.tr("Inactive Opacity")
          value: Math.round(Config.options.hyprland.decoration.inactiveOpacity * 100)
          from: 10
          to: 100
          stepSize: 5
          onValueChanged: {
            Config.options.hyprland.decoration.inactiveOpacity = value / 100.0;
            HyprlandConfig.set("decoration:inactive_opacity", value / 100.0);
          }
        }
      }
    }

    // ── Animations ────────────────────────────────────────────────────────
    ContentSection {
      title: Translation.tr("Animations")

      ConfigSwitch {
        text: Translation.tr("Enable Animations")
        checked: Config.options.hyprland.animations.enable
        onCheckedChanged: {
          Config.options.hyprland.animations.enable = checked;
          HyprlandConfig.set("animations:enabled", checked ? 1 : 0);
        }
      }

      ConfigComboBox {
        title: Translation.tr("Animation Preset")
        description: Translation.tr("The overall animation feel used for window and workspace transitions")
        value: Config.options.hyprland.animations.animation
        onSelected: newValue => {
          Config.options.hyprland.animations.animation = newValue;
          saveAnimProc.command = ["python3", HyprlandConfig.configuratorScriptPath, "--anim-preset", newValue];
          saveAnimProc.running = true;
        }
        model: [
          {
            displayName: Translation.tr("Normal"),
            value: "normal"
          },
          {
            displayName: Translation.tr("Reduced"),
            value: "reduced"
          },
          {
            displayName: Translation.tr("Elastic"),
            value: "fast"
          },
          {
            displayName: Translation.tr("Niri Like"),
            value: "niri"
          },
        ]
      }

      Process {
        id: saveAnimProc
        onRunningChanged: if (!running)
          reloadAnimProc.running = true
      }
      Process {
        id: reloadAnimProc
        command: ["hyprctl", "reload"]
      }
    }
  }
}
