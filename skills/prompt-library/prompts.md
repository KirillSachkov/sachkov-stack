# Prompt Library — полный каталог (снапшот 2026-07-05)

Источник: https://code.claude.com/docs/en/prompt-library
Формат записи: **Название** [роли] (★N = «start here», порядок для новичка)
`шаблон промпта` — слоты в {фигурных скобках}, под ним примеры заполнения.
Why = паттерн, который делает промпт рабочим. Next = как закрепить насовсем.
Шаблоны английские, но работают и по-русски — структура важнее языка.

## Discover · Onboard

- **Get oriented in a new repository** ★1
  `give me an overview of this codebase: architecture, key directories, and how the pieces connect`
  Why: описывай, что хочешь узнать, а не какие файлы читать — Claude сам исследует проект.
  Next: `/init` → CLAUDE.md, чтобы контекст был в каждой сессии.

## Discover · Understand

- **Explain unfamiliar code**
  `explain what {path} does and how data flows through it. write it up as {format}`
  e.g. path=src/scheduler/queue.ts; format=an HTML page with a diagram, then open it in my browser
  Why: назови файл и формат ответа — диаграмма, буллеты, что удобнее.
  Next: output style, чтобы формат стал дефолтом.
- **Find where something happens** ★2
  `where do we {behavior}?` — e.g. behavior=validate uploaded file types
  Why: поиск по поведению, а не по имени файла — работает, когда не знаешь, где лежит.
- **Check what breaks before you delete**
  `what would break if I deleted {target}?` — e.g. target=the retryWithBackoff helper
  Why: список коллеров скажет, однострочная это чистка или координируемое изменение.
- **Trace how code evolved**
  `look through the commit history of {path} and summarize how it evolved and why`
  e.g. path=internal/auth/session.go
  Why: история коммитов — когда вопрос «почему», а не «что».
- **Scope a change before you start** [pm, design]
  `which files would I need to touch to {change}?` — e.g. change=add a dark mode toggle to settings
  Why: оцени объём до попадания в роадмап — один компонент или сквозное изменение.
- **Ask the codebase a product question** [pm]
  `I am a {role}. walk me through what happens when a user {action}, from the UI down to the result`
  e.g. role=PM; action=clicks Export to PDF
  Why: назови роль — ответ будет на нужном уровне, без чтения кода.

## Design · Plan

- **Plan a multi-file change before touching code** [pm, design]
  `plan how to refactor the {target} to {goal}. list the files you would change, but don't edit anything yet`
  e.g. target=payment module; goal=support multiple currencies
  Why: «don't edit yet» отделяет исследование от правок. Постоянно — plan mode (Shift+Tab).
- **Draft a spec by interview** [pm]
  `I want to build {feature}. interview me about implementation, UX, edge cases, and tradeoffs until we have covered everything, then write the spec to SPEC.md`
  e.g. feature=per-workspace rate limits
  Why: попроси интервьюировать себя вместо написания спеки самому.
  Next: сохранить вопросы как `/spec`-скилл.
- **Turn a meeting into tickets** [pm] — needs: tracker (MCP)
  `read {input} and write up the action items, then create a {tracker} ticket for each with acceptance criteria`
  e.g. input=@meeting-notes.md; tracker=Linear
  Why: action items прямо в трекер — ревьюишь тикеты, а не транскрипт. Next: `/tickets`-скилл.
- **Map edge cases before building** [design, pm]
  `list the error states, empty states, and edge cases for {feature} that the design needs to cover`
  e.g. feature=the file upload flow
  Why: спрашивай, чего не хватает, а не что есть — happy-path-дизайн это пропускает.

## Design · Prototype

- **Turn a mockup into a working prototype** [design, pm, marketing] — paste: mockup image
  `here is a mockup. build a working prototype I can click through, matching the layout and states shown`
  Why: кликабельный прототип отвечает на вопросы, на которые статичный мокап не может.
- **Implement from a screenshot and self-check** [design] — paste: design image; needs: browser/screenshot
  `implement this design, then take a screenshot of the result, compare it to the original, and fix any differences`
  Why: цикл верификации — рендерит, сравнивает, итерирует без тыканья в каждый зазор.

## Build · Implement

- **Follow an existing pattern**
  `look at how {example} is implemented to understand the pattern, then build {new} the same way`
  e.g. example=the GitHub webhook handler; new=a Stripe webhook handler
  Why: укажи код, который нравится, — без референса Claude берёт «общие best practices».
  Next: записать паттерн в CLAUDE.md.
- **Generate docs for undocumented code** [docs]
  `find {scope} without {format} comments and add them, matching the style already used in the file`
  e.g. scope=the public functions in src/auth/; format=JSDoc
