#!/usr/bin/env python

# Reads notification counts from window titles using hyprctl
# Output format: appId|count per line
# Apps like Electron or Chromium-based apps put "(17761)" in their window title

import subprocess
import json
import sys
import re

clients = subprocess.run(
    ["hyprctl", "clients", "-j"],
    capture_output=True,
    text=True,
    check=True
)

try:
    clients = json.load(clients.stdout)
except:
    sys.exit(0)

for c in clients:
    title = c.get('title', '')
    class_name = c.get('class', '')
    initial_title = c.get('initialTitle', '')

    # Try to find a number in the title (notification count)
    # Patterns: (number)
    numbers = re.findall(r'(\d+)|(\d+\.\d+)|(\d+,\d+)', title)

    count = 0
    for n in numbers:
        clean = n.replace(',', '').replace('.', '')
        if clean.isdigit() and int(clean) > 0:
            count = int(clean)
            break

    if count > 0:
        print(f'{class_name}|{count}')
