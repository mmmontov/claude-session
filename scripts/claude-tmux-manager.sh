#!/bin/bash
# Ensures a tmux session exists for every entry in claude-sessions.conf.
# Safe to re-run: existing sessions are left untouched.
# Run at boot by the claude-sessions systemd user unit.
set -u
conf="$HOME/.config/claude-sessions.conf"

script_dir="$(dirname "$(readlink -f "$0")")"
loop="$script_dir/claude-restart-loop.sh"
[ -x "$loop" ] || loop="$HOME/.local/bin/claude-restart-loop.sh"

[ -f "$conf" ] || exit 0

while IFS=: read -r name dir mode; do
  [ -z "$name" ] && continue
  case "$name" in \#*) continue ;; esac
  [ -z "$dir" ] && continue

  if ! tmux has-session -t "$name" 2>/dev/null; then
    if [ "${mode:-}" = "channels" ]; then
      tmux new-session -d -s "$name" -c "$dir" "env CLAUDE_CHANNELS=1 '$loop' '$dir'"
    else
      tmux new-session -d -s "$name" -c "$dir" "$loop '$dir'"
    fi
  fi
done < "$conf"
