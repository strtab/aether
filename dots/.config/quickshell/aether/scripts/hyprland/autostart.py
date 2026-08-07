#!/usr/bin/env python3
import json
import subprocess
import sys
import time
import os

LOCKFILE = "/tmp/qs-autostart.lock"


def log(msg: str) -> None:
    print(f"[autostart] {msg}", file=sys.stderr)


def run_dispatch(args: str) -> bool:
    result = subprocess.run(
        ["hyprctl", "dispatch", args],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    )
    if result.returncode != 0:
        log(f"dispatch failed: {args!r} -> {result.stderr.strip()}")
        return False
    return True


def main() -> int:
    if os.path.exists(LOCKFILE):
        try:
            age = time.time() - os.path.getmtime(LOCKFILE)
        except OSError:
            age = 0
        if age < 5:
            log("already running, exiting")
            return 0
        log("stale lock found, removing")
        os.remove(LOCKFILE)

    open(LOCKFILE, "w").close()

    try:
        config_path = f"{os.environ['HOME']}/.config/aether/config.json"
        with open(config_path) as f:
            data = json.load(f)
    except (KeyError, OSError, json.JSONDecodeError) as e:
        log(f"failed to load config: {e}")
        return 1

    autostart = data.get("hyprland", {}).get("autostartApps", {})
    if not autostart.get("enable", False):
        log("autostart disabled in config")
        return 0

    apps = autostart.get("apps", [])
    if not apps:
        log("no apps configured")
        return 0

    for app in apps:
        cmd = app.get("cmd", "").strip()
        workspace = app.get("workspace", 1)
        delay = app.get("delay", 0)
        if not cmd:
            continue

        if not run_dispatch(f"hl.dsp.focus({{workspace = {workspace}}})"):
            continue

        expanded_cmd = os.path.expanduser(cmd)
        if not run_dispatch(f'hl.dsp.exec_cmd("{expanded_cmd}")'):
            continue

        log(f"started {expanded_cmd!r} on workspace {workspace}")
        time.sleep(delay)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
