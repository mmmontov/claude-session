# claude-session (cs)

Постоянные Claude Code-сессии в tmux — по одной на проект. Они не умирают
при закрытии терминала, поднимаются сами после перезагрузки, а одной из них
можно писать прямо из Telegram с телефона.

## Установка

Нужен установленный [Claude Code](https://claude.com/claude-code). Затем одна команда:

```bash
npx skills add mmmontov/claude-session -g
```

(это CLI реестра [skills.sh](https://www.skills.sh/); флаг `-g` ставит скилл глобально в `~/.claude/skills`)

Без node/npm — просто через git:

```bash
git clone https://github.com/mmmontov/claude-session ~/.claude/skills/claude-session
```

Дальше откройте Claude Code и скажите ему:

> настрой claude-session

Claude сам установит всё необходимое, поможет создать Telegram-бота
и первую сессию. Ничего настраивать руками не нужно.

## Шпаргалка (появится после установки)

```
cs                          список сессий
cs <имя>                    подключиться к сессии
cs new <имя> <папка>        создать сессию
cs telegram <имя> [папка]   отдать сессии Telegram-бота
cs rm <имя>                 удалить сессию
```

Выйти из сессии, не останавливая её: `Ctrl+B`, затем `D`.

## Что внутри

- `SKILL.md` — скилл для Claude Code: онбординг и управление сессиями
- `scripts/claude-session` — CLI (`cs`)
- `scripts/claude-restart-loop.sh` — держит Claude запущенным, продолжает разговор после падений
- `scripts/claude-tmux-manager.sh` — поднимает сессии при загрузке (systemd user unit)
- `scripts/install.sh` — идемпотентная установка
- `completions/cs.bash` — tab-дополнение имён сессий
