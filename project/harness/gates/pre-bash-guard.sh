#!/usr/bin/env bash
# Блокирует команды, которые проект объявил запрещёнными.
#
# Список живёт в `.harness/deny-commands.txt`: одна расширенная регулярка на строку,
# пустые строки и строки с `#` игнорируются. Формат текстовый специально: правило
# добавляется правкой файла, а не правкой скрипта.
#
# Контракт: JSON со stdin, причина в stderr, exit 2 отменяет вызов.

set -u

input=$(cat)
cmd=$(printf '%s' "$input" | python3 -c \
  "import json,sys;print((json.load(sys.stdin).get('tool_input') or {}).get('command',''))" 2>/dev/null)
[ -z "$cmd" ] && exit 0

cwd=$(printf '%s' "$input" | python3 -c \
  "import json,sys;print(json.load(sys.stdin).get('cwd',''))" 2>/dev/null)
[ -z "$cwd" ] && cwd="${CLAUDE_PROJECT_DIR:-$PWD}"
repo=$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null) || repo="$cwd"

deny="$repo/.harness/deny-commands.txt"
[ -f "$deny" ] || exit 0

while IFS= read -r line || [ -n "$line" ]; do
  case "$line" in ''|'#'*) continue;; esac
  pattern="${line%%|##|*}"
  reason="${line#*|##|}"
  [ "$reason" = "$line" ] && reason="команда запрещена правилами проекта"
  if printf '%s' "$cmd" | grep -Eq -- "$pattern"; then
    {
      echo "PRE-BASH-ГЕЙТ: $reason"
      echo "  команда: $cmd"
      echo "  правило: $pattern (.harness/deny-commands.txt)"
    } >&2
    exit 2
  fi
done < "$deny"

exit 0
