# Стек: .NET
#
# Контракт стека (одинаков для всех стеков):
#   stack_incremental_check <repo>   изменённые пути читает со stdin, провалы печатает в stdout
#   stack_lint_file <repo> <path>    линт одного файла, fire-and-forget

stack_incremental_check() {
  local repo="$1" changed cs projs p out
  changed="$(cat)"
  cs=$(printf '%s\n' "$changed" | grep -E '\.cs$' || true)
  [ -z "$cs" ] && return 0

  # Собираем ближайшие к изменённым файлам проекты, максимум три: гейт должен быть
  # быстрым. Пропускаем невосстановленные (нет obj/) — их поймает CI.
  projs=$(while IFS= read -r f; do
    [ -n "$f" ] || continue
    d=$(dirname "$repo/$f")
    while [ "$d" != "$repo" ] && [ "$d" != "/" ]; do
      p=$(ls "$d"/*.csproj 2>/dev/null | head -1)
      if [ -n "$p" ]; then printf '%s\n' "$p"; break; fi
      d=$(dirname "$d")
    done
  done <<< "$cs" | sort -u | head -3)

  for p in $projs; do
    [ -d "$(dirname "$p")/obj" ] || continue
    out=$(dotnet build "$p" --nologo -v q 2>&1 | grep -E ': error' | head -15)
    [ -n "$out" ] && printf 'dotnet build %s:\n%s\n' "$(basename "$p")" "$out"
  done
  return 0
}

stack_lint_file() {
  local repo="$1" path="$2"
  case "$path" in
    *.cs) (cd "$repo" && dotnet format --include "$path" --no-restore) ;;
  esac
}
