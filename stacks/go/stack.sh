# Стек: Go
#
# go build по пакетам изменённых файлов: быстро благодаря кэшу сборки и ловит и удаления.

stack_incremental_check() {
  local repo="$1" changed pkgs out
  changed="$(cat)"
  printf '%s\n' "$changed" | grep -qE '\.go$' || return 0
  command -v go >/dev/null 2>&1 || return 0

  pkgs=$(printf '%s\n' "$changed" | grep -E '\.go$' | xargs -n1 dirname 2>/dev/null | sort -u | head -5)
  for p in $pkgs; do
    [ -d "$repo/$p" ] || continue
    out=$( (cd "$repo" && go build "./$p" ) 2>&1 | head -15)
    [ -n "$out" ] && printf 'go build ./%s:\n%s\n' "$p" "$out"
  done
  return 0
}

stack_lint_file() {
  local repo="$1" path="$2"
  case "$path" in
    *.go) command -v gofmt >/dev/null 2>&1 && gofmt -w "$repo/$path" 2>/dev/null || true ;;
  esac
}
