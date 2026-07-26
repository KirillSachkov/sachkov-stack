---
name: coding-task-pipeline
description: Use when performing any file-changing development task in a repository, including code, tests, documentation, configuration, schemas, generated artifacts, implementation, fixes, refactors, finishing, or verification.
---

# Coding Task Pipeline

Use this skill as the global quality contract for code-changing tasks. Keep the loop simple: define observable success, inspect the real system, isolate the task, implement from evidence, obtain independent review, verify the result, and leave a clean handoff.

## Hierarchy

- Read the most specific applicable project workflow first. Treat this skill as the invariant base contract.
- Let project adapters override the issue tracker, base branch, branch naming, commands, CI, release route, and Definition of Done.
- Do not let an adapter silently weaken isolation, behavioral testing, independent review, fresh verification, or evidence. A user may explicitly approve a documented deviation, but waived core gates must be reported as incomplete and not pipeline-compliant.
- Keep stack details in repository instructions or focused skills. Do not copy framework-specific rules into this skill.

Skip this pipeline only for discussion, explanation, research without file changes, or a tiny read-only command result. Use the repository incident or release workflow when it applies, while preserving the evidence gates above.

## Progress Contract

For a non-trivial task, track these gates in a plan or todo list. For a fast task, keep the same order in a compact form. Never skip a gate silently.

1. Task contract
2. Rules, stack, and reality check
3. Research decision
4. Task isolation and baseline
5. Verifiable plan
6. TDD implementation or deterministic non-code validation
7. Self-review
8. Independent review and blocker closure
9. Fresh verification and acceptance
10. Commits, integration, cleanup, and report

## 1. Task Contract

- Identify the source of truth: user request, issue, ticket, PR or MR, failing test, log, or repository task.
- Restate the goal as observable behavior. Separate constraints and non-goals from implementation ideas.
- Write acceptance criteria. Give every criterion an executable `verify:` command or action.
- Classify risk:
  - `fast`: documentation, typo, or mechanical configuration;
  - `standard`: normal feature, bug fix, or refactor;
  - `high`: authentication, authorization, money, migration, concurrency, infrastructure, destructive behavior, or sensitive data.
- Surface ambiguity that changes what to build. State a safe conservative assumption when possible; otherwise ask one focused question.

Risk changes verification depth, not the existence of the core gates.

## 2. Rules, Stack, and Reality Check

Before planning or mutation:

- Read repository and scoped instructions: `AGENTS.md`, `CLAUDE.md`, `.claude/rules/`, project skills, service docs, and tracker conventions.
- Inspect Git state: repository root, branch, remotes, remote default, worktrees, dirty files, and user changes.
- Identify the actual stack from manifests and lock files: language, framework and runtime versions, package manager, setup, test, lint, typecheck, build, run, and CI commands.
- Search the current code, tests, docs, history, and open work for similar behavior, reusable mechanisms, ownership boundaries, and overlapping changes.
- Produce a compact task profile: `base`, `stack`, `applicable skills`, `risk`, `reuse map`, and `verification commands`.

Do not overwrite, revert, format, stage, or commit unrelated user work.

## 3. Research Decision

Record one decision before the plan:

- `research: local` when repository code, tests, and docs provide sufficient current evidence;
- `research: external` when behavior is version-sensitive, unfamiliar, security-relevant, dependent on a third-party API, or missing a trustworthy local precedent;
- `research: not-needed` for a mechanical change that does not depend on external facts.

Use local evidence first. For technical external research, use current primary sources and record only findings that change the plan or verification. Do not perform broad best-practice research when the repository already contains a clear, tested pattern.

## 4. Task Isolation and Baseline

Use one task branch in one isolated worktree for every file-changing task.

1. Detect whether the runtime already placed the task in a linked worktree or native isolated workspace. If yes, use it and do not create a nested worktree.
2. Resolve the base in this order: project adapter, repository or tracker rule, remote default such as `origin/HEAD`, then an explicit local base for a repository without a remote.
3. Fetch the current remote base when a remote exists. Never invent `dev`; use it only when the repository declares it as the integration branch.
4. Prefer the runtime's native worktree mechanism. Otherwise create a Git worktree and task branch from the resolved base.
5. Run project setup and a fresh meaningful baseline check inside the task worktree.

A clean shared checkout, tiny diff, deadline, or previous green CI does not waive task isolation or a fresh baseline. If baseline checks fail, capture the exact failure and decide whether attribution is still possible before editing. Do not claim a pre-existing failure was caused or fixed by the task.

### Shared host runtimes

Worktrees isolate files, not Docker, bound ports, named volumes, databases, brokers, emulators, CPU, or memory. Treat heavyweight local runtimes as a separate shared resource.

