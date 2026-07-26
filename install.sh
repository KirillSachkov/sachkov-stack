#!/usr/bin/env bash
set -euo pipefail

# Установщик sachkov-stack.
#
#   ./install.sh global  [--claude] [--codex]    глобальный канон + детект харнеса
#   ./install.sh skills  [--claude] [--codex]    портируемые скиллы
#   ./install.sh brain   <путь>                  скелет мозга
#   ./install.sh project <путь> --stack <имя>    харнес в репозиторий (обёртка bin/harness)
#
# Без флагов рантайма ставится в оба. Существующие файлы бэкапятся с таймстампом,
# ничего не затирается молча. Зависимости: bash, python3 (для bin/harness), git (для brain).

repo="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

usage() { sed -n '5,12p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//' >&2; exit 1; }

# Бэкап только если содержимое реально отличается: иначе повторный прогон засоряет
# каталог копиями одного и того же.
backup() {
  local f="$1" src="$2"
  [ -e "$f" ] || return 0
  if [ -d "$f" ] && [ -d "$src" ]; then
    diff -rq "$f" "$src" >/dev/null 2>&1 && return 0
  elif [ -f "$f" ] && [ -f "$src" ]; then
    cmp -s "$f" "$src" && return 0
  fi
  local b="$f.bak.$(date +%Y%m%d-%H%M%S)"
  cp -R "$f" "$b"
  echo "  бэкап: $b"
}

install_global() {
  local claude="$1" codex="$2"
  if [ "$claude" = yes ]; then
    mkdir -p "$HOME/.claude/hooks"
    local out="$HOME/.claude/CLAUDE.md" tmp
    tmp="$(mktemp)"
    cat "$repo/global/AGENTS-core.md" > "$tmp"
    printf '\n' >> "$tmp"
    cat "$repo/global/CLAUDE-runtime.md" >> "$tmp"
    backup "$out" "$tmp"
    mv "$tmp" "$out"
    cp "$repo/global/harness-detect.sh" "$HOME/.claude/hooks/harness-detect.sh"
    chmod +x "$HOME/.claude/hooks/harness-detect.sh"
    echo "Claude Code: $out + hooks/harness-detect.sh"
  fi
  if [ "$codex" = yes ]; then
    mkdir -p "$HOME/.codex"
    local out="$HOME/.codex/AGENTS.md" tmp
    tmp="$(mktemp)"
    cat "$repo/global/AGENTS-core.md" > "$tmp"
    printf '\n' >> "$tmp"
    cat "$repo/global/AGENTS-runtime.md" >> "$tmp"
    backup "$out" "$tmp"
    mv "$tmp" "$out"
    cp "$repo/global/harness-detect.sh" "$HOME/.codex/harness-detect.sh"
    chmod +x "$HOME/.codex/harness-detect.sh"
    echo "Codex CLI: $out + harness-detect.sh"
  fi
  cat <<'HOOKS'

Осталось подключить детект руками — свои настройки рантайма мы не переписываем.

  ~/.claude/settings.json, событие SessionStart (таймаут в МИЛЛИСЕКУНДАХ):
    {"type":"command","command":"bash ~/.claude/hooks/harness-detect.sh --json","timeout":5000}

  ~/.codex/hooks.json, событие SessionStart (таймаут в СЕКУНДАХ):
    {"type":"command","command":"bash ~/.codex/harness-detect.sh","timeout":5}
HOOKS
}

install_skills() {
  local claude="$1" codex="$2" n=0
  for src in "$repo"/skills/*/; do
    [ -d "$src" ] || continue
    local name; name="$(basename "$src")"
    if [ "$claude" = yes ]; then
      mkdir -p "$HOME/.claude/skills"
      backup "$HOME/.claude/skills/$name" "${src%/}"
      rm -rf "$HOME/.claude/skills/$name"
      cp -R "$src" "$HOME/.claude/skills/$name"
    fi
    if [ "$codex" = yes ]; then
      mkdir -p "$HOME/.agents/skills"
      backup "$HOME/.agents/skills/$name" "${src%/}"
      rm -rf "$HOME/.agents/skills/$name"
      cp -R "$src" "$HOME/.agents/skills/$name"
    fi
    n=$((n + 1))
  done
  echo "скиллов установлено: $n"
}

install_brain() {
  local dest="$1"
  [ -n "$dest" ] || usage
  if [ -e "$dest" ] && [ -n "$(ls -A "$dest" 2>/dev/null)" ]; then
    echo "install.sh: $dest не пуст, мозг туда не разворачиваю" >&2
    exit 1
  fi
  mkdir -p "$dest"
  cp -R "$repo/brain-template/." "$dest/"
  git -C "$dest" init --quiet
  echo "мозг развёрнут: $dest"
  echo "дальше: git -C \"$dest\" add -A && git -C \"$dest\" commit -m 'brain: skeleton'"
  echo "и укажи путь агенту: export AGENT_BRAIN=\"$dest\""
}

[ $# -ge 1 ] || usage
cmd="$1"; shift

case "$cmd" in
  global|skills)
    claude=no; codex=no
    for a in "$@"; do
      case "$a" in
        --claude) claude=yes ;;
        --codex)  codex=yes ;;
        *) usage ;;
      esac
    done
    if [ "$claude" = no ] && [ "$codex" = no ]; then claude=yes; codex=yes; fi
    if [ "$cmd" = global ]; then
      install_global "$claude" "$codex"
    else
      install_skills "$claude" "$codex"
    fi
    ;;
  brain)   install_brain "${1:-}" ;;
  project) exec python3 "$repo/bin/harness" init "$@" ;;
  *)       usage ;;
esac
