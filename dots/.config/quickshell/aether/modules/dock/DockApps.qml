pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.modules.common
import qs.services

/**
 * Dock data adapter (services/DockApps.qml).
 * - Pinned apps: full .desktop files in <shell config>/dock. They are parsed here, because
 *   DesktopEntries only scans the XDG data dirs.
 * - Running apps: ToplevelManager. Windows are matched to the pinned files; the rest are appended
 *   as running-only slots.
 * - Order of the pinned files: Config.options.dock.pinnedOrder (file names without .desktop).
 *   Files missing from that list go after the listed ones, sorted by name.
 * - Names, icons and desktop entries of running-only apps: AppSearch
 */
Singleton {
  id: root

  readonly property string killScript: Qt.resolvedUrl("../scripts/kill_app.sh").toString().replace(/^file:\/\//, "")

  // Directory with the pinned .desktop files
  readonly property string pinnedDir: `${Directories.shellConfig}/dock`
  // Executables that say nothing about the app when used as a match key
  readonly property var _genericExecs: ["bash", "sh", "env", "python", "python3", "java", "electron", "node", "flatpak", "snap", "gtk-launch", "xdg-open"]

  // Ordered ids shown in the dock, including slots that are still playing their leave animation.
  // Reassigned only when the list really changes.
  property var slotIds: []
  // Incrementally updated model for the Repeater. A plain array model would
  // recreate every delegate on change and kill the enter/leave animations.
  ListModel {
    id: _slotModel
  }
  property alias slotModel: _slotModel
  // Live data per id. Rebuilt on every change; delegates read it through itemFor().
  property var _byId: ({})
  // Parsed pinned .desktop files, keyed by file name without the suffix
  property var _files: ({})
  property int pinnedCount: 0
  // While true the model is frozen (a slot is being dragged)
  property bool dragging: false
  // Ids that are already gone but still shown while their slot plays the leave animation
  property var leavingIds: ({})
  // False during startup so the initial slots do not animate in
  property bool settled: false
  // How long the indicator dots fade out before a leaving slot starts to fade
  readonly property int dotsFadeDuration: 300

  readonly property var _emptyItem: ({
      appId: "",
      stem: "",
      rawId: "",
      pinned: false,
      running: false,
      toplevels: [],
      dotCount: 0,
      entry: null,
      file: "",
      exec: "",
      terminal: false,
      workingDirectory: "",
      actions: [],
      name: "",
      icon: ""
    })

  function itemFor(appId) {
    return root._byId[appId] ?? root._emptyItem;
  }

  function _friendlyName(id) {
    const seg = String(id).split(".").pop();
    return seg.charAt(0).toUpperCase() + seg.slice(1).replace(/[-_]/g, " ");
  }

  // ------------------------------------------------------- pinned files

  // Makes sure the directory exists before the folder model starts watching it
  Process {
    id: ensureDirProc
    command: ["mkdir", "-p", root.pinnedDir]
    running: true
    onExited: folderModel.folder = "file://" + root.pinnedDir
  }

  FolderListModel {
    id: folderModel
    nameFilters: ["*.desktop"]
    showDirs: false
    showFiles: true
    sortField: FolderListModel.Name
  }

  // One loader per file. Editing a file on disk is picked up live.
  Instantiator {
    model: folderModel
    delegate: FileView {
      id: loader
      required property string fileName
      required property string filePath
      readonly property string stem: loader.fileName.replace(/\.desktop$/, "")

      path: loader.filePath
      watchChanges: true
      onFileChanged: loader.reload()
      onLoaded: root._ingest(loader.stem, loader.filePath, loader.text())
    }
    onObjectRemoved: (index, object) => root._removeFile(object.stem)
  }

  function _ingest(stem, path, text) {
    const parsed = root._parseDesktopFile(stem, path, text);
    const next = Object.assign({}, root._files);
    if (parsed)
      next[stem] = parsed;
    else
      delete next[stem];
    root._files = next;
    root.scheduleRebuild();
  }

  function _removeFile(stem) {
    if (!(stem in root._files))
      return;
    const next = Object.assign({}, root._files);
    delete next[stem];
    root._files = next;
    root.scheduleRebuild();
  }

  function _localized(group, key) {
    if (!group)
      return "";
    const locale = Qt.locale().name;
    const lang = locale.split("_")[0];
    return group[`${key}[${locale}]`] ?? group[`${key}[${lang}]`] ?? group[key] ?? "";
  }

  // Resolves the escape sequences allowed in desktop entry string values
  function _unescape(str) {
    const map = {
      "s": " ",
      "n": "\n",
      "t": "\t",
      "r": "\r",
      "\\": "\\"
    };
    return String(str).replace(/\\(.)/g, (m, c) => map[c] ?? m);
  }

  function _parseDesktopFile(stem, path, text) {
    const groups = {};
    let current = null;
    for (const rawLine of String(text).split("\n")) {
      const line = rawLine.trim();
      if (line.length === 0 || line.startsWith("#"))
        continue;
      if (line.startsWith("[") && line.endsWith("]")) {
        current = line.slice(1, -1);
        if (!groups[current])
          groups[current] = {};
        continue;
      }
      const eq = line.indexOf("=");
      if (current === null || eq <= 0)
        continue;
      groups[current][line.slice(0, eq).trim()] = line.slice(eq + 1).trim();
    }

    const main = groups["Desktop Entry"];
    if (!main || (main["Type"] ?? "Application") !== "Application")
      return null;

    const actions = [];
    const actionIds = (main["Actions"] ?? "").split(";").map(s => s.trim()).filter(s => s.length > 0);
    for (const id of actionIds) {
      const group = groups[`Desktop Action ${id}`];
      if (!group || !group["Exec"])
        continue;
      const name = root._unescape(root._localized(group, "Name"));
      actions.push({
        "id": id,
        "name": name.length > 0 ? name : id,
        "exec": group["Exec"]
      });
    }

    return {
      "stem": stem,
      "path": path,
      "name": root._unescape(root._localized(main, "Name")),
      "icon": main["Icon"] ?? "",
      "exec": main["Exec"] ?? "",
      "terminal": (main["Terminal"] ?? "false") === "true",
      "workingDirectory": main["Path"] ?? "",
      "keys": root._matchKeys(stem, main),
      "actions": actions
    };
  }

  // Lowercase keys that identify the app of a window: file name, StartupWMClass, executable name
  function _matchKeys(stem, main) {
    const lowered = stem.toLowerCase();
    const keys = [lowered];
    const parts = lowered.split(".");
    if (parts.length > 1 && parts[parts.length - 1].length > 2)
      keys.push(parts[parts.length - 1]);
    const wmClass = (main["StartupWMClass"] ?? "").trim().toLowerCase();
    if (wmClass.length > 0)
      keys.push(wmClass);
    const argv = root._splitExec(main["Exec"] ?? "");
    if (argv.length > 0) {
      const base = argv[0].split("/").pop().toLowerCase();
      if (base.length > 0 && !root._genericExecs.includes(base))
        keys.push(base);
    }
    return keys.filter((k, i) => keys.indexOf(k) === i);
  }

  function _entryKey(entry) {
    return entry?.id ? String(entry.id).replace(/\.desktop$/, "").toLowerCase() : "";
  }

  // Pinned files in display order
  function _orderedPinned() {
    const out = [];
    const seen = {};
    for (const stem of root._pinnedOrder()) {
      const file = root._files[stem];
      if (file && !seen[stem]) {
        seen[stem] = true;
        out.push(file);
      }
    }
    for (const stem of Object.keys(root._files).sort()) {
      if (!seen[stem]) {
        seen[stem] = true;
        out.push(root._files[stem]);
      }
    }
    return out;
  }

  function _pinnedOrder() {
    return Array.from(Config.options?.dock?.pinnedOrder ?? []);
  }

  function _writeOrder(list) {
    Config.options.dock.pinnedOrder = list;
  }

  // ------------------------------------------------------------- items

  // id is the slot id; it is not always the file stem (see _carryOverId)
  function _makePinnedItem(id, file, toplevels) {
    const rawId = toplevels.length > 0 && toplevels[0].appId ? toplevels[0].appId : file.stem;
    return {
      appId: id,
      stem: file.stem,
      rawId: rawId,
      pinned: true,
      running: toplevels.length > 0,
      toplevels: toplevels,
      // Kept separately so a leaving slot can still show its dots while they fade out
      dotCount: toplevels.length,
      entry: null,
      file: file.path,
      exec: file.exec,
      terminal: file.terminal,
      workingDirectory: file.workingDirectory,
      actions: file.actions.map(a => ({
            id: a.id,
            name: a.name,
            exec: a.exec,
            native: null
          })),
      name: file.name.length > 0 ? file.name : root._friendlyName(file.stem),
      icon: AppSearch.resolveIcon(file.icon.length > 0 ? file.icon : AppSearch.guessIcon(file.stem), "application-x-executable")
    };
  }

  // id is the slot id; key is the lowercased window appId
  function _makeRunningItem(id, key, toplevels) {
    // Prefer the real window appId (keeps original casing) over the lowercased key
    const rawId = toplevels.length > 0 && toplevels[0].appId ? toplevels[0].appId : key;
    const entry = AppSearch.lookupDesktopEntry(rawId) ?? AppSearch.lookupDesktopEntry(key);
    return {
      appId: id,
      stem: "",
      rawId: rawId,
      pinned: false,
      running: toplevels.length > 0,
      toplevels: toplevels,
      dotCount: toplevels.length,
      entry: entry,
      file: "",
      exec: "",
      terminal: false,
      workingDirectory: "",
      actions: Array.from(entry?.actions ?? []).map(a => ({
            id: a.id,
            name: a.name,
            exec: "",
            native: a
          })),
      name: entry?.name ?? root._friendlyName(rawId),
      icon: AppSearch.resolveIcon(AppSearch.guessIcon(rawId), "application-x-executable")
    };
  }

  // The slot id is the key of the delegate, so a new id means a new slot (leave + enter animation).
  // To make pin and unpin only change the data of the existing slot, the id of the previous build
  // is reused:
  // - a pinned file keeps the id it already had (matched by the file stem);
  // - a pinned file that takes over the windows of a running-only slot reuses that slot id;
  // - a running-only group that takes over the windows of a just unpinned slot reuses that slot id.
  // stem is "" for a running-only group. Returns "" when there is nothing to reuse.
  function _carryOverId(stem, toplevels, used) {
    if (stem.length > 0) {
      for (const id of root.slotIds) {
        if (root.leavingIds[id] || used[id])
          continue;
        const old = root._byId[id];
        if (old && old.stem === stem)
          return id;
      }
    }
    if (toplevels.length === 0)
      return "";
    for (const id of root.slotIds) {
      if (root.leavingIds[id] || used[id])
        continue;
      const old = root._byId[id];
      if (!old || !old.toplevels.some(t => toplevels.includes(t)))
        continue;
      const wasRunningOnly = old.stem === "";
      const wasUnpinned = old.stem !== "" && !(old.stem in root._files);
      if (stem.length > 0 ? wasRunningOnly : wasUnpinned)
        return id;
    }
    return "";
  }

  function _uniqueId(id, used) {
    let result = id;
    while (used[result])
      result += "_";
    return result;
  }

  function rebuild() {
    if (root.dragging)
      return;

    const pinnedFiles = root._orderedPinned();

    // Every window goes to the first pinned file that matches it. Windows without a match are
    // grouped by their lowercased appId, in order of appearance.
    const windowsOf = Object.create(null);
    const extraGroups = [];
    const extraByKey = Object.create(null);
    for (const t of ToplevelManager.toplevels.values) {
      const rawAppId = String(t.appId ?? "");
      if (rawAppId.length === 0)
        continue;
      const key = rawAppId.toLowerCase();
      const entryKey = root._entryKey(AppSearch.lookupDesktopEntry(rawAppId));
      const owner = pinnedFiles.find(p => p.keys.includes(key) || (entryKey.length > 0 && p.keys.includes(entryKey)));
      if (owner) {
        if (!windowsOf[owner.stem])
          windowsOf[owner.stem] = [];
        windowsOf[owner.stem].push(t);
      } else {
        if (!extraByKey[key]) {
          extraByKey[key] = {
            "appId": key,
            "toplevels": []
          };
          extraGroups.push(extraByKey[key]);
        }
        extraByKey[key].toplevels.push(t);
      }
    }

    // Pinned apps first, in the saved order, then the running-only apps
    const byId = {};
    const ids = [];
    const used = Object.create(null);
    for (const file of pinnedFiles) {
      const toplevels = windowsOf[file.stem] ?? [];
      const id = root._uniqueId(root._carryOverId(file.stem, toplevels, used) || file.stem, used);
      used[id] = true;
      byId[id] = root._makePinnedItem(id, file, toplevels);
      ids.push(id);
    }
    for (const group of extraGroups) {
      const id = root._uniqueId(root._carryOverId("", group.toplevels, used) || group.appId, used);
      used[id] = true;
      byId[id] = root._makeRunningItem(id, group.appId, group.toplevels);
      ids.push(id);
    }
    const pinnedCount = pinnedFiles.length;

    // Keep removed ids at their old position so the slot can play its leave animation
    const old = root.slotIds;
    const result = ids.slice();
    const leaving = {};
    for (let i = 0; i < old.length; i++) {
      const id = old[i];
      if (ids.includes(id))
        continue;
      let at = 0;
      for (let j = i - 1; j >= 0; j--) {
        const p = result.indexOf(old[j]);
        if (p !== -1) {
          at = p + 1;
          break;
        }
      }
      result.splice(at, 0, id);
      leaving[id] = true;
      // Frozen copy of the last known data (name, icon, dot count) without live windows
      byId[id] = Object.assign({}, root._byId[id], {
        running: false,
        toplevels: []
      });
    }

    // Data first, then the id list, so new delegates see fresh data
    root._byId = byId;
    root.pinnedCount = pinnedCount;
    root.leavingIds = leaving;
    if (result.join("|") !== root.slotIds.join("|")) {
      root.slotIds = result;
      root._syncModel(result);
    }
    if (Object.keys(leaving).length > 0)
      purgeTimer.restart();
  }

  // Applies insert / remove / move operations so existing delegates survive
  function _syncModel(target) {
    for (let i = _slotModel.count - 1; i >= 0; i--) {
      if (!target.includes(_slotModel.get(i).appId))
        _slotModel.remove(i);
    }
    for (let i = 0; i < target.length; i++) {
      const id = target[i];
      if (i < _slotModel.count && _slotModel.get(i).appId === id)
        continue;
      let from = -1;
      for (let j = i + 1; j < _slotModel.count; j++) {
        if (_slotModel.get(j).appId === id) {
          from = j;
          break;
        }
      }
      if (from === -1)
        _slotModel.insert(i, {
          "appId": id
        });
      else
        _slotModel.move(from, i, 1);
    }
  }

  // Drops slots whose leave animation has finished
  function _purge() {
    if (root.dragging) {
      purgeTimer.restart();
      return;
    }
    const keep = root.slotIds.filter(id => !root.leavingIds[id]);
    root.leavingIds = {};
    root.slotIds = keep;
    root._syncModel(keep);
  }

  function scheduleRebuild() {
    rebuildTimer.restart();
  }

  onDraggingChanged: root.scheduleRebuild()

  Timer {
    id: rebuildTimer
    interval: 40
    repeat: false
    onTriggered: root.rebuild()
  }

  // Waits for the whole leave sequence of a slot: dots fade, icon fade, width collapse
  Timer {
    id: purgeTimer
    interval: root.dotsFadeDuration + Appearance.animation.elementMoveFast.duration * 2 + 80
    repeat: false
    onTriggered: root._purge()
  }

  Timer {
    id: settleTimer
    interval: 600
    repeat: false
    onTriggered: root.settled = true
  }

  Connections {
    target: ToplevelManager.toplevels
    function onValuesChanged() {
      root.scheduleRebuild();
    }
  }

  // A window can get its appId after it was created
  Instantiator {
    model: ToplevelManager.toplevels
    delegate: Connections {
      required property var modelData
      target: modelData
      function onAppIdChanged() {
        root.scheduleRebuild();
      }
    }
  }

  Connections {
    target: Config.options.dock
    function onPinnedOrderChanged() {
      root.scheduleRebuild();
    }
  }

  Connections {
    target: AppSearch
    function onListChanged() {
      root.scheduleRebuild();
    }
  }

  // ------------------------------------------------------------- pinning

  function isPinned(appId) {
    return root._byId[appId]?.pinned ?? false;
  }

  // Creates the .desktop file for a running-only app and returns its file name without the suffix.
  // The original file is copied from the XDG data dirs; when the app has none, a minimal file is
  // generated from the window class.
  readonly property string _pinScript: ['dir="$1"; stem="$2"; src="$3"; name="$4"; cmd="$5"; icon="$6"; wmclass="$7"', 'mkdir -p "$dir"', 'dest="$dir/$stem.desktop"', '[ -e "$dest" ] && exit 0', 'if [ -n "$src" ]; then', '  IFS=: read -ra dirs <<< "${XDG_DATA_HOME:-$HOME/.local/share}:${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"', '  for d in "${dirs[@]}"; do', '    if [ -f "$d/applications/$src.desktop" ]; then', '      cat "$d/applications/$src.desktop" > "$dest"', '      exit 0', '    fi', '  done', 'fi', '{', '  echo "[Desktop Entry]"', '  echo "Type=Application"', '  echo "Name=$name"', '  echo "Exec=$cmd"', '  [ -n "$icon" ] && echo "Icon=$icon"', '  [ -n "$wmclass" ] && echo "StartupWMClass=$wmclass"', '} > "$dest"'].join("\n")

  function _createPinFile(item) {
    const sourceId = item.entry?.id ? String(item.entry.id).replace(/\.desktop$/, "") : "";
    const stem = (sourceId || String(item.rawId || item.appId)).replace(/[^A-Za-z0-9._@+-]/g, "_");
    Quickshell.execDetached(["bash", "-c", root._pinScript, "dock-pin", root.pinnedDir, stem, sourceId, String(item.name), String(item.rawId), String(AppSearch.guessIcon(item.rawId)), String(item.rawId)]);
    return stem;
  }

  function pinApp(appId) {
    const item = root.itemFor(appId);
    if (item.appId === "" || item.pinned)
      return;
    const stem = root._createPinFile(item);
    root._writeOrder(root._orderedPinned().map(p => p.stem).concat([stem]));
  }

  function unpinApp(appId) {
    const item = root.itemFor(appId);
    if (!item.pinned)
      return;
    Quickshell.execDetached(["rm", "-f", item.file]);
    root._removeFile(item.stem);
    root._writeOrder(root._pinnedOrder().filter(s => s !== item.stem));
  }

  // Used by drag and drop: pins the app when it is only running and puts it at targetIndex of the
  // pinned list. The order is written first, the file may appear a moment later.
  function moveToPinnedIndex(appId, targetIndex) {
    const item = root.itemFor(appId);
    if (item.appId === "")
      return;
    const stem = item.pinned ? item.stem : root._createPinFile(item);
    const list = root._orderedPinned().map(p => p.stem).filter(s => s !== stem);
    list.splice(Math.max(0, Math.min(list.length, targetIndex)), 0, stem);
    root._writeOrder(list);
    root.rebuild();
  }

  // ------------------------------------------------------------- actions

  // Splits an Exec value into arguments. Double quotes group, a backslash inside quotes escapes.
  function _splitExec(str) {
    const args = [];
    let cur = "";
    let inQuote = false;
    let hasToken = false;
    for (let i = 0; i < str.length; i++) {
      const c = str[i];
      if (inQuote) {
        if (c === "\\" && i + 1 < str.length)
          cur += str[++i];
        else if (c === "\"")
          inQuote = false;
        else
          cur += c;
      } else if (c === "\"") {
        inQuote = true;
        hasToken = true;
      } else if (c === " " || c === "\t") {
        if (cur.length > 0 || hasToken) {
          args.push(cur);
          cur = "";
          hasToken = false;
        }
      } else {
        cur += c;
      }
    }
    if (cur.length > 0 || hasToken)
      args.push(cur);
    return args;
  }

  // Splits an Exec value and expands the field codes. Codes that need a file or an url are dropped.
  function _expandExec(exec, item) {
    const out = [];
    for (const arg of root._splitExec(exec)) {
      const expanded = arg.replace(/%%/g, "@@PERCENT@@").replace(/%c/g, () => item.name).replace(/%k/g, () => item.file ?? "").replace(/%[fFuUdDnNvmi]/g, "").replace(/@@PERCENT@@/g, "%");
      if (expanded.length === 0 && arg.length > 0)
        continue;
      out.push(expanded);
    }
    return out;
  }

  function _runExec(exec, item) {
    let command = root._expandExec(exec, item);
    if (command.length === 0)
      return;
    if (item.terminal)
      command = String(Config.options?.apps?.terminal ?? "kitty").split(/\s+/).concat(["-e"], command);
    const spec = {
      "command": command
    };
    if (item.workingDirectory)
      spec["workingDirectory"] = item.workingDirectory;
    Quickshell.execDetached(spec);
  }

  function launch(item) {
    if (item.exec) {
      root._runExec(item.exec, item);
      return;
    }
    const entry = item.entry ?? AppSearch.lookupDesktopEntry(item.rawId);
    if (entry)
      entry.execute();
    else if (item.rawId)
      Quickshell.execDetached([item.rawId]);
  }

  // Runs one of item.actions (a [Desktop Action] of a pinned file or of a system entry)
  function runAction(item, action) {
    if (action.native)
      action.native.execute();
    else
      root._runExec(action.exec, item);
  }

  // Focuses the app; cycles through its windows when it has several
  function focus(item) {
    const list = item?.toplevels ?? [];
    if (list.length === 0)
      return;
    const current = list.findIndex(t => t.activated);
    list[(current + 1) % list.length].activate();
  }

  function quit(item) {
    for (const t of (item?.toplevels ?? []))
      t.close();
  }

  function forceKill(item) {
    if (!item)
      return;
    const ids = [item.rawId, item.appId];
    for (const t of item.toplevels)
      ids.push(t.appId);
    const unique = ids.filter((id, i) => id && ids.indexOf(id) === i);
    _killProc.command = ["bash", root.killScript].concat(unique);
    _killProc.running = true;
  }

  Process {
    id: _killProc
    running: false
    stdout: StdioCollector {}
  }

  // Finds the dock item that a window class or a notification app name belongs to
  function _matchItem(needle) {
    const n = String(needle ?? "").toLowerCase();
    if (n.length === 0)
      return null;
    for (const id of root.slotIds) {
      if (root.leavingIds[id])
        continue;
      const item = root._byId[id];
      const keys = [item.appId, item.stem, item.rawId, item.name, item.entry?.id ?? ""].map(k => String(k).toLowerCase().replace(/\.desktop$/, "")).filter(k => k.length > 2);
      if (keys.some(k => n.includes(k) || k.includes(n)))
        return item;
    }
    return null;
  }

  Component.onCompleted: {
    root.rebuild();
    settleTimer.start();
  }
}
