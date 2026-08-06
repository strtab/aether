pragma Singleton

import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import qs.modules.common
import qs.modules.common.models
import qs.modules.common.functions

Singleton {
  id: root

  property real scoreThreshold: 0.2

  property var builtinActions: [
    {
      action: Translation.tr("Dark theme"),
      verb: Translation.tr("Switch to dark theme"),
      iconName: "settings",
      iconType: LauncherSearchResult.IconType.System,
      execute: _ => {
        Quickshell.execDetached([Directories.wallpaperSwitchScriptPath, "--mode", "dark", "--noswitch"]);
      }
    },
    {
      action: Translation.tr("Light theme"),
      verb: Translation.tr("Switch to light theme"),
      iconName: "settings",
      iconType: LauncherSearchResult.IconType.System,
      execute: _ => {
        Quickshell.execDetached([Directories.wallpaperSwitchScriptPath, "--mode", "light", "--noswitch"]);
      }
    },
    {
      action: Translation.tr("Todo"),
      verb: Translation.tr("Add Task"),
      iconName: "checklist",
      iconType: LauncherSearchResult.IconType.Material,
      execute: args => {
        if (args !== "")
          Todo.addTask(args);
      }
    },
    {
      action: Translation.tr("Random Wallpaper"),
      verb: Translation.tr("Switch to random wallpaper"),
      iconName: "settings",
      iconType: LauncherSearchResult.IconType.System,
      execute: _ => {
        Wallpapers.randomFromCurrentFolder();
      }
    },
    {
      action: Translation.tr("Change Wallpaper"),
      verb: Translation.tr("Change Wallpaper"),
      iconName: "settings",
      iconType: LauncherSearchResult.IconType.System,
      execute: _ => {
        Quickshell.execDetached(["bash", "-c", Directories.wallpaperSwitchScriptPath]);
      }
    },
    {
      action: Translation.tr("Wipe Clipboard"),
      verb: Translation.tr("Clear Clipboard"),
      iconName: "delete_sweep",
      iconType: LauncherSearchResult.IconType.Material,
      execute: _ => {
        Cliphist.wipe();
      }
    },
    {
      action: Translation.tr("Super paste"),
      verb: Translation.tr("Paste item from clipboard"),
      iconName: "content_paste",
      iconType: LauncherSearchResult.IconType.Material,
      execute: args => {
        if (!/^(\d+)/.test(args.trim())) {
          Quickshell.execDetached(["notify-send", Translation.tr("Superpaste"), Translation.tr("Usage: <tt>%1superpaste NUM_OF_ENTRIES[i]</tt>\nSupply <tt>i</tt> when you want images\nExamples:\n<tt>%1superpaste 4i</tt> for the last 4 images\n<tt>%1superpaste 7</tt> for the last 7 entries").arg(Config.options.search.prefix.action), "-a", "Shell"]);
          return;
        }
        const m = /^(?:(\d+)(i)?)/.exec(args.trim());
        Cliphist.superpaste(m[1] ? parseInt(m[1]) : 1, !!m[2]);
      }
    }
  ]

  FolderListModel {
    id: userActionsFolder
    folder: Qt.resolvedUrl(Directories.userActions)
    showDirs: false
    showHidden: false
    sortField: FolderListModel.Name
  }

  property var userActions: {
    const actions = [];
    for (let i = 0; i < userActionsFolder.count; i++) {
      const fileName = userActionsFolder.get(i, "fileName");
      const filePath = userActionsFolder.get(i, "filePath");
      if (!fileName || !filePath)
        continue;
      const name = fileName.replace(/\.[^/.]+$/, "");
      const path = FileUtils.trimFileProtocol(filePath.toString());
      actions.push({
        action: name,
        iconName: "action_key",
        iconType: LauncherSearchResult.IconType.Material,
        execute: args => {
          Quickshell.execDetached([path, ...(args ? args.split(" ") : [])]);
        }
      });
    }
    return actions;
  }

  readonly property var allActions: builtinActions.concat(userActions)

  // Cached prepared names for fuzzy matching — rebuilt when allActions changes
  property var _cachedPrepped: []

  onAllActionsChanged: _rebuildCache()
  Component.onCompleted: _rebuildCache()

  function _rebuildCache(): void {
    _cachedPrepped = allActions.map((a, i) => ({
          name: Fuzzy.prepare(`${a.action} `),
          index: i
        }));
  }

  function fuzzyQuery(search: string): var {
    if (allActions.length === 0)
      return [];

    const searchLower = search.toLowerCase().trim();

    const fuzzyResults = Fuzzy.go(search, _cachedPrepped, {
      all: true,
      key: "name",
      threshold: -10000
    });

    const fuzzyIndices = new Set(fuzzyResults.map(r => r.obj.index));

    // Prefix matches that fuzzy threshold filtered out
    const prefixResults = _cachedPrepped.filter(p => {
      const n = allActions[p.index].action.toLowerCase();
      return !fuzzyIndices.has(p.index) && (searchLower.startsWith(n + " ") || searchLower === n);
    }).map(p => ({
          obj: p,
          score: 0
        }));

    return [...fuzzyResults, ...prefixResults].map(r => {
      const action = allActions[r.obj.index];
      const nameLower = action.action.toLowerCase();
      let score = r.score;

      if (nameLower.startsWith(searchLower))
        score += 50000;
      else if (searchLower.startsWith(nameLower + " ") || searchLower === nameLower)
        score += 45000;
      else if (nameLower.includes(" " + searchLower) || nameLower.includes("-" + searchLower))
        score += 20000;
      else if (nameLower.includes(searchLower))
        score += 10000;

      return {
        action,
        score
      };
    }).sort((a, b) => b.score - a.score).map(item => item.action);
  }

  // Prefix-aware match: returns actions whose name starts with or equals queryLower
  function prefixQuery(search: string): var {
    if (allActions.length === 0)
      return [];
    const q = search.toLowerCase();
    if (q === "")
      return allActions;
    return allActions.filter(a => {
      const n = a.action.toLowerCase();
      return n.startsWith(q) || q.startsWith(n) || q.includes(n) || n.includes(q);
    });
  }
}
