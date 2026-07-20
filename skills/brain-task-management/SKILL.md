---
name: brain-task-management
description: Use when the user asks to create, update, close, list, or schedule a task in the brain repository — the lifecycle inbox → active → done, date resolution, verification, and git sync.
---

# Brain Task Management

Tasks live in the brain repository (`${BRAIN:-$HOME/Work/brain}`) under
`tasks/<status>/<file>.md`. Statuses are directories: `inbox/` (captured, not started),
`active/` (in progress, keep under a WIP cap of ~15), `done/` (closed, kept as history).

## Creating a task

1. **Resolve dates with a tool.** "Today", "tomorrow", a weekday — run `date` first,
   write the absolute date into the file. Never guess.
2. **One outcome per task.** A broad request ("sort out project X") is a decomposition:
   several class-level tasks, not one oversized task. But don't shred one outcome into
   micro-tasks either.
3. **File from the template** (`tasks/TEMPLATE.md`): frontmatter `title`, `status`,
   `project`, `assignee`, `created`; body — «Зачем», «Критерий готовности», «Лог».
   Filename: `YYYY-MM-DD-short-slug.md`, slug in lowercase ASCII.
4. **Route first.** If the task belongs to a project with its own tracker — create it in
   that tracker and do NOT duplicate it in the brain (or close the brain task in the same
   commit when promoting). Brain `tasks/` is for everything without a tracker.
5. New tasks land in `inbox/`; move to `active/` only when work actually starts.

## Updating and closing

- Progress → append a dated line to «Лог» in the task file.
- Done → move the file to `tasks/done/`, set `status: done`, add the closing log line.
  Closing evidence: the «Критерий готовности» is verifiably met, not "seems fine".
- Stale `active/` tasks (no movement, unclear status) → triage back to `inbox/` or close;
  never leave `active/` overflowing the WIP cap.

## Verify and sync

1. Read the changed file back; `git -C "$BRAIN" status --short` shows only the intended change.
2. Commit with a concise message (`task: <what happened>`); push if the brain has a remote.
3. Report to the user in human terms: what was captured and when it's due. No file paths
   or commit hashes unless asked.

## Listing ("what are my tasks?")

Read `tasks/active/` and `tasks/inbox/`, compare `due`-style dates against the real
current date (resolve with a tool), and group the answer: overdue → today → the rest.
Keep it short; summarize clusters instead of listing every file.

## Runtime adapters

- Claude Code: file ops via Read/Write/Edit, git and `date` via Bash.
- Codex / other agents: the same via shell; logic is runtime-independent.
