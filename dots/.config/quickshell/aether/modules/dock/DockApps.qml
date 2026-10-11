pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common
import qs.services

/**
 * Dock data adapter (services/DockApps.qml).
 * - Model: TaskbarApps (pinned apps from Config + running toplevels)
 * - Names, icons, desktop entries: AppSearch
 * - Pin state and order: Config.options.dock.pinnedApps
 */
Singleton {
  id: root

  readonly property string killScript: Qt.resolvedUrl("../scripts/kill_app.sh").toString().replace(/^file:\/\//, "")

  // Ordered ids shown in the dock. Reassigned only when the list really changes,
  // so Repeater delegates (hover, bounce, drag state) survive window events.
  property var slotIds: []
  // Live data per id. Rebuilt on every change; delegates read it through itemFor().
  property var _byId: ({})
  property int pinnedCount: 0
  // While true the model is frozen (a slot is being dragged)
  property bool dragging: false

  readonly property var _emptyItem: ({
      appId: "",
      rawId: "",
      pinned: false,
      running: false,
      toplevels: [],
      entry: null,
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

  function _makeItem(app, pinned) {
    const toplevels = app.toplevels ?? [];
    // Prefer the real window appId (keeps original casing) over the lowercased key
    const rawId = toplevels.length > 0 && toplevels[0].appId ? toplevels[0].appId : app.appId;
    const entry = AppSearch.lookupDesktopEntry(rawId) ?? AppSearch.lookupDesktopEntry(app.appId);
    return {
      appId: app.appId,
      rawId: rawId,
      pinned: pinned,
      running: toplevels.length > 0,
      toplevels: toplevels,
      entry: entry,
      name: entry?.name ?? root._friendlyName(rawId),
      icon: AppSearch.resolveIcon(AppSearch.guessIcon(rawId), "application-x-executable")
    };
  }

  function rebuild() {
    if (root.dragging)
      return;
    const pinnedIds = Array.from(Config.options?.dock?.pinnedApps ?? []).map(id => String(id).toLowerCase());
    const byId = {};
    const ids = [];
    let pinnedCount = 0;
    for (const app of TaskbarApps.apps) {
      const id = app.appId;
      const item = root._makeItem(app, pinnedIds.includes(id.toLowerCase()));
      byId[id] = item;
      if (item.pinned)
        pinnedCount++;
      ids.push(id);
    }
    // Data first, then the id list, so new delegates see fresh data
    root._byId = byId;
    root.pinnedCount = pinnedCount;
    if (ids.join("|") !== root.slotIds.join("|"))
      root.slotIds = ids;
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

  Connections {
    target: TaskbarApps
    function onAppsChanged() {
      root.scheduleRebuild();
    }
  }

  Connections {
    target: Config.options.dock
    function onPinnedAppsChanged() {
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

  function _pinnedList() {
    return Array.from(Config.options?.dock?.pinnedApps ?? []);
  }

  function isPinned(appId) {
    const needle = String(appId).toLowerCase();
    return root._pinnedList().some(id => String(id).toLowerCase() === needle);
  }

  function pinApp(appId) {
    Config.options.dock.pinnedApps = root._pinnedList().concat([appId]);
  }

  function unpinApp(appId) {
    const needle = String(appId).toLowerCase();
    Config.options.dock.pinnedApps = root._pinnedList().filter(id => String(id).toLowerCase() !== needle);
  }

  // Moves a pinned app so that it ends up at targetIndex of the pinned list
  function movePinned(appId, targetIndex) {
    const needle = String(appId).toLowerCase();
    const list = root._pinnedList();
    const from = list.findIndex(id => String(id).toLowerCase() === needle);
    if (from === -1)
      return;
    const moved = list.splice(from, 1)[0];
    list.splice(Math.max(0, Math.min(list.length, targetIndex)), 0, moved);
    Config.options.dock.pinnedApps = list;
  }

  // Used by drag and drop: pins the app first when it is only running
  function moveToPinnedIndex(appId, targetIndex) {
    root.pinApp(appId);
    root.movePinned(appId, targetIndex);
  }

  // ------------------------------------------------------------- actions

  function launch(item) {
    const entry = item.entry ?? AppSearch.lookupDesktopEntry(item.rawId);
    if (entry)
      entry.execute();
    else if (item.rawId)
      Quickshell.execDetached([item.rawId]);
  }

  // Focuses the app; cycles through its windows when it has several
  function focus(item) {
    const list = item?.toplevels ?? [];
    if (list.length === 0)
      return;
    const current = list.findIndex(t => t.activated);
    list[(current + 1) % list.length].activate();
    root.clearBadge(item.appId);
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
      const item = root._byId[id];
      const keys = [item.appId, item.rawId, item.name, item.entry?.id ?? ""].map(k => String(k).toLowerCase().replace(/\.desktop$/, "")).filter(k => k.length > 2);
      if (keys.some(k => n.includes(k) || k.includes(n)))
        return item;
    }
    return null;
  }

  Connections {
    target: Notifications
    function onNotify(n) {
      const item = root._matchItem(n.appName);
      if (item)
        root.incrementBadge(item.appId);
    }
  }

  Component.onCompleted: {
    root.rebuild();
  }
}
