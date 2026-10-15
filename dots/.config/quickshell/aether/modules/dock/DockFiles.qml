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
 * - Links: symbolic links in <shell config>/dock-files. Dropping files on the dock creates them.
 *   Removing an item from the dock deletes only the link, never the target.
 * - Trash: the XDG trash directory. Used for the full/empty icon and for the trash actions.
 * The order of the links is the file name order of the links directory.
 */
Singleton {
  id: root

  readonly property bool enabled: Config.options?.dock?.files?.enable ?? true
  readonly property bool trashEnabled: root.enabled && (Config.options?.dock?.files?.showTrash ?? true)
  readonly property bool showPreviews: Config.options?.dock?.files?.showPreviews ?? true

  readonly property string linksDir: `${Directories.shellConfig}/dock-files`
  readonly property string dataHome: Quickshell.env("XDG_DATA_HOME") || `${Quickshell.env("HOME")}/.local/share`
  readonly property string trashRoot: `${root.dataHome}/Trash`
  readonly property string trashDir: `${root.trashRoot}/files`

  property alias linksModel: _links
  readonly property int linkCount: _links.count
  // Number of slots in the section. Zero hides the section and its separator.
  readonly property int itemCount: root.enabled ? root.linkCount + (root.trashEnabled ? 1 : 0) : 0
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

  // Makes sure both directories exist before the folder models start watching them.
  // Mode 700: the trash directory must stay private, same as the one created by GLib.
  Process {
    command: ["mkdir", "-p", "-m", "700", root.linksDir, root.trashRoot, root.trashDir]
    running: true
    onExited: {
      _links.folder = "file://" + root.linksDir;
      _trash.folder = "file://" + root.trashDir;
    }
  }

  FolderListModel {
    id: _links
    showDirs: true
    showFiles: true
    showHidden: false
    sortField: FolderListModel.Name
    sortCaseSensitive: false
  }

  FolderListModel {
    id: _trash
    showDirs: true
    showFiles: true
    showHidden: true
  }

  // ------------------------------------------------------------- icons

  function isPreviewable(isDir, suffix) {
    return root.showPreviews && !isDir && root.previewSuffixes.includes(String(suffix).toLowerCase());
  }

  function iconFor(isDir, suffix) {
    const name = isDir ? "folder" : (root._suffixIcons[String(suffix).toLowerCase()] ?? "text-x-generic");
    return AppSearch.resolveIcon(name, "text-x-generic");
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

  // ------------------------------------------------------------- links

  // Creates one link per path. A target that is already linked is skipped, a name clash gets " (n)".
  readonly property string _addScript: ['dir="$1"; shift', 'mkdir -p "$dir"', 'shopt -s nullglob', 'for src in "$@"; do', '  src="$(readlink -f -- "$src")"', '  [ -e "$src" ] || continue', '  dupe=0', '  for l in "$dir"/*; do', '    if [ -L "$l" ] && [ "$(readlink -f -- "$l")" = "$src" ]; then dupe=1; break; fi', '  done', '  [ "$dupe" = 1 ] && continue', '  base="$(basename -- "$src")"', '  dest="$dir/$base"', '  n=2', '  while [ -e "$dest" ] || [ -L "$dest" ]; do', '    dest="$dir/$base ($n)"', '    n=$((n + 1))', '  done', '  ln -s -- "$src" "$dest"', 'done'].join("\n")

  function addUrls(urls) {
    const paths = root._paths(urls);
    if (paths.length === 0)
      return;
    Quickshell.execDetached(["bash", "-c", root._addScript, "dock-files-add", root.linksDir].concat(paths));
  }

  // Deletes the link only. A regular file that ended up in the directory is left alone.
  function removeLink(path) {
    Quickshell.execDetached(["bash", "-c", '[ -L "$1" ] && rm -f -- "$1"', "dock-files-remove", path]);
  }

  function open(path) {
    Quickshell.execDetached(["xdg-open", path]);
  }

  function showInFolder(path) {
    Quickshell.execDetached(["bash", "-c", 'xdg-open "$(dirname "$(readlink -f -- "$1")")"', "dock-files-show", path]);
  }

  // ------------------------------------------------------------- trash

  function openTrash() {
    const cmd = String(Config.options?.dock?.files?.openTrashCommand ?? "dolphin trash:/").trim().split(/\s+/);
    if (cmd.length > 0 && cmd[0].length > 0)
      Quickshell.execDetached(cmd);
  }

  // Empties the XDG trash directly. `gio trash --empty` needs the GVfs trash backend,
  // which is not always installed. Dolphin (KIO) uses the same directory.
  readonly property string _emptyTrashScript: ['root="$1"', '[ -n "$root" ] && [ -d "$root/files" ] || exit 0', 'chmod -R u+w "$root/files" 2>/dev/null', 'find "$root/files" "$root/info" -mindepth 1 -delete 2>/dev/null', 'rm -f "$root/directorysizes"'].join("\n")

  function emptyTrash() {
    Quickshell.execDetached(["bash", "-c", root._emptyTrashScript, "dock-files-empty-trash", root.trashRoot]);
  }

  function trashUrls(urls) {
    const paths = root._paths(urls);
    if (paths.length === 0)
      return;
    Quickshell.execDetached(["gio", "trash", "--"].concat(paths));
  }
}
