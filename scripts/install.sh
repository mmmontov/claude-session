#!/bin/bash
# Установка cs / claude-session. Идемпотентен — можно запускать повторно.
# Ставит симлинки в ~/.local/bin, systemd user unit для автозапуска
# сессий при загрузке и bash-дополнение. Ничего не удаляет и не
# перезапускает уже работающие сессии.
set -u

repo="$(dirname "$(readlink -f "$0")")/.."
repo="$(realpath "$repo")"
bin="$HOME/.local/bin"
conf="$HOME/.config/claude-sessions.conf"
unit_dir="$HOME/.config/systemd/user"
unit="$unit_dir/claude-sessions.service"

ok=()    # что сделали
warn=()  # на что обратить внимание

# --- зависимости -----------------------------------------------------------
if ! command -v tmux >/dev/null 2>&1; then
  warn+=("tmux не установлен — без него ничего не заработает. Установка: sudo apt install tmux")
fi
if ! command -v claude >/dev/null 2>&1; then
  warn+=("команда claude не найдена — установите Claude Code: https://claude.com/claude-code")
fi

# --- симлинки в ~/.local/bin -----------------------------------------------
mkdir -p "$bin"
for f in claude-session claude-restart-loop.sh claude-tmux-manager.sh; do
  ln -sf "$repo/scripts/$f" "$bin/$f"
done
chmod +x "$repo/scripts/claude-session" "$repo/scripts/claude-restart-loop.sh" \
         "$repo/scripts/claude-tmux-manager.sh"
ok+=("команды claude-session установлены в $bin")

# короткое имя cs — только если оно не занято чем-то чужим
cs_owner="$(command -v cs 2>/dev/null || true)"
if [ -z "$cs_owner" ] || [ "$(readlink -f "$cs_owner" 2>/dev/null)" = "$repo/scripts/claude-session" ]; then
  ln -sf "$repo/scripts/claude-session" "$bin/cs"
  ok+=("короткая команда: cs")
else
  warn+=("команда 'cs' уже занята ($cs_owner) — короткое имя не ставлю, используйте claude-session")
fi

case ":$PATH:" in
  *":$bin:"*) ;;
  *) warn+=("$bin не в PATH — добавьте в ~/.bashrc: export PATH=\"\$HOME/.local/bin:\$PATH\"") ;;
esac

# --- конфиг сессий ----------------------------------------------------------
if [ ! -f "$conf" ]; then
  cat > "$conf" <<'EOF'
# Постоянные Claude Code-сессии (управляются командой cs).
# Формат: имя_сессии:/абсолютный/путь/к/проекту[:channels]
# Третье поле "channels" отдаёт этой сессии Telegram-бота
# (только у одной сессии — один бот, один обработчик).
# Одна строка — одна сессия. Строки с # игнорируются.
EOF
  ok+=("создан конфиг $conf")
fi

# --- автозапуск при загрузке (systemd user unit) ----------------------------
if command -v systemctl >/dev/null 2>&1 && systemctl --user show-environment >/dev/null 2>&1; then
  mkdir -p "$unit_dir"
  cat > "$unit" <<EOF
[Unit]
Description=Persistent Claude Code tmux sessions
After=network-online.target

[Service]
Type=oneshot
RemainAfterExit=yes
Environment=PATH=$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin
ExecStart=$HOME/.local/bin/claude-tmux-manager.sh

[Install]
WantedBy=default.target
EOF
  systemctl --user daemon-reload
  systemctl --user enable claude-sessions.service >/dev/null 2>&1
  ok+=("автозапуск сессий при загрузке включён (systemd user unit claude-sessions)")
else
  warn+=("systemd user-сессия недоступна — автозапуск при загрузке не настроен; после перезагрузки запускайте claude-tmux-manager.sh вручную")
fi

# --- bash-дополнение ---------------------------------------------------------
comp_line="source \"$repo/completions/cs.bash\""
if [ -f "$HOME/.bashrc" ] && ! grep -qF "completions/cs.bash" "$HOME/.bashrc"; then
  printf '\n# cs (claude-session) tab-completion\n%s\n' "$comp_line" >> "$HOME/.bashrc"
  ok+=("tab-дополнение подключено в ~/.bashrc (заработает в новом терминале)")
fi

# --- итог --------------------------------------------------------------------
echo "=== Установлено ==="
for line in "${ok[@]}"; do echo "  + $line"; done
if [ "${#warn[@]}" -gt 0 ]; then
  echo "=== Требует внимания ==="
  for line in "${warn[@]}"; do echo "  ! $line"; done
fi
echo
echo "Дальше: cs new <имя> <папка проекта>  — создать первую сессию"
