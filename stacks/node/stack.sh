# Стек: Node / TypeScript (базовый; next наследует его)
#
# Порядок выбора проверки принципиален:
#   1) собственный скрипт проекта (typecheck / type-check) — он всегда прав;
#   2) `tsc -b`, если tsconfig ссылочный (solution-style: files: [] + references);
#   3) `tsc --noEmit` для обычного tsconfig.
#
# Пункт 2 появился не из теории. На content-builder голый `tsc --noEmit` возвращал 0
# при живой ошибке типов: у ссылочного tsconfig нет собственных файлов, компилировать
# ему нечего, и гейт молча пропускал сломанный код. Проверяй гейт на реальном репо,
# а не на игрушечном.
#
# tsc гоняется по проекту целиком, а не по изменённому файлу: сломанный импорт после
# удаления или переименования ловится только полной проверкой. Инкрементальный режим
# делает это дешёвым после первого прогона.

_stack_ts_root() {
  local repo="$1" root
  for root in "$repo" "$repo/frontend" "$repo/app" "$repo/web" "$repo/src"; do
    if [ -f "$root/tsconfig.json" ] && [ -d "$root/node_modules" ]; then
      printf '%s\n' "$root"
      return 0
    fi
  done
  return 1
}

_stack_ts_script() {
  # Печатает имя скрипта тайпчека из package.json, если он там объявлен.
  local root="$1"
  [ -f "$root/package.json" ] || return 1
  python3 - "$root/package.json" <<'PY'
import json, sys
try:
    scripts = json.load(open(sys.argv[1], encoding="utf-8")).get("scripts") or {}
except Exception:
    sys.exit(1)
for name in ("typecheck", "type-check", "tsc", "check-types"):
    if name in scripts:
        print(name)
        break
PY
}

_stack_ts_is_solution() {
  # Ссылочный tsconfig: есть references и нет собственных files/include.
  python3 - "$1/tsconfig.json" <<'PY'
import json, re, sys
try:
    raw = open(sys.argv[1], encoding="utf-8").read()
    raw = re.sub(r"//.*?$|/\*.*?\*/", "", raw, flags=re.S | re.M)
    cfg = json.loads(raw)
except Exception:
    sys.exit(1)
refs = cfg.get("references")
own = cfg.get("files") or cfg.get("include")
sys.exit(0 if refs and not own else 1)
PY
}

stack_incremental_check() {
  local repo="$1" changed root script out rc
  changed="$(cat)"
  printf '%s\n' "$changed" | grep -qE '\.(ts|tsx|mts|cts|js|jsx|mjs)$' || return 0

  root="$(_stack_ts_root "$repo")" || return 0

  script="$(_stack_ts_script "$root" 2>/dev/null)"
  if [ -n "$script" ]; then
    out=$( (cd "$root" && npm run --silent "$script") 2>&1 ); rc=$?
    if [ "$rc" -ne 0 ]; then
      # Дедуп: в ссылочных проектах общий каталог (src/shared) входит в несколько
      # tsconfig, и одна ошибка приезжает столько раз, сколько проектов её видят.
      printf 'npm run %s (%s):\n%s\n' "$script" "${root#$repo/}" \
        "$(printf '%s\n' "$out" | grep -E 'error|Error' | awk '!seen[$0]++' | head -25)"
    fi
    return 0
  fi

  if _stack_ts_is_solution "$root"; then
    out=$( (cd "$root" && npx --no-install tsc -b --pretty false) 2>&1 ); rc=$?
  else
    out=$( (cd "$root" && npx --no-install tsc --noEmit) 2>&1 ); rc=$?
  fi
  if [ "$rc" -ne 0 ]; then
    printf 'tsc (%s):\n%s\n' "${root#$repo/}" \
      "$(printf '%s\n' "$out" | grep -E 'error TS' | awk '!seen[$0]++' | head -25)"
  fi
  return 0
}

stack_lint_file() {
  local repo="$1" path="$2" root
  case "$path" in
    *.ts|*.tsx|*.js|*.jsx|*.mjs|*.mts) ;;
    *) return 0 ;;
  esac
  for root in "$repo" "$repo/frontend" "$repo/app" "$repo/web"; do
    [ -d "$root/node_modules" ] || continue
    (cd "$root" && npx --no-install eslint --fix "$path")
    return 0
  done
}
