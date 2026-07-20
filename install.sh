#!/usr/bin/env bash
set -euo pipefail

# Установщик sachkov-stack: скиллы, глобальный конфиг, скелет мозга.
#
# Использование:
#   ./install.sh <skill-name|all> [--claude] [--codex]   # скиллы (без флагов: оба рантайма)
#   ./install.sh config [--claude] [--codex]             # CLAUDE.md/AGENTS.md + хуки
#   ./install.sh brain <путь>                            # создать мозг из brain-template
#
# Существующие файлы бэкапятся с таймстампом. Зависимости: bash, git (для brain),
# jq — только для работы хуков (не для установки).

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
skills_dir="$repo_dir/skills"
stamp() { date +%Y%m%d-%H%M%S; }

usage() {
  sed -n '4,10p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//' >&2
  echo "Доступные скиллы:" >&2
  for d in "$skills_dir"/*/; do
    [ -f "$d/SKILL.md" ] && echo "  - $(basename "$d")" >&2
  done
}

backup_if_exists() {
  local target="$1"
  if [ -e "$target" ]; then
    local backup="${target}.backup-$(stamp)"
    mv "$target" "$backup"
    echo "  бэкап: $backup"
  fi
}

install_skill() {
  local name="$1" target_root="$2"
  local source_dir="$skills_dir/$name" target_dir="$target_root/$name"
  if [ ! -f "$source_dir/SKILL.md" ]; then
    echo "Скилл не найден: $name" >&2
    exit 1
  fi
  mkdir -p "$target_root"
  backup_if_exists "$target_dir"
  cp -a "$source_dir" "$target_dir"
  if [ -d "$target_dir/scripts" ]; then
    find "$target_dir/scripts" -type f \( -name '*.sh' -o -name '*.py' -o -name '*.js' \) -exec chmod +x {} +
  fi
  echo "Установлен $name -> $target_dir"
}

install_config() {
  local want_claude="$1" want_codex="$2"
  if [ "$want_claude" -eq 1 ]; then
    mkdir -p "$HOME/.claude/hooks"
    for f in CLAUDE.md AGENTS.md; do
      backup_if_exists "$HOME/.claude/$f"
      cp "$repo_dir/global-config/$f" "$HOME/.claude/$f"
      echo "Установлен ~/.claude/$f"
    done
    for h in brain-anchor.sh brain-reminder.sh; do
      backup_if_exists "$HOME/.claude/hooks/$h"
      cp "$repo_dir/global-config/hooks/$h" "$HOME/.claude/hooks/$h"
      chmod +x "$HOME/.claude/hooks/$h"
      echo "Установлен ~/.claude/hooks/$h"
    done
    echo ""
    echo "ВАЖНО: хуки подключаются вручную — перенесите блоки env и hooks из"
    echo "  $repo_dir/global-config/settings.example.json"
    echo "в свой ~/.claude/settings.json (путь к мозгу — env.BRAIN), затем перезапустите Claude Code."
  fi
  if [ "$want_codex" -eq 1 ]; then
    mkdir -p "${CODEX_HOME:-$HOME/.codex}"
    backup_if_exists "${CODEX_HOME:-$HOME/.codex}/AGENTS.md"
    cp "$repo_dir/global-config/AGENTS.md" "${CODEX_HOME:-$HOME/.codex}/AGENTS.md"
    echo "Установлен ${CODEX_HOME:-$HOME/.codex}/AGENTS.md"
  fi
  echo ""
  echo "Откройте установленные файлы и замените плейсхолдеры <...> под себя."
}

install_brain() {
  local target="$1"
  if [ -z "$target" ]; then
    echo "Укажите путь: ./install.sh brain ~/Work/brain" >&2
    exit 2
  fi
  if [ -e "$target" ] && [ -n "$(ls -A "$target" 2>/dev/null)" ]; then
    echo "Каталог $target существует и не пуст — мозг не создан (ничего не перезаписываю)." >&2
    exit 1
  fi
  mkdir -p "$target"
  cp -a "$repo_dir/brain-template/." "$target/"
  git -C "$target" init -q
  git -C "$target" add -A
  git -C "$target" commit -qm "brain: initial skeleton from sachkov-stack"
  echo "Мозг создан: $target (git-репозиторий, начальный коммит сделан)."
  echo "Дальше: заполните memory/profile.md и memory/projects.md, задайте BRAIN=$target в env хуков."
}

[ $# -lt 1 ] && { usage; exit 2; }
cmd="$1"; shift

case "$cmd" in
  brain)
    install_brain "${1:-}"
    ;;
  config)
    want_claude=0; want_codex=0
    for arg in "$@"; do
      case "$arg" in
        --claude) want_claude=1 ;;
        --codex)  want_codex=1 ;;
        *) usage; exit 2 ;;
      esac
    done
    if [ "$want_claude" -eq 0 ] && [ "$want_codex" -eq 0 ]; then want_claude=1; want_codex=1; fi
    install_config "$want_claude" "$want_codex"
    ;;
  *)
    want_claude=0; want_codex=0
    for arg in "$@"; do
      case "$arg" in
        --claude) want_claude=1 ;;
        --codex)  want_codex=1 ;;
        *) usage; exit 2 ;;
      esac
    done
    if [ "$want_claude" -eq 0 ] && [ "$want_codex" -eq 0 ]; then want_claude=1; want_codex=1; fi
    targets=()
    [ "$want_claude" -eq 1 ] && targets+=("$HOME/.claude/skills")
    [ "$want_codex" -eq 1 ] && targets+=("${CODEX_HOME:-$HOME/.codex}/skills")
    if [ "$cmd" = "all" ]; then
      names=()
      for d in "$skills_dir"/*/; do
        [ -f "$d/SKILL.md" ] && names+=("$(basename "$d")")
      done
    else
      names=("$cmd")
    fi
    for target_root in "${targets[@]}"; do
      for name in "${names[@]}"; do
        install_skill "$name" "$target_root"
      done
    done
    echo ""
    echo "Готово. Перезапустите Claude Code / Codex, чтобы список скиллов обновился."
    ;;
esac
