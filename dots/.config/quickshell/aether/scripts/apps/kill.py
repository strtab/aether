#!/usr/bin/env python3
# Force-kill all windows of the given app IDs (matches Hyprland class / initialClass).

import json
import os
import signal
import subprocess
import sys


def ensure_hyprland_signature():
    # Automatically set HYPRLAND_INSTANCE_SIGNATURE if it is not already present
    if os.environ.get("HYPRLAND_INSTANCE_SIGNATURE"):
        return

    xdg_runtime = os.environ.get("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}")
    hypr_dir = os.path.join(xdg_runtime, "hypr")

    try:
        if os.path.isdir(hypr_dir):
            entries = os.listdir(hypr_dir)
            if entries:
                os.environ["HYPRLAND_INSTANCE_SIGNATURE"] = entries[0]
    except Exception:
        pass


def main():
    if len(sys.argv) < 2:
        print(f"Usage: {sys.argv[0]} <app_id1> [app_id2 ...]", file=sys.stderr)
        sys.exit(1)

    # Collect target IDs from command-line arguments case-insensitively
    target_ids = {arg.lower() for arg in sys.argv[1:]}

    # Ensure the environment variable is configured for hyprctl
    ensure_hyprland_signature()

    # Fetch active clients from hyprctl
    try:
        result = subprocess.run(
            ["hyprctl", "-j", "clients"],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            check=True,
        )
        clients = json.loads(result.stdout)
    except (subprocess.SubprocessError, json.JSONDecodeError, FileNotFoundError):
        sys.exit(0)

    # Iterate through clients and force-kill matching PIDs
    for client in clients:
        cls = str(client.get("class", "")).lower()
        initial_cls = str(client.get("initialClass", "")).lower()

        if cls in target_ids or initial_cls in target_ids:
            pid = client.get("pid", 0)
            if pid:
                try:
                    os.kill(int(pid), signal.SIGKILL)
                except Exception:
                    pass


if __name__ == "__main__":
    main()
