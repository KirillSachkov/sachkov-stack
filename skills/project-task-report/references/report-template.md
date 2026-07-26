# Project task report v1

Copy the whole block to the task's canonical destination. Replace every instruction comment and the
revision placeholder. The validator rejects empty, comment-only, placeholder, missing, and duplicate
required sections.

For PR/MR code work, `Revision` is the final source-branch HEAD. For a tracker-free brain task,
use the repository HEAD immediately before the separate closure commit. For a result without a
code revision, use a concrete task version or dated result identifier. Keep the block as visible
Markdown; never wrap it in an HTML comment or code fence.

```markdown
<!-- project-task-report:v1 -->
Revision: `<final code SHA or concrete result version>`

## Итог
<!-- What is now true for the owner or user? -->

## Затронутые части проекта
<!-- Which product, workflow, data, infrastructure, or documentation areas were affected? -->

## Бизнес-логика
<!-- What behavior or rules changed? Write "Нет." if none changed. -->

## Что изменено
<!-- Describe the important implementation or decision in plain language. -->

## Проверка
<!-- List fresh automated, manual, independent-review, and CI evidence. -->

## Не проверено и риски
<!-- Name gaps and residual risks. Write "Нет." only when that is accurate. -->

## Интеграция
<!-- State branch and tracker/PR/MR status plus the owner's next action. -->
<!-- /project-task-report -->
```
