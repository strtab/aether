pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common.functions

Singleton {
  id: root
  property string filePath: Directories.shellConfigPath
  property alias options: configOptionsJsonAdapter
  property bool ready: false
  property int readWriteDelay: 50 // milliseconds
  property bool blockWrites: false

  function setNestedValue(nestedKey, value) {
    let keys = nestedKey.split(".");
    let obj = root.options;
    let parents = [obj];

    // Traverse and collect parent objects
    for (let i = 0; i < keys.length - 1; ++i) {
      if (!obj[keys[i]] || typeof obj[keys[i]] !== "object") {
        obj[keys[i]] = {};
      }
      obj = obj[keys[i]];
      parents.push(obj);
    }

    // Convert value to correct type using JSON.parse when safe
    let convertedValue = value;
    if (typeof value === "string") {
      let trimmed = value.trim();
      if (trimmed === "true" || trimmed === "false" || !isNaN(Number(trimmed))) {
        try {
          convertedValue = JSON.parse(trimmed);
        } catch (e) {
          convertedValue = value;
        }
      }
    }

    obj[keys[keys.length - 1]] = convertedValue;
  }

  Timer {
    id: fileReloadTimer
    interval: root.readWriteDelay
    repeat: false
    onTriggered: {
      configFileView.reload();
    }
  }

  Timer {
    id: fileWriteTimer
    interval: root.readWriteDelay
    repeat: false
    onTriggered: {
      configFileView.writeAdapter();
    }
  }

  FileView {
    id: configFileView
    path: root.filePath
    watchChanges: true
    blockWrites: root.blockWrites
    onFileChanged: fileReloadTimer.restart()
    onAdapterUpdated: fileWriteTimer.restart()
    onLoaded: root.ready = true
    onLoadFailed: error => {
      if (error == FileViewError.FileNotFound) {
        writeAdapter();
      }
    }

    JsonAdapter {
      id: configOptionsJsonAdapter

      property string panelFamily: "aether"

      property JsonObject policies: JsonObject {
        property int weeb: 0 // 0: No | 1: Open | 2: Closet
      }

      property JsonObject appearance: JsonObject {
        property bool extraBackgroundTint: true
        property int fakeScreenRounding: 1 // 0: None | 1: Always | 2: When not fullscreen
        property JsonObject typography: JsonObject {
          property string main: "Google Sans Flex"
          property string numbers: "Google Sans 17pt Medium"
          property string title: "Google Sans 17pt SemiBold"
          property string iconNerd: "JetBrains Mono NF"
          property string monospace: "JetBrains Mono NF"
          property string reading: "Readex Pro"
          property string expressive: "Google Sans Flex 120pt Medium"
          property real sizeScale: 1.0
          property bool syncWithSystem: true // Sync fonts with GTK/KDE apps
          property JsonObject variableAxes: JsonObject {
            property int wght: 300
            property int wdth: 105
            property int grad: 175
          }
        }
        property JsonObject transparency: JsonObject {
          property bool enable: false
          property bool automatic: true
          property real backgroundTransparency: 0.11
          property real contentTransparency: 0.57
        }
        property JsonObject wallpaperTheming: JsonObject {
          property bool enableAppsAndShell: true
          property bool enableQtApps: true
          property bool enableTerminal: true
          property JsonObject terminalGenerationProps: JsonObject {
            property real harmony: 0.6
            property real harmonizeThreshold: 100
            property real termFgBoost: 0.35
            property bool forceDarkMode: false
          }
        }
        property JsonObject palette: JsonObject {
          property string type: "scheme-neutral" // Allowed: auto, scheme-content, scheme-expressive, scheme-fidelity, scheme-fruit-salad, scheme-monochrome, scheme-neutral, scheme-rainbow, scheme-tonal-spot
          property string accentColor: ""
        }
      }

      property JsonObject audio: JsonObject {
        // Values in %
        property JsonObject protection: JsonObject {
          // Prevent sudden bangs
          property bool enable: false
          property real maxAllowedIncrease: 10
          property real maxAllowed: 99
        }
      }

      property JsonObject apps: JsonObject {
        property string bluetooth: "kcmshell6 kcm_bluetooth"
        property string changePassword: "kitty sh -i -c 'passwd'"
        property string network: "kcmshell6 kcm_networkmanagement"
        property string manageUser: "kcmshell6 kcm_users"
        property string networkEthernet: "kcmshell6 kcm_networkmanagement"
        property string taskManager: "plasma-systemmonitor --page-name Processes"
        property string terminal: "kitty" // This is only for shell actions
        property string volumeMixer: `~/.config/hypr/hyprland/scripts/launch_first_available.sh "pavucontrol-qt" "pavucontrol"`
      }

      property JsonObject hyprland: JsonObject {
        property JsonObject animations: JsonObject {
          property string animation: "normal"
          property bool enable: true
        }
        property JsonObject autostartApps: JsonObject {
          property bool enable: false
          property list<var> apps: []
        }
        property JsonObject decoration: JsonObject {
          property int rounding: 25
          property real activeOpacity: 1.0
          property real inactiveOpacity: 1.0
          property JsonObject blur: JsonObject {
            property bool enabled: true
            property int size: 1
            property int passes: 3
          }
          property JsonObject shadow: JsonObject {
            property bool enabled: true
            property int range: 4
          }
        }
        property JsonObject general: JsonObject {
          property int borderSize: 1
          property int gapsIn: 2
          property int gapsOut: 5
          property string layout: "dwindle"
        }
        property JsonObject input: JsonObject {
          property string kbLayout: "us"
          property bool numlock: true
          property int repeatDelay: 250
          property int repeatRate: 35
          property int followMouse: 1
          property JsonObject touchpad: JsonObject {
            property bool naturalScroll: false
            property bool disableWhileTyping: true
            property bool clickfingerBehavior: false
            property real scrollFactor: 0.7
          }
        }
      }

      property JsonObject background: JsonObject {
        property bool enable: true
        property JsonObject widgets: JsonObject {
          property JsonObject clock: JsonObject {
            property bool enable: true
            property bool showOnlyWhenLocked: false
            property string placementStrategy: "leastBusy" // "free", "leastBusy", "mostBusy"
            property real x: 100
            property real y: 100
            property string style: "cookie"        // Options: "cookie", "digital"
            property string styleLocked: "digital"  // Options: "cookie", "digital"
            property JsonObject cookie: JsonObject {
              property int sides: 14
              property string dialNumberStyle: "full"   // Options: "dots" , "numbers", "full" , "none"
              property string hourHandStyle: "fill"     // Options: "classic", "fill", "hollow", "hide"
              property string minuteHandStyle: "medium" // Options: "classic", "thin", "medium", "bold", "hide"
              property string secondHandStyle: "dot"    // Options: "dot", "line", "classic", "hide"
              property string dateStyle: "hide"         // Options: "border", "rect", "bubble" , "hide"
              property bool timeIndicators: true
              property bool hourMarks: false
              property bool dateInClock: true
              property bool constantlyRotate: false
              property bool useSineCookie: false
            }
            property JsonObject digital: JsonObject {
              property bool adaptiveAlignment: true
              property bool showDate: true
              property bool animateChange: true
              property bool vertical: false
              property JsonObject font: JsonObject {
                property string family: "Google Sans Flex"
                property real weight: 855
                property real size: 100
                property real width: 105
                property real roundness: 85
              }
            }
            property JsonObject quote: JsonObject {
              property bool enable: false
              property string text: ""
            }
          }
          property JsonObject weather: JsonObject {
            property bool enable: false
            property string placementStrategy: "free" // "free", "leastBusy", "mostBusy"
            property real x: 400
            property real y: 100
          }
        }
        property string wallpaperPath: FileUtils.trimFileProtocol(`${Directories.assetsPath}/images/default_wallpaper.jpg`)
        property string thumbnailPath: ""
        property bool hideWhenFullscreen: true
        property JsonObject parallax: JsonObject {
          property bool vertical: false
          property bool autoVertical: false
          property bool enableWorkspace: true
          property real workspaceZoom: 1.07 // Relative to your screen, not wallpaper size
          property bool enableSidebar: true
          property real widgetsFactor: 1.2
        }
      }

      property JsonObject bar: JsonObject {
        property bool enable: true
        property list<string> screenList: [] // List of names, like "eDP-1", find out with 'hyprctl monitors' command
        property int cornerStyle: 0 // 0: Hug | 1: Float | 2: Plain rectangle
        property bool floatStyleShadow: true // Show shadow behind bar when cornerStyle == 1 (Float)
        property JsonObject autoHide: JsonObject {
          property bool enable: false
          property int hoverRegionWidth: 2
          property bool pushWindows: false
          property JsonObject showWhenPressingSuper: JsonObject {
            property bool enable: true
            property int delay: 140
          }
        }
        property JsonObject foreground: JsonObject {
          property int style: 1 // 0: Auto color | 1: Plain color
          property color color: "#000000"
        }
        property JsonObject background: JsonObject {
          property bool enable: false
          property int style: 0 // 0: Auto color | 1: Plain color | 2: Transparent
          property color color: "#000000"
        }
        property JsonObject resources: JsonObject {
          property bool alwaysShowSwap: true
          property bool alwaysShowCpu: true
          property int memoryWarningThreshold: 95
          property int swapWarningThreshold: 85
          property int cpuWarningThreshold: 90
        }
        property JsonObject workspaces: JsonObject {
          property bool enable: false
          property bool monochromeIcons: true
          property int shown: 4
          property bool showAppIcons: true
          property bool alwaysShowNumbers: false
          property int showNumberDelay: 300 // milliseconds
          property list<string> numberMap: ["1", "2"] // Characters to show instead of numbers on workspace indicator
          property bool useNerdFont: false
        }
        property JsonObject weather: JsonObject {
          property bool enableGPS: true // gps based location
          property string city: "" // When 'enableGPS' is false
          property bool useUSCS: false // Instead of metric (SI) units
          property int fetchInterval: 10 // minutes
        }
        property JsonObject clock: JsonObject {
          property bool enable: true
          property bool showDate: true
        }
        property JsonObject indicators: JsonObject {
          property JsonObject notifications: JsonObject {
            property bool showUnreadCount: false
          }
        }
      }

      property JsonObject battery: JsonObject {
        property int low: 20
        property int critical: 5
        property int full: 101
        property bool automaticSuspend: true
        property int suspend: 3
      }

      property JsonObject calendar: JsonObject {
        property string locale: "en-GB"
      }

      property JsonObject cheatsheet: JsonObject {
        property string superKey: "󰘳"
        property bool useMacSymbol: true
        property bool useMouseSymbol: false
        property bool useFnSymbol: false
        property JsonObject fontSize: JsonObject {
          property int key: Appearance.font.pixelSize.large
          property int comment: Appearance.font.pixelSize.large
        }
      }

      property JsonObject conflictKiller: JsonObject {
        property bool autoKillNotificationDaemons: true
        property bool autoKillTrays: true
      }

      property JsonObject dock: JsonObject {
        property bool enable: true
        property bool monochromeIcons: true
        property bool showPinButton: false
        property bool showOverviewButton: false
        property real iconSize: 65
        property real hoverRegionHeight: 2
        property JsonObject dots: JsonObject {
          property int maxCount: 5
          property real widthFocused: 6
          property real widthInactive: 6
          property real height: 6
        }
        property bool showPreview: true
        property bool pinnedOnStartup: true
        property bool hoverToReveal: true // When false, only reveals on empty workspace
        property list<string> pinnedApps: [ // IDs of pinned entries
          "zen", "kitty", "obsidian", "anki", "thunderbird", "org.telegram.desktop", "org.kde.dolphin", "org.kde.kinfocenter", "ONLYOFFICE"]
        property list<string> ignoredAppRegexes: []
      }

      property JsonObject interactions: JsonObject {
        property JsonObject scrolling: JsonObject {
          property bool fasterTouchpadScroll: false // Enable faster scrolling with touchpad
          property int mouseScrollDeltaThreshold: 120 // delta >= this then it gets detected as mouse scroll rather than touchpad
          property int mouseScrollFactor: 120
          property int touchpadScrollFactor: 450
        }
        property JsonObject deadPixelWorkaround: JsonObject { // Hyprland leaves out 1 pixel on the right for interactions
          property bool enable: false
        }
      }

      property JsonObject language: JsonObject {
        property string ui: "auto" // UI language. "auto" for system locale, or specific language code like "zh_CN", "en_US"
        property JsonObject translator: JsonObject {
          property string engine: "auto" // Run `trans -list-engines` for available engines. auto should use google
          property string targetLanguage: "auto" // Run `trans -list-all` for available languages
          property string sourceLanguage: "auto"
        }
      }

      property JsonObject launcher: JsonObject {
        property list<string> pinnedApps: ["org.kde.dolphin", "alacritty", "cmake-gui"]
      }

      property JsonObject light: JsonObject {
        property JsonObject night: JsonObject {
          property bool automatic: true
          property string from: "19:00" // Format: "HH:mm", 24-hour time
          property string to: "08:30"   // Format: "HH:mm", 24-hour time
          property int colorTemperature: 5000
        }
        property JsonObject antiFlashbang: JsonObject {
          property bool enable: false
        }
      }

      property JsonObject lock: JsonObject {
        property bool useHyprlock: false
        property bool launchOnStartup: false
        property JsonObject blur: JsonObject {
          property bool enable: true
          property real radius: 100
          property real extraZoom: 1.1
        }
        property bool centerClock: true
        property bool showLockedText: true
        property JsonObject security: JsonObject {
          property bool unlockKeyring: true
          property bool requirePasswordToPower: false
        }
        property bool materialShapeChars: true
      }

      property JsonObject media: JsonObject {
        // Attempt to remove dupes (the aggregator playerctl one and browsers' native ones when there's plasma browser integration)
        property bool filterDuplicatePlayers: true
      }

      property JsonObject networking: JsonObject {
        property string userAgent: "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36"
      }

      property JsonObject notifications: JsonObject {
        property int timeout: 7000
      }

      property JsonObject osd: JsonObject {
        property int timeout: 1000
      }

      property JsonObject osk: JsonObject {
        property string layout: "qwerty_full"
        property bool pinnedOnStartup: false
      }

      property JsonObject overview: JsonObject {
        property bool enable: true
        property real scale: 0.18 // Relative to screen size
        property real rows: 2
        property real columns: 5
        property bool orderRightLeft: false
        property bool orderBottomUp: false
        property bool centerIcons: true
      }

      property JsonObject regionSelector: JsonObject {
        property JsonObject targetRegions: JsonObject {
          property bool windows: true
          property bool layers: false
          property bool content: true
          property bool showLabel: false
          property real opacity: 0.3
          property real contentRegionOpacity: 0.8
          property int selectionPadding: 5
        }
        property JsonObject rect: JsonObject {
          property bool showAimLines: true
        }
        property JsonObject circle: JsonObject {
          property int strokeWidth: 6
          property int padding: 10
        }
        property JsonObject annotation: JsonObject {
          property bool useSatty: false
        }
      }

      property JsonObject resources: JsonObject {
        property bool enabled: true
        property int updateInterval: 3000
        property int historyLength: 60
      }

      property JsonObject tray: JsonObject {
        property bool monochromeIcons: true
        property bool showItemId: false
        property bool invertPinnedItems: true // Makes the below a whitelist for the tray and blacklist for the pinned area
        property list<var> pinnedItems: ["Fcitx"]
        property bool filterPassive: true
      }

      property JsonObject musicRecognition: JsonObject {
        property int timeout: 16
        property int interval: 4
      }

      property JsonObject search: JsonObject {
        property bool enable: true
        property bool collapsed: false
        property int fontSize: 20
        property int nonAppResultDelay: 30 // This prevents lagging when typing
        property string engineBaseUrl: "https://www.google.com/search?q="
        property int clipboardMaxResults: 40
        property bool sloppy: false // Uses levenshtein distance based scoring instead of fuzzy sort. Very weird.
        property bool contentAnimation: true
        property list<var> blacklist: ["SongRec", "MenuEditor", "Menu Editor", "Bluetooth Adapters", "KDE System Settings", "System Settings", "Gvim", "Qt6 Settings"]
        property JsonObject autocomplete: JsonObject {
          property bool enable: true
          property bool showBorder: false
          property bool showBackground: true
        }
        property JsonObject prefix: JsonObject {
          property bool showDefaultActionsWithoutPrefix: true
          property string action: ":"
          property string app: ">"
          property string clipboard: "\""
          property string math: "="
          property string shellCommand: "$"
          property string webSearch: "?"
        }
        property JsonObject imageSearch: JsonObject {
          property string imageSearchEngineBaseUrl: "https://lens.google.com/uploadbyurl?url="
          property bool useCircleSelection: false
        }
      }

      property JsonObject sidebar: JsonObject {
        property bool keepRightSidebarLoaded: true
        property JsonObject translator: JsonObject {
          property bool enable: false
          property int delay: 300 // Delay before sending request. Reduces (potential) rate limits and lag.
        }

        property JsonObject quickToggles: JsonObject {
          property string style: "android" // Options: classic, android
          property JsonObject android: JsonObject {
            property int columns: 5
            property list<var> toggles: [
              {
                "size": 2,
                "type": "network"
              },
              {
                "size": 2,
                "type": "bluetooth"
              },
              {
                "size": 1,
                "type": "idleInhibitor"
              },
              {
                "size": 1,
                "type": "mic"
              },
              {
                "size": 2,
                "type": "audio"
              },
              {
                "size": 2,
                "type": "nightLight"
              }
            ]
          }
        }

        property JsonObject quickSliders: JsonObject {
          property bool enable: false
          property bool showMic: false
          property bool showVolume: true
          property bool showBrightness: true
        }
      }

      property JsonObject screenRecord: JsonObject {
        property string savePath: Directories.videos.replace("file://", "") // strip "file://"
      }

      property JsonObject screenSnip: JsonObject {
        property string savePath: "" // only copy to clipboard when empty
      }

      property JsonObject sounds: JsonObject {
        property bool battery: true
        property bool pomodoro: true
        property bool notifications: true
        property string theme: "ocean"
      }

      property JsonObject time: JsonObject {
        // https://doc.qt.io/qt-6/qtime.html#toString
        property string format: "hh:mm"
        property string shortDateFormat: "dd/MM"
        property string dateWithYearFormat: "dd/MM/yyyy"
        property string dateFormat: "ddd MMM dd"
        property JsonObject pomodoro: JsonObject {
          property int breakTime: 300
          property int cyclesBeforeLongBreak: 4
          property int focus: 1500
          property int longBreak: 900
        }
        property bool secondPrecision: false
      }

      property JsonObject wallpaperSelector: JsonObject {
        property bool useSystemFileDialog: false
      }

      property JsonObject windows: JsonObject {
        property bool showTitlebar: false // Client-side decoration for shell apps
        property bool centerTitle: true
      }

      property JsonObject hacks: JsonObject {
        property int arbitraryRaceConditionDelay: 20 // milliseconds
      }

      property JsonObject workSafety: JsonObject {
        property JsonObject enable: JsonObject {
          property bool wallpaper: false
          property bool clipboard: false
        }
        property JsonObject triggerCondition: JsonObject {
          property list<string> networkNameKeywords: ["airport", "cafe", "college", "company", "eduroam", "free", "guest", "public", "school", "university"]
          property list<string> fileKeywords: ["anime", "booru", "ecchi", "hentai", "yande.re", "konachan", "breast", "nipples", "pussy", "nsfw", "spoiler", "girl"]
          property list<string> linkKeywords: ["hentai", "porn", "sukebei", "hitomi.la", "rule34", "gelbooru", "fanbox", "dlsite"]
        }
      }
    }
  }
}
