# Bash-дополнение для cs / claude-session: подсказывает подкоманды и имена сессий.
_cs_complete() {
  local cur prev conf
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]}"
  conf="$HOME/.config/claude-sessions.conf"

  _cs_names() {
    [ -f "$conf" ] && grep -vE '^\s*(#|$)' "$conf" | cut -d: -f1
  }

  if [ "$COMP_CWORD" -eq 1 ]; then
    COMPREPLY=($(compgen -W "$(_cs_names) new telegram list attach rm help" -- "$cur"))
    return
  fi

  case "$prev" in
    telegram|attach|a|rm)
      COMPREPLY=($(compgen -W "$(_cs_names)" -- "$cur"))
      ;;
    *)
      COMPREPLY=($(compgen -d -- "$cur"))
      ;;
  esac
}
complete -F _cs_complete cs claude-session
