pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

// Dock icon that recovers on its own.
// After a shell reload the icon provider can answer before the icon theme is ready, the Image
// ends in Error and stays empty until its source changes. This component walks a chain of sources
// instead of giving up:
//   1. iconSource, retried with growing delays (blank -> wait -> same source again)
//   2. fallbackSource (for example the type icon of an image preview)
//   3. the theme icon looked up again by name (exact and lowercase), checked with iconPath(name, true)
//   4. the generic application icon
// When the whole chain fails it is armed again after a pause, and it is restarted from the top
// when the app list or the config changes. `source` is a pure binding and is never assigned
// imperatively, so the delegate can be recycled safely.
Image {
  id: root

  // Primary source, usually "image://icon/<name>?fallback=..." from AppSearch.resolveIcon
  property string iconSource: ""
  // Used when the primary source ran out of retries
  property string fallbackSource: ""
  // Delays between retries of the primary source, ms
  property var retryDelays: [150, 400, 1000, 2500, 6000]
  // Retries for every later source of the chain
  property int fallbackRetries: 1
  // Pause before a fully failed chain is tried again, ms
  property int rearmDelay: 10000
  // A load that stays in Loading longer than this counts as a failure, ms
  property int loadTimeout: 5000
  // The owner bumps this when the theme or the app list may have changed (DockApps.iconEpoch)
  property int resetToken: 0

  // Position in the chain and retries used for it
  property int stage: 0
  property int attempt: 0
  // True for the pause between two tries, so the same source is loaded again from scratch
  property bool blanked: false
  // Bumped on reset so the chain is rebuilt (the theme lookups may answer differently by then)
  property int _epoch: 0

  readonly property bool failed: root.stage >= root._chain.length
  readonly property string _iconName: root._nameOf(root.iconSource)

  // Icon name from an image://icon/ url, or the base name of a file path
  function _nameOf(src) {
    const s = String(src ?? "");
    const m = /^image:\/\/icon\/([^?]*)/.exec(s);
    if (m) {
      try {
        return decodeURIComponent(m[1]);
      } catch (e) {
        return m[1];
      }
    }
    if (s.startsWith("file://") || s.startsWith("/")) {
      const file = s.split("/").pop();
      const dot = file.lastIndexOf(".");
      return dot > 0 ? file.slice(0, dot) : file;
    }
    return "";
  }

  readonly property var _chain: {
    root._epoch;
    const list = [];
    const add = s => {
      if (s && String(s).length > 0 && !list.includes(String(s)))
        list.push(String(s));
    };
    add(root.iconSource);
    add(root.fallbackSource);
    const name = root._iconName;
    if (name.length > 0) {
      add(Quickshell.iconPath(name, true));
      add(Quickshell.iconPath(name.toLowerCase(), true));
    }
    add(Quickshell.iconPath("application-x-executable", "image-missing"));
    return list;
  }

  source: (root.blanked || root.failed) ? "" : root._chain[root.stage]

  fillMode: Image.PreserveAspectFit
  antialiasing: true
  asynchronous: true
  mipmap: true
  smooth: true

  // ---------------------------------------------------------------- recovery

  function reset() {
    retryTimer.stop();
    root.blanked = false;
    root.stage = 0;
    root.attempt = 0;
    root._epoch++;
  }

  // Next step after a failure: retry the current source, or move on along the chain
  function recover() {
    if (root.failed)
      return;
    const first = root.stage === 0;
    const limit = first ? root.retryDelays.length : root.fallbackRetries;
    if (root.attempt < limit) {
      retryTimer.interval = first ? root.retryDelays[root.attempt] : 300;
      root.attempt++;
      root.blanked = true;
      retryTimer.restart();
    } else {
      root.stage++;
      root.attempt = 0;
    }
  }

  function _onError() {
    if (root.status === Image.Error)
      root.recover();
  }

  onStatusChanged: {
    // Deferred: the source binding depends on state that this handler changes
    if (root.status === Image.Error)
      Qt.callLater(root._onError);
  }

  onIconSourceChanged: root.reset()
  onFallbackSourceChanged: root.reset()

  Timer {
    id: retryTimer
    repeat: false
    onTriggered: root.blanked = false
  }

  // A load that never finishes is handled like an error
  Timer {
    interval: root.loadTimeout
    repeat: false
    running: root.status === Image.Loading
    onTriggered: root.recover()
  }

  // The whole chain failed: try again later
  Timer {
    interval: root.rearmDelay
    repeat: false
    running: root.failed && root.iconSource.length > 0
    onTriggered: root.reset()
  }

  // Theme or app list became available later: go back to the primary source
  onResetTokenChanged: {
    if (root.status !== Image.Ready || root.stage > 0)
      root.reset();
  }
}
