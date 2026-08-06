pragma Singleton

import qs.services
import qs.modules.common
import qs.modules.common.models
import qs.modules.common.functions
import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Singleton {
  id: root

  property string query: ""
  property string mode: ""
  property int selectedIndex: 0
  property string mathResult: ""
  property string typeResult: ""
  property bool commandExsists: false

  property list<string> mainRegisteredCategories: ["AudioVideo", "Development", "Education", "Game", "Graphics", "Network", "Office", "Science", "Settings", "System", "Utility"]
  property list<string> appCategories: Array.from(AppSearch.list.reduce((acc, entry) => {
    for (const cat of entry.categories)
      if (mainRegisteredCategories.includes(cat))
        acc.add(cat);
    return acc;
  }, new Set())).sort()

  property bool clipboardWorkSafetyActive: {
    const enabled = Config.options.workSafety.enable.clipboard;
    const sensitiveNetwork = StringUtils.stringListContainsSubstring(Network.networkName.toLowerCase(), Config.options.workSafety.triggerCondition.networkNameKeywords);
    return enabled && sensitiveNetwork;
  }

  function containsUnsafeLink(entry) {
    if (entry == undefined)
      return false;
    return StringUtils.stringListContainsSubstring(entry.toLowerCase(), Config.options.workSafety.triggerCondition.linkKeywords);
  }

  // Defined at singleton level — not recreated on every results recompute
  function makeAppResult(entry) {
    return resultComp.createObject(null, {
      type: Translation.tr("App"),
      id: entry.id ?? "",
      name: entry.name ?? "",
      iconName: entry.icon ?? "",
      iconType: LauncherSearchResult.IconType.System,
      verb: Translation.tr("Open"),
      execute: () => {
        if (!entry.runInTerminal)
          entry.execute();
        else {
          // Probably needs more proper escaping, but this will do for now
          Quickshell.execDetached(["bash", '-c', `${Config.options.apps.terminal} -e '${StringUtils.shellSingleQuoteEscape(entry.command.join(' '))}'`]);
        }
      },
      comment: entry.comment ?? "",
      runInTerminal: entry.runInTerminal ?? false,
      genericName: entry.genericName ?? "",
      keywords: entry.keywords ?? "",
      actions: (entry.actions ?? []).map(action => {
        return resultComp.createObject(null, {
          name: action.name ?? "",
          iconName: action.icon ?? "",
          iconType: LauncherSearchResult.IconType.System,
          execute: () => {
            if (!action.runInTerminal)
              action.execute();
            else {
              Quickshell.execDetached(["bash", '-c', `${Config.options.apps.terminal} -e '${StringUtils.shellSingleQuoteEscape(action.command.join(' '))}'`]);
            }
          }
        });
      })
    });
  }

  function makeActionResult(entry) {
    return resultComp.createObject(null, {
      name: entry.action,
      verb: entry.verb ?? Translation.tr("Run"),
      type: Translation.tr("Action"),
      comment: entry.comment ?? entry.verb ?? Translation.tr("Run"),
      iconName: entry.iconName ?? 'action_key',
      iconType: entry.iconType ?? LauncherSearchResult.IconType.Material,
      execute: () => {
        entry.execute(root.query.split(" ").slice(1).join(" "));
      }
    });
  }

  // Timer restart moved out of results binding to avoid side effects on every recompute
  function _maybeRestartNonAppTimer() {
    if (root.query === "" && root.mode === "") {
      nonAppResultsTimer.stop();
      return;
    }
    const p = Config.options.search.prefix;
    const skip = root.mode === p.clipboard || root.mode === p.webSearch || root.mode === p.app;
    skip ? nonAppResultsTimer.stop() : nonAppResultsTimer.restart();
  }

  onQueryChanged: _maybeRestartNonAppTimer()
  onModeChanged: _maybeRestartNonAppTimer()

  // Plain JS object — mutating its fields does not trigger QML dependency tracking
  QtObject {
    id: internal
    property var store: ({
        prevResults: []
      })
  }

  property list<var> results: {
    if (root.query === "" && root.mode === "")
      return [];
    // Copy before async destroy so the reference is stable in the closure
    const prev = [...internal.store.prevResults];
    Qt.callLater(() => {
      for (const o of prev)
        if (o)
          o.destroy();
    });
    const built = root._buildResults();
    // Mutate the JS object — no QML property write, no binding loop
    internal.store.prevResults = built;
    return built;
  }

  function _buildResults() {
    const p = Config.options.search.prefix;
    const startsWithNumber = /^\d/.test(root.query);
    const mathMode = root.mode === p.math;
    const appMode = root.mode === p.app;
    const shellMode = root.mode === p.shellCommand;
    const webMode = root.mode === p.webSearch;
    const clipMode = root.mode === p.clipboard;
    const actionMode = root.mode === p.action;
    const showFallbacks = p.showDefaultActionsWithoutPrefix;

    if (clipMode) {
      return Cliphist.fuzzyQuery(root.query).slice(0, Config.options.search.clipboardMaxResults ?? 30).map((entry, i, arr) => {
        const mightBlur = Cliphist.entryIsImage(entry) && root.clipboardWorkSafetyActive;
        const shouldBlur = mightBlur && (root.containsUnsafeLink(arr[i - 1]) || root.containsUnsafeLink(arr[i + 1]));
        return resultComp.createObject(null, {
          rawValue: entry,
          name: StringUtils.cleanCliphistEntry(entry),
          verb: Translation.tr("Copy"),
          comment: `#${entry.match(/^\s*(\S+)/)?.[1] || ""}`,
          execute: () => Cliphist.copy(entry),
          // Item actions
          actions: [resultComp.createObject(null, {
              name: Translation.tr("Copy"),
              iconName: "content_copy",
              iconType: LauncherSearchResult.IconType.Material,
              execute: () => Cliphist.copy(entry)
            }), resultComp.createObject(null, {
              name: Translation.tr("Delete"),
              iconName: "delete",
              iconType: LauncherSearchResult.IconType.Material,
              execute: () => Cliphist.deleteEntry(entry)
            })],
          blurImage: shouldBlur
        });
      }).filter(Boolean);
    }

    if (mathMode) {
      return [resultComp.createObject(null, {
          name: root.query === "" ? "0" : root.mathResult,
          verb: Translation.tr("Copy"),
          comment: Translation.tr("Math result"),
          type: Translation.tr("Math result"),
          fontType: LauncherSearchResult.FontType.Monospace,
          iconType: LauncherSearchResult.IconType.None,
          execute: () => {
            Quickshell.clipboardText = root.mathResult;
          }
        })];
    }

    if (appMode) {
      return AppSearch.fuzzyQuery(root.query).map(e => makeAppResult(e));
    }

    if (actionMode) {
      return ActionSearch.fuzzyQuery(root.query).map(e => makeActionResult(e));
    }

    if (shellMode) {
      return [resultComp.createObject(null, {
          name: root.query ?? "",
          verb: root.commandExsists ? Translation.tr("Run") : "",
          type: Translation.tr("Shell Command"),
          comment: root.query === "" ? "Command Path" : root.commandExsists ? root.typeResult : Translation.tr("Command Not Found"),
          fontType: LauncherSearchResult.FontType.Monospace,
          iconType: LauncherSearchResult.IconType.None,
          execute: () => {
            Quickshell.execDetached(["sh", "-c", root.query.startsWith("sudo") ? `${Config.options.apps.terminal} '${root.query}'` : root.query]);
          }
        })];
    }

    if (webMode) {
      return [resultComp.createObject(null, {
          name: root.query,
          verb: Translation.tr("Search"),
          type: Translation.tr("Web search"),
          comment: Translation.tr("Search the Web"),
          iconName: 'travel_explore',
          iconType: LauncherSearchResult.IconType.Material,
          execute: () => {
            Qt.openUrlExternally(p.engineBaseUrl + root.query);
          }
        })];
    }

    // Default mode
    let result = [];

    if (startsWithNumber) {
      result.push(resultComp.createObject(null, {
        name: root.mathResult,
        verb: Translation.tr("Copy"),
        type: Translation.tr("Math result"),
        comment: Translation.tr("Math result"),
        fontType: LauncherSearchResult.FontType.Monospace,
        iconName: 'calculate',
        iconType: LauncherSearchResult.IconType.Material,
        execute: () => {
          Quickshell.clipboardText = root.mathResult;
        }
      }));
    }

    result = result.concat(AppSearch.fuzzyQuery(root.query).map(e => makeAppResult(e))); // Apps
    result = result.concat(ActionSearch.fuzzyQuery(root.query).map(e => makeActionResult(e))); // Actions

    if (showFallbacks) {
      if (!startsWithNumber && root.commandExsists) {
        result.push(resultComp.createObject(null, {
          name: root.query,
          verb: Translation.tr("Run"),
          type: Translation.tr("Shell Command"),
          comment: root.typeResult,
          fontType: LauncherSearchResult.FontType.Monospace,
          iconName: 'terminal',
          iconType: LauncherSearchResult.IconType.Material,
          execute: () => {
            Quickshell.execDetached(["sh", "-c", root.query.startsWith("sudo") ? `${Config.options.apps.terminal} '${root.query}'` : root.query]);
          }
        }));
      }
      if (!webMode) {
        result.push(resultComp.createObject(null, {
          name: root.query,
          verb: Translation.tr("Search"),
          type: Translation.tr("Web search"),
          comment: Translation.tr("Search the Web"),
          iconName: 'travel_explore',
          iconType: LauncherSearchResult.IconType.Material,
          execute: () => {
            Qt.openUrlExternally(Config.options.search.engineBaseUrl + root.query);
          }
        }));
      }
    }

    return result;
  }

  Timer {
    id: nonAppResultsTimer
    interval: Config.options.search.nonAppResultDelay
    onTriggered: {
      const p = Config.options.search.prefix;
      const startsWithNumber = /^\d/.test(root.query);
      if (root.mode === p.math || startsWithNumber)
        mathProc.calculateExpression(root.query);
      // Skip type lookup for modes that don't need it
      if (root.query !== "" && root.mode !== p.clipboard && root.mode !== p.math && root.mode !== p.webSearch)
        typeProc.searchExpression(root.query.split(" ")[0]);
    }
  }

  Process {
    id: mathProc
    property list<string> baseCommand: ["qalc", "-t"]
    function calculateExpression(expression) {
      mathProc.running = false;
      mathProc.command = baseCommand.concat(expression);
      mathProc.running = true;
    }
    stdout: SplitParser {
      onRead: data => {
        console.info(data);
        root.mathResult = data;
      }
    }
  }

  Process {
    id: typeProc
    function searchExpression(expression) {
      typeProc.running = false;
      typeProc.command = ["sh", "-c", `type ${expression}`];
      typeProc.running = true;
    }
    stdout: SplitParser {
      onRead: data => root.typeResult = data.trim()
    }
    onExited: (code, status) => {
      root.commandExsists = (code === 0);
    }
  }

  Component {
    id: resultComp
    LauncherSearchResult {}
  }
}
