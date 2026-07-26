---
name: prompt-library
description: Use when phrasing or structuring any task for Claude Code — a vague or underspecified request that needs shaping, the user asks "как сформулировать" / "how should I ask for X", starting an unfamiliar kind of work (onboarding a repo, incident, migration, release, spec, review), writing prompts for subagents/workflows, or suggesting what Claude Code can do next.
metadata:
  source: https://code.claude.com/docs/en/prompt-library
  snapshot: 2026-07-05
---

# Prompt Library — паттерны формулировки задач

Локальный снапшот официальной библиотеки промптов Claude Code (52 промпта,
5 фаз SDLC, 15 категорий). Полный каталог — в [prompts.md](prompts.md).

**Принцип использования: постоянно.** Получил задачу → определи фазу/категорию →
проверь, применён ли паттерн соответствующего промпта. владелец спрашивает «как
попросить» или даёт расплывчатый запрос → подбери конкретный промпт из каталога.

## 6 паттернов, почему эти промпты работают

1. **Outcome, не шаги.** Скажи, что нужно получить, — файлы Claude найдёт сам.
   `add rate limiting to the public API and make sure existing tests still pass`
2. **Дай способ самопроверки.** run / test / compare / verify в том же промпте —
   Claude итерирует, а не останавливается после первой попытки.
   `write the migration, run it against the dev database, and confirm the schema matches`
3. **Укажи референс.** Существующий файл/тест/паттерн → новый код консистентен.
   `add a settings page that follows the same layout as the profile page`
4. **Измеримая цель.** Метрика + порог = однозначное «готово».
   `get the bundle size under 200KB and show me what you removed`
5. **Дай артефакт.** Ошибки, логи, скриншоты, plan-output — вставляй сырьё или `@файл`,
   а не пересказ. `why is the build failing? @build.log`
6. **Скажи формат ответа.** Формат, длина, аудитория — под то, как ответ будет использован.

## Карта фаз → категории

| Фаза | Категории |
|---|---|
| Discover | Onboard, Understand |
| Design | Plan, Prototype |
| Build | Implement, Test, Refactor, Review, Steer |
| Ship | Git, Release |
| Operate | Debug, Incident, Data, Automate |

Алиасы симптомов → категория (не очевидно из названий):
- тормозит / медленно / slow / performance / latency / оптимизировать → Build·Refactor (Optimize against a measurable target)
- миграция / переезд на новый API / переписать на другой язык → Build·Refactor
- прод упал / 500 / инцидент / логи → Operate·Incident; падает тест или билд → Operate·Debug
- «надоело повторять» / рутина → Operate·Automate (скилл, хук, MCP)
- baseline для measurable-цели неизвестен → сначала замерь или спроси порог (паттерн 4)

## Как применять к входящей задаче

- Запрос без критерия готовности → добавь/предложи измеримую цель или self-check-цикл (паттерны 2, 4).
- Запрос «сделай как-нибудь» → спроси/найди референс (паттерн 3).
- Пересказ ошибки словами → попроси артефакт (паттерн 5).
- Повторяющаяся просьба → предложи промпт из категории Automate (скилл/хук/MCP).
- Прежде чем советовать формулировку — открой prompts.md и возьми готовый шаблон со слотами.

## Обновление снапшота

Источник живёт в доках: https://code.claude.com/docs/en/prompt-library
Устарел (новые промпты в доках) → перекачать WebFetch'ем и пересобрать prompts.md.
