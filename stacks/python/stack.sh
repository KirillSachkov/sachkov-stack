# Стек: Python
#
# Гейт держим дешёвым: синтаксис плюс ruff, если он есть. Тайпчек (mypy, pyright) обычно
# слишком медленный для хука на каждый ход и живёт в CI или в verify-командах контракта.

stack_incremental_check() {
  local repo="$1" changed py out
  changed="$(cat)"
  py=$(printf '%s\n' "$changed" | grep -E '\.py$' || true)
  [ -z "$py" ] && return 0

  # Синтаксис: ловит опечатку раньше любого линтера и не требует установленных тулов.
  while IFS= read -r f; do
    [ -f "$repo/$f" ] || continue
    out=$(python3 -m py_compile "$repo/$f" 2>&1) || printf 'py_compile %s:\n%s\n' "$f" "$out"
  done <<< "$py"

  if command -v ruff >/dev/null 2>&1; then
    out=$( (cd "$repo" && printf '%s\n' "$py" | tr '\n' '\0' | xargs -0 ruff check --quiet 2>&1) | head -20)
    [ -n "$out" ] && printf 'ruff check:\n%s\n' "$out"
  fi
  return 0
}

stack_lint_file() {
  local repo="$1" path="$2"
  case "$path" in
    *.py) command -v ruff >/dev/null 2>&1 && (cd "$repo" && ruff format "$path" && ruff check --fix "$path") ;;
  esac
}