- **Add a small, well-defined feature**
  `add a {endpoint} endpoint that returns {payload}` — e.g. endpoint=/health; payload=the app version and uptime
  Why: назови входы и выходы, не способ реализации.
- **Build a small internal tool from scratch** [pm, design, marketing, docs]
  `create a {tool} using HTML, CSS, and vanilla JavaScript, then open it in my browser`
  e.g. tool=drag-and-drop Kanban board with three columns
  Why: без проекта, фреймворка и сборки — опиши и попроси открыть.
- **Work an issue end to end** — needs: gh CLI
  `read issue #{issue}, implement the fix, and run the tests` — e.g. issue=312
  Why: дай номер, не пересказ — Claude прочтёт тикет целиком, требования не потеряются.
- **Find and update copy across the codebase** [design, docs, marketing]
  `find every place we say "{copy}" or a close variant, show me each one in context, then update them all to "{new}". leave tests and the changelog alone`
  e.g. copy=Sign up free; new=Start free trial
  Why: проси варианты и скажи, что пропустить — найдёт формулировки мимо literal search.
- **Draft a document from past examples** [docs, marketing, pm]
  `read the {examples} in {folder} to learn the structure and voice, then draft a new one for {topic}`
  e.g. examples=privacy impact assessments; folder=legal/pia/; topic=the new analytics integration
  Why: папка готовых работ вместо описания стиля. Next: сохранить голос как скилл.

## Build · Test

- **Write tests, run them, fix failures** ★4
  `write tests for {path}, run them, and fix any failures` — e.g. path=app/parsers/feed.py
  Why: write+run+fix вместе — итерирует без остановок за инструкциями. Next: `/init`.
- **Drive implementation from tests**
  `write tests for {feature} first, then implement it until they pass` — e.g. feature=the password reset flow
  Why: TDD — тесты определяют «готово».
- **Fill gaps from a coverage report**
  `read {report} and add tests for the lowest-covered files until each is above {target}%`
  e.g. report=coverage/coverage-summary.json; target=80
  Why: реальные цифры вместо угадывания. Next: `/goal` до достижения порога.

## Build · Refactor

- **Migrate a pattern across the codebase**
  `migrate everything from {from} to {to}: identify every place that needs to change, then make the changes`
  e.g. from=the old logging API; to=the structured logger
  Why: «сначала перечисли все места» — список call sites в ответе, можно проверить полноту.
- **Port code to another language**
  `port {source} to {target}, keeping the same {keep}`
  e.g. source=this Python module; target=Rust; keep=public API and test behavior
  Why: скажи, что сохранить — контракт для проверки порта.
- **Optimize against a measurable target** [data]
  `optimize {target} to bring {metric} from {current} down to under {goal}`
  e.g. target=the search query; metric=p95 latency; current=2s; goal=500ms
  Why: метрика+цель = чёткое определение готовности. Next: `/goal`.
- **Fix a precise visual bug** [design]
  `the {element} extends {amount} beyond the {container} on {viewport}. fix it.`
  e.g. element=login button; amount=20px; container=card border; viewport=mobile
  Why: точный фидбек → точный фикс: элемент, измерение, вьюпорт.

## Build · Review

- **Review your changes before you commit** ★5
  `review my uncommitted changes and flag anything that looks risky before I commit`
  Why: ловит проблемы, пока дёшево; читает файлы целиком, не только diff. Next: `/code-review`.
- **Review a pull request** — needs: gh CLI
  `review PR #{pr} and summarize what changed, then list any concerns` — e.g. pr=247
  Why: ревью со всей кодбазой в контексте, не только diff.
- **Review infrastructure changes before applying** [security, ops] — paste: plan output
  `here is my Terraform plan output. what is this going to do, and is anything here going to cause problems?`
  Why: plan-output плотный — получишь человеческое резюме до apply.
- **Run a security review with a subagent** [security]
  `use a subagent to review {path} for security issues and report what it finds` — e.g. path=src/api/
  Why: сабагент в своём контексте — длинный аудит не забивает основную сессию.
- **Catch issues before formal review** [marketing, docs]
  `review {file} for {concerns} and list anything I should fix before it goes to {reviewer}`
  e.g. file=launch-post.md; concerns=unsupported claims, missing attributions, and brand-guideline issues; reviewer=legal
  Why: первый проход до человека; назови конкретные concerns. Next: чеклист как скилл.

## Build · Steer

- **Course-correct a wrong approach**
  `that is not right: {feedback}. try a different approach`
  e.g. feedback=the function signature needs to stay backward-compatible
  Why: назови пропущенное ограничение, а не просто «неправильно». Next: Esc×2 → rewind.
- **Narrow the scope of a change**
  `that is too much. keep only the changes to {scope} and undo your other edits`
  e.g. scope=the validation logic in src/forms/
  Why: направление верное, но слишком широко — граница вместо полного отката.
