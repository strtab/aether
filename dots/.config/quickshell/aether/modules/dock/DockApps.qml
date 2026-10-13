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
  property int pinnedCount: 0
  // While true the model is frozen (a slot is being dragged)
  property bool dragging: false
  // Ids that are already gone but still shown while their slot plays the leave animation
  property var leavingIds: ({})
  // Order of the running apps that are not pinned. Set by dragging and kept in Persistent, not in
  // the config, so dragging never pins an app. Ids of closed apps stay in it until the next drag;
  // a re-opened app then returns to its old place.
  function _unpinnedOrder() {
    return Array.from(Persistent.states?.dock?.unpinnedOrder ?? []);
  }
  // False during startup so the initial slots do not animate in
  property bool settled: false
  // How long the indicator dots fade out before a leaving slot starts to fade
  readonly property int dotsFadeDuration: 300

  readonly property var _emptyItem: ({
      appId: "",
      rawId: "",
      pinned: false,
      running: false,
      toplevels: [],
      dotCount: 0,
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
      // Kept separately so a leaving slot can still show its dots while they fade out
      dotCount: toplevels.length,
      entry: entry,
      name: entry?.name ?? root._friendlyName(rawId),
      icon: AppSearch.resolveIcon(AppSearch.guessIcon(rawId), "application-x-executable")
    };
  }

  function rebuild() {
    if (root.dragging)
      return;
    // The order is built here and not taken from TaskbarApps: pinned apps first, in the order of
    // the config list, then the running apps that are not pinned. This keeps pinnedCount and the
    // real slot positions in sync even if TaskbarApps has not re-sorted its list yet.
    const live = Object.create(null);
    for (const app of TaskbarApps.apps) {
      const key = String(app.appId).toLowerCase();
      if (!live[key])
        live[key] = app;
    }
    const ordered = [];
    const seen = Object.create(null);
    for (const pinnedId of root._pinnedList()) {
      const key = String(pinnedId).toLowerCase();
      if (live[key] && !seen[key]) {
        seen[key] = true;
        ordered.push({
          "app": live[key],
          "pinned": true
        });
      }
    }
    for (const app of TaskbarApps.apps) {
      const key = String(app.appId).toLowerCase();
      if (!seen[key]) {
        seen[key] = true;
        ordered.push({
          "app": app,
          "pinned": false
        });
      }
    }

    // Running-only apps follow the order set by dragging; apps that are not in that order
    // keep the TaskbarApps order and come after the ones that are.
    const rank = Object.create(null);
    root._unpinnedOrder().forEach((id, i) => {
      rank[id] = i;
    });
    const rankOf = id => (id in rank) ? rank[id] : Number.MAX_SAFE_INTEGER;
    const loose = ordered.filter(e => !e.pinned).map((e, i) => ({
          "e": e,
          "i": i
        }));
    loose.sort((a, b) => (rankOf(a.e.app.appId) - rankOf(b.e.app.appId)) || (a.i - b.i));
    const finalOrder = ordered.filter(e => e.pinned).concat(loose.map(x => x.e));

    const byId = {};
    const ids = [];
    let pinnedCount = 0;
    for (const entry of finalOrder) {
      const id = entry.app.appId;
      byId[id] = root._makeItem(entry.app, entry.pinned);
      if (entry.pinned)
        pinnedCount++;
      ids.push(id);
    }

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

  // The saved order is loaded asynchronously and can also change from outside
  Connections {
    target: Persistent.states.dock
    function onUnpinnedOrderChanged() {
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

  // Used by drag and drop. targetIndex is a position in the dock.
  // - pinned app: reorders the pinned list in the config
  // - running-only app: reorders the session-only list; the app is never pinned
  // Then an immediate rebuild, so the dock is reordered in the same frame in which the
  // dragged slot is released.
  function moveSlot(appId, targetIndex) {
    if (root.isPinned(appId)) {
      const needle = String(appId).toLowerCase();
      const list = root._pinnedList().filter(id => String(id).toLowerCase() !== needle);
      list.splice(Math.max(0, Math.min(list.length, targetIndex)), 0, appId);
      Config.options.dock.pinnedApps = list;
    } else {
      const ids = root.slotIds.filter(id => !root.leavingIds[id] && !root._byId[id]?.pinned && id !== appId);
      const at = Math.max(0, Math.min(ids.length, targetIndex - root.pinnedCount));
      ids.splice(at, 0, appId);
      Persistent.states.dock.unpinnedOrder = ids;
    }
    root.rebuild();
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
      const keys = [item.appId, item.rawId, item.name, item.entry?.id ?? ""].map(k => String(k).toLowerCase().replace(/\.desktop$/, "")).filter(k => k.length > 2);
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
