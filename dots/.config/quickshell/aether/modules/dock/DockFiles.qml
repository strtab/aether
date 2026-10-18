pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import qs.modules.common
import qs.services

/**
 * Data adapter for the file section of the dock (services/DockFiles.qml).
 * - Items: files and directories listed in Config.options.dock.files.items, in that order.
 *   Dropping files on the dock appends their paths to the list. Removing an item from the dock
 *   only removes the path from the list, the file itself is never touched.
 *   Paths that do not exist are not shown, but stay in the list.
 * - Trash: the XDG trash directory. Used for the full/empty icon and for the trash actions.
 */
Singleton {
  id: root

  readonly property bool enabled: Config.options?.dock?.files?.enable ?? true
  readonly property bool trashEnabled: root.enabled && (Config.options?.dock?.files?.showTrash ?? true)
  readonly property bool showPreviews: Config.options?.dock?.files?.showPreviews ?? true

  readonly property string dataHome: Quickshell.env("XDG_DATA_HOME") || `${Quickshell.env("HOME")}/.local/share`
  readonly property string trashRoot: `${root.dataHome}/Trash`
  readonly property string trashDir: `${root.trashRoot}/files`

  // Paths from the config without duplicates, in config order
  readonly property var configured: {
    const list = Array.from(Config.options?.dock?.files?.items ?? []);
    return list.filter((p, i) => p.length > 0 && list.indexOf(p) === i);
  }

  // Incrementally updated model for the Repeater (role: path). A plain array model would
  // recreate every delegate on change and kill the enter animations.
  ListModel {
    id: _model
  }
  property alias itemsModel: _model

  // Facts about each existing path, keyed by path: { isDir, name, suffix, icon }.
  // icon is the Icon= value of the .directory file inside a directory, "" when there is none.
  property var _info: ({})
  readonly property var _emptyInfo: ({
      isDir: false,
      name: "",
      suffix: "",
      icon: ""
    })

  // Number of slots in the section. Zero hides the section and its separator.
  readonly property int itemCount: root.enabled ? _model.count + (root.trashEnabled ? 1 : 0) : 0
  readonly property bool trashFull: _trash.count > 0
  readonly property string trashIcon: AppSearch.resolveIcon(root.trashFull ? "user-trash-full" : "user-trash", "user-trash")

  // Files with these suffixes are shown as their own picture instead of a type icon
  readonly property var previewSuffixes: ["png", "jpg", "jpeg", "webp", "gif", "bmp", "avif", "svg"]

  readonly property var _suffixIcons: {
    const groups = {
      "image-x-generic": ["png", "jpg", "jpeg", "webp", "gif", "bmp", "avif", "svg", "tiff"],
      "video-x-generic": ["mp4", "mkv", "webm", "avi", "mov"],
      "audio-x-generic": ["mp3", "flac", "ogg", "opus", "wav", "m4a"],
      "application-pdf": ["pdf"],
      "package-x-generic": ["zip", "7z", "rar", "tar", "gz", "xz", "zst", "bz2"],
      "x-office-document": ["doc", "docx", "odt", "rtf"],
      "x-office-spreadsheet": ["xls", "xlsx", "ods", "csv"],
      "x-office-presentation": ["ppt", "pptx", "odp"],
      "text-x-script": ["sh", "py", "js", "lua", "nix", "qml", "rs", "c", "cpp", "h", "cs", "json", "toml", "yaml", "yml"]
    };
    const map = {};
    for (const icon of Object.keys(groups)) {
      for (const suffix of groups[icon])
        map[suffix] = icon;
    }
    return map;
  }

  // ------------------------------------------------------------- trash watcher

  // Makes sure the trash directory exists before the folder model starts watching it.
  // Mode 700: the trash directory must stay private, same as the one created by GLib.
  Process {
    command: ["mkdir", "-p", "-m", "700", root.trashRoot, root.trashDir]
    running: true
    onExited: _trash.folder = "file://" + root.trashDir
  }

  FolderListModel {
    id: _trash
    showDirs: true
    showFiles: true
    showHidden: true
  }

  // ------------------------------------------------------------- items

  // Prints "d<TAB>path<TAB>icon" for a directory and "f<TAB>path<TAB>" for anything else that exists.
  // icon is the Icon= value from the [Desktop Entry] group of the .directory file in the directory.
  readonly property string _statScript: [
    'for p in "$@"; do',
    '  if [ -d "$p" ]; then',
    '    icon=""',
    '    if [ -r "$p/.directory" ]; then',
    '      icon=$(awk \'/^\\[/ { g = ($0 == "[Desktop Entry]"); next } g && /^Icon[ \\t]*=/ { sub(/^Icon[ \\t]*=[ \\t]*/, ""); gsub(/[ \\t\\r]+$/, ""); print; exit }\' "$p/.directory")',
    '    fi',
    '    printf "d\\t%s\\t%s\\n" "$p" "$icon"',
    '  elif [ -e "$p" ]; then',
    '    printf "f\\t%s\\t\\n" "$p"',
    '  fi',
    'done'
  ].join("\n")

  property bool _refreshPending: false

  function refresh() {
    if (statProc.running) {
      root._refreshPending = true;
      return;
    }
    const paths = root.configured;
    if (paths.length === 0) {
      root._info = {};
      root._syncModel([]);
      return;
    }
    statProc.command = ["bash", "-c", root._statScript, "dock-files-stat"].concat(paths);
    statProc.running = true;
  }

  Process {
    id: statProc
    running: false
    stdout: StdioCollector {
      onStreamFinished: root._ingest(this.text)
    }
    onExited: {
      if (root._refreshPending) {
        root._refreshPending = false;
        root.refresh();
      }
    }
  }

  function _ingest(text) {
    const info = {};
    for (const line of String(text).split("\n")) {
      if (line.length < 3)
        continue;
      const isDir = line[0] === "d";
      // The icon is behind the last tab, the path in between
      const tab = line.lastIndexOf("\t");
      const path = line.slice(2, tab > 1 ? tab : undefined);
      const icon = tab > 1 ? line.slice(tab + 1) : "";
      const name = path.replace(/\/+$/, "").split("/").pop() || path;
      const dot = name.lastIndexOf(".");
      info[path] = {
        "isDir": isDir,
        "name": name,
        "suffix": (!isDir && dot > 0) ? name.slice(dot + 1) : "",
        "icon": isDir ? icon : ""
      };
    }
    // Data first, then the model, so new delegates see fresh data
    root._info = info;
    root._syncModel(root.configured.filter(p => p in info));
  }

  // Applies insert / remove / move operations so existing delegates survive
  function _syncModel(target) {
    for (let i = _model.count - 1; i >= 0; i--) {
      if (!target.includes(_model.get(i).path))
        _model.remove(i);
    }
    for (let i = 0; i < target.length; i++) {
      const path = target[i];
      if (i < _model.count && _model.get(i).path === path)
        continue;
      let from = -1;
      for (let j = i + 1; j < _model.count; j++) {
        if (_model.get(j).path === path) {
          from = j;
          break;
        }
      }
      if (from === -1)
        _model.insert(i, {
          "path": path
        });
      else
        _model.move(from, i, 1);
    }
  }

  function infoFor(path) {
    return root._info[path] ?? root._emptyInfo;
  }

  Connections {
    target: Config.options?.dock?.files ?? null
    function onItemsChanged() {
      root.refresh();
    }
  }

  Connections {
    target: Config
    function onReadyChanged() {
      if (Config.ready)
        root.refresh();
    }
  }

  // ------------------------------------------------------------- .directory watcher

  // Several changes in a row (a file is saved in two steps, a folder loads) give one refresh
  Timer {
    id: _directoryTimer
    interval: 150
    repeat: false
    onTriggered: root.refresh()
  }

  // One watcher pair per listed path that is a directory. The FileView sees the .directory file
  // being edited, the FolderListModel sees it being created or deleted. Either one runs refresh(),
  // which reads the Icon= value again. Items are matched by path, so a refresh that changes nothing
  // keeps the watchers.
  Instantiator {
    model: _model
    delegate: Item {
      id: watcher
      required property string path
      readonly property bool isDir: root.infoFor(watcher.path).isDir

      FileView {
        path: watcher.isDir ? `${watcher.path}/.directory` : ""
        watchChanges: true
        onFileChanged: {
          this.reload();
          _directoryTimer.restart();
        }
      }

      FolderListModel {
        folder: watcher.isDir ? root.fileUrl(watcher.path) : ""
        nameFilters: [".directory"]
        showDirs: false
        showFiles: true
        showHidden: true
        onCountChanged: _directoryTimer.restart()
      }
    }
  }

  Component.onCompleted: root.refresh()

  // ------------------------------------------------------------- icons

  function isPreviewable(isDir, suffix) {
    return root.showPreviews && !isDir && root.previewSuffixes.includes(String(suffix).toLowerCase());
  }

  function iconFor(isDir, suffix) {
    const name = isDir ? "folder" : (root._suffixIcons[String(suffix).toLowerCase()] ?? "text-x-generic");
    return AppSearch.resolveIcon(name, "text-x-generic");
  }

  // Icon of a slot from infoFor(). A directory with an Icon= in its .directory file uses it: an
  // absolute path is loaded as a file, anything else is a theme icon name.
  function iconForMeta(meta) {
    if (meta.isDir && meta.icon.length > 0) {
      if (meta.icon.startsWith("/"))
        return root.fileUrl(meta.icon);
      return AppSearch.resolveIcon(meta.icon, "folder");
    }
    return root.iconFor(meta.isDir, meta.suffix);
  }

  // file:// url of a path, with every segment percent-encoded
  function fileUrl(path) {
    return "file://" + String(path).split("/").map(s => encodeURIComponent(s)).join("/");
  }

  // ------------------------------------------------------------- paths

  function urlToPath(url) {
    const s = String(url);
    if (!s.startsWith("file://"))
      return "";
    const raw = s.slice(7);
    try {
      return decodeURIComponent(raw);
    } catch (e) {
      return raw;
    }
  }

  function _paths(urls) {
    return Array.from(urls).map(u => root.urlToPath(u)).filter(p => p.length > 0);
  }

  // ------------------------------------------------------------- config list

  function _write(list) {
    Config.options.dock.files.items = list;
  }

  // Appends the dropped paths to the config list. Paths that are already listed are skipped.
  // modelIndex is the position among the shown items to insert before; without it the paths go to
  // the end. Returns how many paths were new.
  function addUrls(urls, modelIndex) {
    const list = root.configured.slice();
    let at = list.length;
    if (modelIndex !== undefined && modelIndex >= 0 && modelIndex < _model.count) {
      const ref = list.indexOf(_model.get(modelIndex).path);
      if (ref >= 0)
        at = ref;
    }
    let added = 0;
    for (const p of root._paths(urls)) {
      const path = p.length > 1 ? p.replace(/\/+$/, "") : p;
      if (!list.includes(path)) {
        list.splice(at + added, 0, path);
        added++;
      }
    }
    if (added > 0)
      root._write(list);
    return added;
  }

  // Removes the path from the list only
  function remove(path) {
    root._write(root.configured.filter(p => p !== path));
  }

  function open(path) {
    Quickshell.execDetached(["xdg-open", path]);
  }

  // Opens the directory that contains the path
  function showInFolder(path) {
    const trimmed = String(path).replace(/\/+$/, "");
    const cut = trimmed.lastIndexOf("/");
    const parent = cut > 0 ? trimmed.slice(0, cut) : "/";
    Quickshell.execDetached(["xdg-open", parent]);
  }

  // ------------------------------------------------------------- trash

  function openTrash() {
    const cmd = String(Config.options?.dock?.files?.openTrashCommand ?? "dolphin trash:/").trim().split(/\s+/);
    if (cmd.length > 0 && cmd[0].length > 0)
      Quickshell.execDetached(cmd);
  }

  // Empties the XDG trash directly. `gio trash --empty` needs the GVfs trash backend,
  // which is not always installed. Dolphin (KIO) uses the same directory.
  readonly property string _emptyTrashScript: [
    'root="$1"',
    '[ -n "$root" ] && [ -d "$root/files" ] || exit 0',
    'chmod -R u+w "$root/files" 2>/dev/null',
    'find "$root/files" "$root/info" -mindepth 1 -delete 2>/dev/null',
    'rm -f "$root/directorysizes"'
  ].join("\n")

  function emptyTrash() {
    Quickshell.execDetached(["bash", "-c", root._emptyTrashScript, "dock-files-empty-trash", root.trashRoot]);
  }

  // ------------------------------------------------------------- copy into a directory

  // Copies files and directories into the directory $1. A name that is taken gets " (N)" before the
  // suffix instead of being overwritten. Symlinks are followed, so a .desktop file from a Nix profile
  // is copied as a real file. Items already inside the target and directories dropped into
  // themselves are skipped.
  readonly property string _copyScript: [
    'dest="${1%/}"; shift',
    '[ -d "$dest" ] || exit 1',
    'for src in "$@"; do',
    '  src="${src%/}"',
    '  [ -e "$src" ] || continue',
    '  name="${src##*/}"',
    '  case "$dest/" in "$src"/*) continue ;; esac',
    '  [ "$(dirname -- "$src")" = "$dest" ] && continue',
    '  target="$dest/$name"',
    '  if [ -e "$target" ]; then',
    '    base="$name"; ext=""',
    '    if [ -f "$src" ] && [[ "$name" == *.* ]] && [[ "$name" != .* ]]; then',
    '      base="${name%.*}"; ext=".${name##*.}"',
    '    fi',
    '    n=1',
    '    while [ -e "$dest/$base ($n)$ext" ]; do n=$((n + 1)); done',
    '    target="$dest/$base ($n)$ext"',
    '  fi',
    '  cp -rL --preserve=timestamps -- "$src" "$target" && chmod -R u+rw "$target"',
    'done'
  ].join("\n")

  function copyUrls(urls, destDir) {
    const paths = root._paths(urls);
    if (paths.length === 0 || String(destDir).length === 0)
      return;
    Quickshell.execDetached(["bash", "-c", root._copyScript, "dock-files-copy", destDir].concat(paths));
  }

  function trashUrls(urls) {
    const paths = root._paths(urls);
    if (paths.length === 0)
      return;
    Quickshell.execDetached(["gio", "trash", "--"].concat(paths));
  }
}