- **Turn a correction into a rule**
  `you keep {mistake}. add a rule to CLAUDE.md so this stops happening`
  e.g. mistake=using default exports when this project uses named exports
  Why: поправка в чате не шарится; правило в CLAUDE.md читается каждую сессию. Next: `/memory`.

## Ship · Git

- **Resolve merge conflicts**
  `resolve the merge conflicts in this branch and explain what you kept from each side`
  Why: скажи желаемое состояние + попроси reasoning — merge становится ревьюабельным.
- **Commit with a generated message**
  `commit these changes with a message that summarizes what I did`
  Why: сообщение из diff, в стиле коммитов репозитория.
- **Open a pull request from a ticket** — needs: tracker (MCP)
  `find the {tracker} ticket about {topic} and open a PR that implements it`
  e.g. tracker=Linear; topic=the login timeout
  Why: один промпт: читает спеку, делает изменение, открывает PR.

## Ship · Release

- **Draft release notes from git history** [pm, docs, marketing]
  `compare {from} to {to} and draft release notes grouped by feature, fix, and breaking change`
  e.g. from=v2.3.0; to=v2.4.0
  Why: две точки отсчёта + структура. Next: `/changelog`-скилл.
- **Write a CI workflow** [ops]
  `write a GitHub Actions workflow that {steps} on every push to {branch}`
  e.g. steps=runs the tests and deploys to staging; branch=main
  Why: опиши когда и что — YAML под команды проекта сгенерируется.

## Operate · Debug

- **Find and fix a failing test** ★3
  `the {test} test is failing, find out why and fix it` — e.g. test=UserAuth
  Why: опиши симптом — не нужно знать, какой файл сломан.
- **Investigate a reported error** [ops]
  `users are seeing {symptom} on {where}. investigate and tell me what is going on`
  e.g. symptom=500 errors; where=/api/settings
  Why: симптом + локация; stack traces/логи — вставляй, если есть.
- **Fix a build error at the root** [ops] — paste: error output
  `here is a build error. fix the root cause and verify the build succeeds`
  Why: root cause + verify — против поверхностных заплаток, глушащих ошибку.

## Operate · Incident

- **Investigate a production incident** [ops, security]
  `{symptom}. check the logs, recent deploys, and config changes, then tell me the most likely cause`
  e.g. symptom=the checkout endpoint started returning 500s an hour ago
  Why: перечисли источники улик для корреляции, а не шаги. Next: Sentry/логи через MCP.
- **Diagnose from a console screenshot** [ops, data] — paste: screenshot
  `here is a screenshot of {console}. walk me through why {resource} is failing and give me the exact commands to fix it`
  e.g. console=the GCP Kubernetes dashboard; resource=this pod
  Why: консоль показывает проблему, но не команды — скриншот → kubectl/gcloud/aws.
- **Query logs in plain English** [security, ops, data] — needs: db/log store (MCP)
  `show me all {events} for {scope} over {timeframe}. write the query, run it, and tell me what stands out`
  e.g. events=failed logins; scope=the auth service; timeframe=the past 24 hours
  Why: задай вопрос вместо SQL — покажет и запрос, и результат.

## Operate · Data

- **Analyze a data file** [data, pm, marketing] — paste/@ csv
  `read {file}, summarize the key patterns, and write the results to {output}`
  e.g. file=@reports/q1-signups.csv; output=an HTML page with charts, then open it in my browser
  Why: разовый вопрос не требует разового скрипта.
- **Generate variations from performance data** [marketing, data] — paste/@ csv
  `read {file}, find the underperforming {items}, and generate {n} new variations that stay under {limit} characters`
  e.g. file=@ads-performance.csv; items=headlines; n=20; limit=90
  Why: ограничение в начале — генерация не вылезет за лимит.

## Operate · Automate

- **Turn a recurring task into a skill**
  `create a /{name} skill for this project that {steps}`
  e.g. name=ship; steps=runs the linter and tests, then drafts a commit message
  Why: назови шаги один раз — переиспользуй как команду.
- **Add a hook for repeat behavior**
  `write a hook that {action} after every {event}`
  e.g. action=runs prettier; event=edit to a .ts or .tsx file
  Why: хук делает поведение автоматическим, а не «надо не забыть попросить».
- **Connect a tool with MCP**
  `set up the {server} MCP server so you can read my {data} directly`
  e.g. server=Sentry; data=error reports
  Why: подключи источник один раз вместо вставки данных каждую сессию.
- **Capture what to remember for next time** [pm, docs]
  `summarize what we did this session and suggest what to add to CLAUDE.md`
  Why: спроси до того, как забыл, — Claude знает, что пришлось выяснять в этой сессии.