1. A project that uses a local stack must declare its stack identity, lease lifecycle (acquire, status, handoff, release, and stale-owner recovery), isolation support, and safe commands in `AGENTS.md` or its pipeline adapter. If no lease exists and a stack is already running, treat it as owned by another task until ownership is resolved.
2. Default to one heavyweight stack per project per host. Before any start, build, restart, stop, recreate, migration, database reset, or state-mutating integration/E2E run, inspect the running services and acquire the documented lease.
3. Only the lease owner may mutate the shared stack. Never stop, rebuild, run `down`, prune, delete volumes, reset data, or replace a stack owned by another task.
4. Reuse is valid only after explicit handoff and when commit/configuration provenance and test-state isolation are sufficient for the intended evidence. Unknown provenance or concurrent mutable state forbids reuse.
5. Do not improvise a second stack with another Compose project name or ports. A parallel stack is allowed only when the project explicitly documents complete isolation and a safe resource budget. Otherwise continue lightweight checks, then wait or hand off the heavyweight verification.
6. After the heavyweight check, release the lease or explicitly hand it to the next task. Recover a stale lease only through the documented project rule; age alone does not prove that the owner is gone.

## 5. Verifiable Plan

- For each step, state the expected artifact and the command or action that proves it works.
- Map every acceptance criterion to at least one test, validator, manual check, or CI signal.
- Split large work into vertical slices that can be tested and reviewed independently.
- Choose the smallest design that matches local architecture. Defer adjacent cleanup unless it blocks an acceptance criterion.
- Record migrations, rollback, compatibility, and data risks when applicable.

## 6. Implementation

### Behavioral code

Use RED, GREEN, REFACTOR for new or changed behavior and bug fixes:

1. Write one focused test for the next behavior.
2. Run it and observe the expected failure caused by missing or incorrect behavior.
3. Write the minimum production change that passes the test.
4. Run the focused test and relevant neighboring tests.
5. Refactor only while green, then run the tests again.

Tests written after production code are useful regression coverage, but they are not TDD. Replaying a new test against an old commit does not make the completed implementation test-first. If behavioral code was written before RED, discard that implementation, do not preserve or adapt it as a reference, and implement again from the failing test. An exploratory spike is allowed only when it is thrown away before the TDD cycle starts.

For a behavior-preserving refactor, establish green characterization or existing behavior tests before editing, make the smallest structural change, and prove the same tests stay green afterward. Start a RED-first cycle if the refactor also adds or corrects behavior.

### Non-code and generated changes

For documentation, configuration, schemas, or generated outputs where a unit test adds no useful signal, define deterministic evidence before editing: schema validation, lint, build, generator check, smoke test, or rendered inspection. Configuration that changes runtime behavior still needs observable behavior verification.

### Change discipline

- Match existing naming, architecture, error handling, and test layout.
- Make surgical changes. Trace every changed line to an acceptance criterion, test, or cleanup caused by the task.
- Use established libraries for solved domains. Do not add speculative abstractions or configurability.
- Trigger the systematic debugging workflow after an observed failure. Do not guess through repeated retries.
- Run the narrow check after each slice so failures stay attributable.

Do not impose a universal line-coverage percentage. Require meaningful coverage of changed behavior, relevant boundaries, and failure paths based on risk.

## 7. Self-Review

Review the complete change from the base merge point, including committed, staged, unstaged, and generated artifacts.

Check:

- every acceptance criterion and non-goal;
- correctness, error paths, null or empty cases, duplicates, retries, idempotency, concurrency, and permissions as relevant;
- backward compatibility, migrations, data integrity, rollback, observability, performance, and secrets as relevant;
- scope, unnecessary abstraction, copied logic, test quality, warnings, and unrelated files.

Confirm findings with code search, tests, logs, reproduction, or current documentation. Do not fix unrelated findings; record them in the repository tracker when they matter.

## 8. Independent Review and Blocker Closure

Independent review is mandatory for every file-changing task. The fast profile may use a lightweight diff review, but it may not replace independence with author self-review.

Use a fresh Claude Code or Codex context, configured review agent, or dedicated review command. Static analysis supports review but does not count as an independent reviewer by itself.

Give the reviewer:

- original request and acceptance criteria;
- relevant project rules and risk profile;
- base SHA, head SHA, and complete diff;
- test and verification evidence;
- no author conclusions about what should or should not be flagged.

Classify each finding:

- `CONFIRMED`: direct evidence proves a defect or requirement gap;
- `PLAUSIBLE`: verify the hypothesis before changing code;
- `FALSE_POSITIVE`: evidence disproves the finding.

Fix confirmed in-scope blockers. Track confirmed out-of-scope findings. After a blocker fix, require a fresh independent pass over the updated diff and explicit closure. The author cannot close the author's own blocker, and green tests or static checks do not substitute for that closure.

If no independent reviewer is available, park or report the task as not fully done. Do not silently waive the gate.

## 9. Fresh Verification and Acceptance

