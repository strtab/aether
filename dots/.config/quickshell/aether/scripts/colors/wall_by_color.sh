#!/usr/bin/env bash

XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STATE_DIR="$XDG_STATE_HOME/quickshell"

main() {
  color_code=$1
  if [[ -z "$color_code" ]]; then
      color_code="$(kdialog --getcolor --title 'Choose color')"
      [[ -z "$color_code" ]] && exit 1
  fi
  magick -size 1920x1080 xc:"$color_code" "$STATE_DIR/user/generated/wallpaper/monotone.png"
  "$SCRIPT_DIR"/switchwall.sh "$STATE_DIR/user/generated/wallpaper/monotone.png"
}

main "$@"
