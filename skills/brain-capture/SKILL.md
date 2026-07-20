---
name: brain-capture
description: Use when the user says "create a task…", "remember…", "save this to the brain/wiki", "add a note…" from ANY working directory (e.g. while coding in another repo). Captures into the brain repository, not the current project, and safely syncs.
---

# Brain Capture — write to the brain from anywhere

Use for capture requests **regardless of the current repo/dir**. Target is always the
brain repository, NOT the current project repo.

## 1. Resolve brain location

- Brain clone: `${BRAIN:-$HOME/Work/brain}` (the same path your `brain-anchor.sh` hook uses).
- Confirm it exists and is a git repo; do all file ops against the resolved path:
  `git -C "$BRAIN" ...`, write files under `$BRAIN/...`.

## 2. Sync first (if the brain has a remote)

```
git -C "$BRAIN" pull --rebase --autostash origin main
```

## 3. Do the capture

- **Task** → follow the `brain-task-management` skill: file under `$BRAIN/tasks/inbox/`
  (or `active/` if the user starts it now) from `tasks/TEMPLATE.md`.
- **Memory** ("remember X") → update the relevant `$BRAIN/memory/*.md`
  (profile / projects / rules). Update the existing file, don't create duplicates.
- **Durable knowledge** → follow the `llm-wiki` skill (raw → `$BRAIN/sources/`,
  synthesized → `$BRAIN/wiki/` + line in `wiki/index.md`).
- **Idea (content, feature, someday/maybe)** → check `$BRAIN/tasks/{inbox,active}/` for an
  existing artifact covering the same stream first; append there rather than creating a
  duplicate. New file only when nothing fits.

## 4. Commit + push (safe, multi-writer)

```
git -C "$BRAIN" add -A
git -C "$BRAIN" commit -m "capture: <short summary>"
git -C "$BRAIN" push origin main    # if rejected: pull --rebase, then push again
```

## Rules

- Never put secrets in the brain.
- Capture goes to the **brain**, not the current project repo.
- Link new notes to related ones with `[[wikilinks]]` — no orphan pages.
- Report what was captured in human terms; omit file paths and commit hashes unless asked.

## Runtime adapters

- Claude Code: file ops via Write/Edit, git via Bash.
- Codex / other agents: the same via shell; logic is runtime-independent.
