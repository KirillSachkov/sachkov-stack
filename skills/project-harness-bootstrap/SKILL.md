---
name: project-harness-bootstrap
description: "Use when starting work in a project repository that has no agent harness or an incomplete one (no root AGENTS.md canon, project skills, pipeline adapter, gates, or test scaffold), or when the owner asks to set a project up for agent-driven development. Detect what exists, interview the owner, build the harness, verify it, record it in the brain."
related_skills: [coding-task-pipeline]
---

# Project Harness Bootstrap

Owner rule (2026-07-19): every project gets a full agent harness of its own on top of the shared
global harness. When an agent starts work in a repository without one, the harness is built first,
with the owner's input, and only then does the task go through it. Do not quietly work harness-free.

The global contract stays canonical: a project adapter overrides routes (tracker, base branch,
commands, CI) but never weakens the core gates of `coding-task-pipeline` (isolation, TDD,
independent review, fresh verification, owner report, owner-commanded merge).

## Step 0. Detect what exists

Check, do not assume. A complete harness has:

- root `AGENTS.md` canon (~150-200 lines: project snapshot, exact commands, boundaries, Definition
  of Done, merge policy, tracker conventions) plus thin runtime bridges (`CLAUDE.md` with
  `@AGENTS.md`);
- one real project skills directory (`.claude/skills/`) with a `task-pipeline` adapter over the
  global `coding-task-pipeline`; other runtimes see it through a symlink
  (`.agents/skills -> ../.claude/skills`), never a second editable copy;
- gates as hooks: a stop-gate (dirty-tree incremental check + `.task-contract.json` verify) wired
  per runtime, `.task-contract.json` in `.gitignore`;
- a runnable test scaffold and verification commands that actually work;
- CI quality gates when the project has CI;
- a declared tracker (project tracker or brain `tasks/`).

All present: proceed with normal work. Partial: name the missing parts and propose completing them
as a separate small task before or alongside the current one. Never silently rebuild what exists.

## Step 1. Interview the owner

Ask once, as one compact list, only what the repository cannot answer. Confirm inferred facts
instead of asking open questions. Cover:

- what the project is and its stage (active development, maintenance, experiment);
- stack and versions (pre-fill from manifests and lock files);
- exact commands: setup, run, test, lint, build;
- integration branch and merge policy (default: agent stops at merge-ready, owner commands the merge);
- tracker: project tracker, brain tasks, or none yet;
- boundaries: always allowed, ask first, never touch;
- deploy or release route and production access, if relevant;
- Definition of Done for a typical task.

## Step 2. Build the harness

Reference implementation: your most recently bootstrapped project. Copy its
shape, adapt the stack specifics; do not invent a new structure per project.

1. `AGENTS.md` canon from the interview + repository facts. Thin `CLAUDE.md` bridge. Raise runtime
   doc-size limits when the canon is large (Codex `project_doc_max_bytes`).
2. `.claude/skills/task-pipeline/` adapter: head (project context, tracker, base branch, commands)
   + tail (Definition of Done, report and merge policy) around the global contract; route by task
   type (feature, fix, trivial) only when the project needs it.
3. `.agents/skills` symlink to `.claude/skills`, asserted in CI when CI exists.
4. Stop-gate hook adapted to the stack: incremental check command for a dirty tree, contract verify
   on a clean tree. Wire for each runtime (`.claude/settings.json`; `.codex/hooks.json`, timeout in
   seconds). Add `.task-contract.json` to `.gitignore`.
5. Test scaffold by stack if missing; wire its run command into the gate and `AGENTS.md`.
6. CI gates: tests, lint, skills frontmatter validation, symlink assertion.
7. Per-stack guidance skills when they exist; otherwise record stack rules inside the project, not
   in the global skills.

## Step 3. Verify before first use

- Run every command written into `AGENTS.md` once; fix or mark the broken ones.
- Trip the stop-gate deliberately (dirty tree, failing contract command) and watch it block.
- Run one trivial task end to end through the adapter, including the owner report.

## Step 4. Record in the brain

- Add or update the project line in `memory/projects.md` and the `wiki/<project>.md` page with
  `[[wikilinks]]`; note where the project deviates from the global contract and why.
- The harness itself lives in the project repository; the brain records that it exists.

## Runtime adapters

- **Claude Code:** hooks in `.claude/settings.json` (timeout in milliseconds); skills discovered
  from `.claude/skills/`.
- **Codex:** reads `AGENTS.md` natively; hooks in `.codex/hooks.json` (timeout in seconds); skills
  through the `.agents/skills` symlink.
