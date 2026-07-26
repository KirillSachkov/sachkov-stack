#!/usr/bin/env bash
# Линтует только что изменённый файл средствами стека. Fire-and-forget: гейт никогда
# не блокирует работу, он лишь чинит форматирование в фоне. Всё, что должно блокировать,
# живёт в stop-gate.
#
# Стек реализует `stack_lint_file <repo> <path>` в .harness/stack.sh. Нет стека или нет
# функции, значит делать нечего.

set -u

input=$(cat)
path=$(printf '%s' "$input" | python3 -c \
  "import json,sys;t=json.load(sys.stdin).get('tool_input') or {};print(t.get('file_path') or '')" 2>/dev/null)
[ -z "$path" ] && path="${CLAUDE_FILE_PATH:-}"
[ -z "$path" ] && exit 0

cwd=$(printf '%s' "$input" | python3 -c \
  "import json,sys;print(json.load(sys.stdin).get('cwd',''))" 2>/dev/null)
[ -z "$cwd" ] && cwd="${CLAUDE_PROJECT_DIR:-$PWD}"
repo=$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null) || exit 0

STACK="$repo/.harness/stack.sh"
[ -f "$STACK" ] || exit 0
# shellcheck source=/dev/null
. "$STACK"

type stack_lint_file >/dev/null 2>&1 || exit 0
stack_lint_file "$repo" "$path" >/dev/null 2>&1 &
exit 0
