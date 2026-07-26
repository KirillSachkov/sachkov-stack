#!/usr/bin/env bash
# Stop-гейт: не даёт агенту завершить ход с заведомо сломанной работой.
#
# Две фазы:
#   грязное дерево  -> инкрементальная проверка изменённых файлов средствами стека
#                      (`stack_incremental_check` из .harness/stack.sh);
#   чистое дерево   -> verify-команды acceptance-критериев из .task-contract.json,
#                      если поверх базовой ветки есть локальные коммиты.
#
# Контракт: JSON со stdin, причина в stderr, exit 2 не даёт завершить ход, exit 0 пропускает.
# Одинаков для Claude и Codex; отличается только единица таймаута в обвязке рантайма
# (Claude миллисекунды, Codex секунды).
#
# Аварийный обход: HARNESS_SKIP_STOP_GATE=1. Только по явной просьбе владельца.

set -u

input=$(cat)
py() { printf '%s' "$input" | python3 -c "$1" 2>/dev/null; }

# Анти-цикл: хук, вызванный из-за собственного exit 2, не должен зацикливаться.
active=$(py "import json,sys;print(json.load(sys.stdin).get('stop_hook_active',False))")
case "$active" in True|true) exit 0;; esac
[ "${HARNESS_SKIP_STOP_GATE:-}" = "1" ] && exit 0

cwd=$(py "import json,sys;print(json.load(sys.stdin).get('cwd',''))")
[ -z "$cwd" ] && cwd="${CLAUDE_PROJECT_DIR:-$PWD}"
repo=$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null) || exit 0

# shasum на macOS, sha256sum на Linux: гейт обязан работать и там, и там.
if command -v shasum >/dev/null 2>&1; then sha() { shasum -a 256; }; else sha() { sha256sum; }; fi
key() { printf '%s' "$repo" | sha | cut -c1-12; }

# Стек подключается опционально: без него работает только контрактная фаза.
STACK="$repo/.harness/stack.sh"
# shellcheck source=/dev/null
[ -f "$STACK" ] && . "$STACK"

BASE_BRANCH="$(git -C "$repo" config --get harness.baseBranch 2>/dev/null || echo "")"
if [ -z "$BASE_BRANCH" ] && [ -f "$repo/.harness/harness.lock" ]; then
  BASE_BRANCH=$(python3 -c \
    "import json,sys;print(json.load(open(sys.argv[1],encoding='utf-8')).get('base_branch',''))" \
    "$repo/.harness/harness.lock" 2>/dev/null)
fi
[ -z "$BASE_BRANCH" ] && BASE_BRANCH="main"

dirty_all=$(git -C "$repo" status --porcelain 2>/dev/null)

# ── Чистое дерево: контрактная фаза ─────────────────────────────────────────
if [ -z "$dirty_all" ]; then
  contract="$repo/.task-contract.json"
  [ -f "$contract" ] || exit 0
  head_sha=$(git -C "$repo" rev-parse HEAD 2>/dev/null) || exit 0
  base=$(git -C "$repo" merge-base "origin/$BASE_BRANCH" HEAD 2>/dev/null || echo "")
  # Нет локальных коммитов поверх базовой ветки, значит проверять нечего.
  [ -n "$base" ] && [ "$head_sha" = "$base" ] && exit 0

  chash=$( { printf '%s' "$head_sha"; cat "$contract"; } | sha | cut -c1-16)
  cmarker="${TMPDIR:-/tmp}/harness-contract-$(key)"
  [ -f "$cmarker" ] && [ "$(cat "$cmarker" 2>/dev/null)" = "$chash" ] && exit 0

  fails=$(python3 - "$contract" "$repo" <<'PY' 2>&1
import json, subprocess, sys
contract, repo = sys.argv[1], sys.argv[2]
try:
    data = json.load(open(contract, encoding="utf-8"))
except Exception as e:
    print(f"CONTRACT-PARSE: {e} — почини .task-contract.json или удали его")
    sys.exit(0)
for ac in (data.get("acceptance") or [])[:10]:
    cmd = (ac.get("verify") or "").strip()
    if not cmd:
        continue
    try:
        r = subprocess.run(["bash", "-lc", cmd], cwd=repo,
                           capture_output=True, text=True, timeout=900)
    except subprocess.TimeoutExpired:
        print(f"{ac.get('id', 'AC?')}: `{cmd}` -> timeout 900s")
        continue
    if r.returncode != 0:
        tail = (r.stdout + r.stderr).strip().splitlines()[-8:]
        print(f"{ac.get('id', 'AC?')}: `{cmd}` -> exit {r.returncode}")
        for line in tail:
            print(f"  {line}")
PY
)
  if [ -n "$fails" ]; then
    {
      echo "STOP-ГЕЙТ (task-contract): verify-команды acceptance-критериев провалены на текущем HEAD."
      echo "Почини код или обнови контракт через владельца:"
      printf '%s\n' "$fails"
    } >&2
    exit 2
  fi
  printf '%s' "$chash" > "$cmarker"
  exit 0
fi

# ── Грязное дерево: инкрементальная проверка стеком ─────────────────────────
# Без стека проверять нечем: пропускаем, CI поймает.
command -v stack_incremental_check >/dev/null 2>&1 || type stack_incremental_check >/dev/null 2>&1 || exit 0

# Список изменённых путей, включая удаления и переименования.
changed=$(printf '%s\n' "$dirty_all" | sed 's/^...//;s/.* -> //')

state_hash=$( {
  git -C "$repo" rev-parse HEAD 2>/dev/null
  git -C "$repo" status --porcelain
  git -C "$repo" diff HEAD 2>/dev/null
} | sha | cut -d' ' -f1)
marker="${TMPDIR:-/tmp}/harness-stopgate-$(key)"
[ -f "$marker" ] && [ "$(cat "$marker" 2>/dev/null)" = "$state_hash" ] && exit 0

fail=$(printf '%s\n' "$changed" | stack_incremental_check "$repo" 2>&1)

if [ -n "$fail" ]; then
  {
    echo "STOP-ГЕЙТ: изменённые файлы не проходят проверку."
    echo "Почини до завершения хода или объясни владельцу, почему это ожидаемо:"
    printf '%s\n' "$fail"
  } >&2
  exit 2
fi

printf '%s' "$state_hash" > "$marker"
exit 0
