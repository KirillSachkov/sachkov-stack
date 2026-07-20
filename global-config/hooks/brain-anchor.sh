#!/usr/bin/env bash
# SessionStart-хук: якорь мозга как стартовой точки анализа.
# Срабатывает на startup|resume|compact. Смысл compact-ветки: compaction вытесняет
# директивы из контекста, хук реинжектит их заново после каждого сжатия.
#
# Настройка: задайте путь к мозгу (переменная BRAIN или правка строки ниже).
# Зависимость: jq (для чтения source из stdin-JSON; без jq считаем startup).
BRAIN="${BRAIN:-$HOME/Work/brain}"

input=$(cat 2>/dev/null)
source=$(printf '%s' "$input" | jq -r '.source // "startup"' 2>/dev/null || echo startup)

if [ "$source" = "compact" ]; then
  echo "[reinject after compaction] Контекст был сжат — восстанавливаю директивы:"
fi

cat <<EOF
## Мозг — обязательная стартовая точка (MUST)
- Канонический мозг: $BRAIN/ (высшая авторитетность: расходится с предположением — прав мозг).
- Перед кросс-проектным ответом или вопросом о статусе: memory/projects.md и релевантная wiki/*.md.
- Задачи в очереди: tasks/active/ и tasks/inbox/.
- Новое durable-знание после работы — обратно в memory/ или wiki/, с [[wikilinks]].
EOF

# Показать хвост очереди задач, если мозг существует (безвредно, если нет).
if [ -d "$BRAIN/tasks/active" ]; then
  n=$(find "$BRAIN/tasks/active" -name '*.md' 2>/dev/null | wc -l | tr -d ' ')
  [ "$n" -gt 0 ] && echo "- Сейчас в tasks/active: $n задач(и)."
fi
exit 0
