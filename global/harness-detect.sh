#!/usr/bin/env bash
# SessionStart: сообщает агенту состояние харнеса текущего репозитория.
#
# Три исхода:
#   харнеса нет      -> предложи построить (скилл project-harness-bootstrap)
#   харнес отстал    -> предложи обновить, покажи дрейф
#   всё совпадает    -> молчит (тишина это норма, шум в контексте стоит токенов)
#
# Общий для всех рантаймов. `--json` даёт форму, которую понимает Claude Code;
# без флага печатает простой текст, который Codex подмешивает в контекст как есть.

set -u

JSON=0
[ "${1:-}" = "--json" ] && JSON=1

emit() {
  if [ "$JSON" = 1 ]; then
    python3 -c '
import json, sys
print(json.dumps({"hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": sys.stdin.read(),
}}, ensure_ascii=False))' <<< "$1"
  else
    printf '%s\n' "$1"
  fi
}

repo=$(git -C "$PWD" rev-parse --show-toplevel 2>/dev/null) || exit 0

BRAIN_ROOT=""
for c in "${AGENT_BRAIN:-}" "$HOME/dev/brain" "$HOME/brain"; do
  [ -n "$c" ] || continue
  if [ -f "$c/AGENTS.md" ] && [ -d "$c/memory" ] && [ -d "$c/skills" ]; then BRAIN_ROOT="$c"; break; fi
done
[ -n "$BRAIN_ROOT" ] || exit 0

# Сам мозг живёт по своим правилам, проектный харнес ему не нужен.
[ "$repo" = "$BRAIN_ROOT" ] && exit 0

HARNESS="$BRAIN_ROOT/harness"
[ -d "$HARNESS" ] || exit 0
PKG_VERSION=$(cat "$HARNESS/VERSION" 2>/dev/null || echo "")
[ -n "$PKG_VERSION" ] || exit 0

lock="$repo/.harness/harness.lock"

if [ ! -f "$lock" ]; then
  # Репозиторий без харнеса, но и без признаков рабочего проекта трогать незачем.
  [ -d "$repo/.git" ] || exit 0
  emit "ХАРНЕС: в этом репозитории ($(basename "$repo")) харнеса нет.
Правило владельца от 2026-07-19: не работать молча без харнеса.
Первым делом предложи его построить: скилл project-harness-bootstrap
(детект стека, короткое интервью, \`$HARNESS/bin/harness init\`, прогон команд).
Если владелец откажется, работай дальше, но скажи, что гейты не подключены."
  exit 0
fi

LOCK_VERSION=$(python3 -c \
  "import json,sys;print(json.load(open(sys.argv[1],encoding='utf-8')).get('version',''))" \
  "$lock" 2>/dev/null)
[ -n "$LOCK_VERSION" ] || exit 0

if [ "$LOCK_VERSION" != "$PKG_VERSION" ]; then
  detail=$(python3 "$HARNESS/bin/harness" diff "$repo" 2>/dev/null | tail -n +2)
  emit "ХАРНЕС: версия проекта $LOCK_VERSION, в пакете $PKG_VERSION.
$detail
Предложи владельцу обновить: \`$HARNESS/bin/harness update $repo\`.
Локальные правки update не затирает, конфликты показывает и останавливается."
fi

exit 0
