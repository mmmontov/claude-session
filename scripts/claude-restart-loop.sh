#!/bin/bash
# Keeps a Claude Code session alive in the given project directory,
# restarting (and resuming the last conversation) if it exits or crashes.
# Falls back to a fresh session when there is nothing to continue yet,
# and backs off exponentially on fast-crash loops so a persistent
# failure (e.g. bad auth) doesn't hammer in a tight restart spin.
set -u
dir="$1"
cd "$dir" || exit 1

backoff=2
max_backoff=60

flags=()
if [ "${CLAUDE_CHANNELS:-}" = "1" ]; then
  flags=(--channels plugin:telegram@claude-plugins-official --permission-mode auto)
else
  # Telegram is enabled in user settings for the channel-bound session;
  # explicitly disable it here so this session doesn't also spin up an
  # MCP server that fights over the same bot token.
  flags=(--settings '{"enabledPlugins":{"telegram@claude-plugins-official":false}}')
fi

while true; do
  start_ts=$(date +%s)

  claude "${flags[@]}" -c || claude "${flags[@]}"

  elapsed=$(( $(date +%s) - start_ts ))

  if [ "$elapsed" -lt 5 ]; then
    sleep "$backoff"
    if [ "$backoff" -lt "$max_backoff" ]; then
      backoff=$(( backoff * 2 ))
    fi
  else
    backoff=2
    sleep 2
  fi
done