Run the narrowest checks first, then broaden by risk and project rules:

- `fast`: relevant validator or smoke check, diff check, and lightweight independent review;
- `standard`: focused and relevant full tests, lint, typecheck, build, integration checks, and independent review;
- `high`: standard checks plus focused security, data, migration, rollback, concurrency, E2E, or operational checks.

For UI work, drive the real rendered interface and inspect screenshots or equivalent visual evidence. For APIs and backend work, verify observable requests, responses, state changes, and failure behavior. Run CI when the project integration route uses it.

After all review fixes:

1. Re-read the original request and acceptance criteria.
2. Execute every `verify:` command or action against the current code.
3. Run the complete applicable verification set fresh.
4. Read full output and record commands, exit status, test counts, screenshots, or links.

If a required check cannot run, state the exact attempt, reason, and residual risk. A user may accept the delivery with that gap, but the report must mark it incomplete and not pipeline-compliant.

An active shared-runtime lease is not a reason to skip required integration or E2E evidence. Record the exact deferred command, target snapshot, and blocking owner or lease; mark the task `verification pending`; and run the check after handoff. Do not claim pipeline-compliant completion until the check passes fresh. The user may explicitly accept delivery with the gap, but it remains incomplete and not pipeline-compliant.

## 10. Commits, Integration, Cleanup, and Report

- Create coherent commits that describe completed intent. Use one commit for a small task or one per independently verified vertical slice. Do not use noisy WIP commits in the final history.
- Stage only scoped files. Inspect commit contents before integration.
- Follow the project route for push, PR or MR, latest-commit CI, issue linkage, and release boundaries.
- Bring a PR- or MR-routed change to merge-ready: latest-commit CI green, review gate closed, no conflicts with the target branch, owner report published. **Do not merge on your own.** The owner reads the report and commands the merge (owner decision 2026-07-19). A repository with a documented direct-commit route and no PR or MR flow (for example a shared notes repo) follows its own rule.
- Update durable docs, tracker state, or wiki only when behavior or reusable process changed.
- Remove only the task's temporary files and processes. Keep the task branch, worktree, and PR or MR intact while the merge decision is pending; remove them after integration or an explicit handoff. Preserve blocked or unmerged work.

### Task-local owner report

Invoke `project-task-report` whenever project-scoped work reaches a completed usable result. This
includes a completed audit, diagnosis, investigation, or decision even when no files changed.

Publish one complete `project-task-report:v1` block in the canonical PR/MR, tracker item, or
tracker-free brain task. Use the shared seven-section schema, name the delivery revision, and
record validator or provider-gate evidence. A later material revision invalidates the report until
it is updated and validated again. Do not create a report catalogue, a sidecar report file, or a
duplicate full copy in the final chat response.

The final chat handoff stays short: state the outcome in one or two sentences, link the canonical
report, and name the integration state or next owner action. Add unique blocking information only
when it is not already visible in the canonical report.

## Red Flags

| Rationalization | Required response |
|---|---|
| "The change is tiny and main is clean" | Use or verify the task worktree anyway. |
| "The last CI run is the baseline" | Run a fresh meaningful baseline on the resolved base. |
| "I can restore the finished code after making the test fail on an old commit" | That proves regression coverage, not TDD. Discard and implement after RED. |
| "The reviewer is unavailable, so I will note the risk" | The task is not fully done. Park or wait for independent review. |
| "All tests pass, so the requirements are complete" | Re-run acceptance checks and independent review. |
| "All repositories should start from dev" | Resolve the base from repository rules. |
| "Best practices require a broad web search" | Research only the current facts that affect this task. |
| "The agent or reviewer reported success" | Verify the diff, findings, and commands independently. |
| "CI is green and review is closed, so merging is safe" | Stop at merge-ready. Publish the owner report and wait for the owner's merge command. |
| "A separate worktree means I can start another Docker stack" | Worktrees do not isolate host runtimes. Use the project lease and one-stack default. |
| "I will change the Compose project name and ports" | Use a parallel stack only when the project declares full isolation and a safe resource budget. |

## Definition of Done

The task is done only when all applicable statements are true:

- Requested behavior and acceptance criteria are satisfied with current evidence.
- Work occurred in the task's isolated branch and worktree.
- Behavioral changes have genuine RED, GREEN, REFACTOR evidence, or the chosen non-code validator is documented.
- Self-review and independent review are complete; confirmed blockers have independent closure.
- Fresh applicable tests, lint, typecheck, build, UI, integration, E2E, and CI checks pass.
- Commits and integration follow project rules without unrelated user changes.
- A PR- or MR-routed change is merge-ready with the owner report published, and any merge happened only on an explicit owner command.
- Durable state and cleanup are complete.
- The final chat response links and briefly summarizes the canonical task-local report instead of
  repeating its sections.
