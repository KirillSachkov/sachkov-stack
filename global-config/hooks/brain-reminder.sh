#!/usr/bin/env bash
# UserPromptSubmit-хук: короткое напоминание про мозг каждый N-й промпт.
# Подстраховка между компактами (после компакта эстафету держит brain-anchor.sh).
# Настройка: EVERY_N (по умолчанию 3). Зависимость: jq.
EVERY_N="${BRAIN_REMINDER_EVERY_N:-3}"

input=$(cat 2>/dev/null)
sid=$(printf '%s' "$input" | jq -r '.session_id // "unknown"' 2>/dev/null || echo unknown)
cwd=$(printf '%s' "$input" | jq -r '.cwd // ""' 2>/dev/null || echo "")

# Молчать в изолированных воркспейсах/автоворкерах — добавьте свои паттерны через |
case "$cwd" in
  *worktree*) exit 0 ;;
esac

cnt_file="${TMPDIR:-/tmp}/brain-reminder-${sid}"
cnt=$(cat "$cnt_file" 2>/dev/null || echo 0)
cnt=$((cnt + 1))
echo "$cnt" > "$cnt_file"

if [ $((cnt % EVERY_N)) -eq 0 ]; then
  echo "Напоминание: стартовая точка анализа — мозг (memory/projects.md, wiki/). Сверься перед содержательным ответом, инструмент бери по реестру скиллов, не по догадке."
fi
exit 0
