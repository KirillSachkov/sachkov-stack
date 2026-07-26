---
name: project-task-report
description: Use when finishing project-scoped work that changed project state or produced a completed audit, diagnosis, investigation, or decision, including tasks with or without a tracker.
related_skills: [coding-task-pipeline, project-harness-bootstrap]
---

# Project Task Report

Publish one owner-facing completion report inside the task's canonical surface. The report is a
completion artifact, not a session transcript, activity log, or global catalogue entry.

## Decide whether the report is required

Require it when work belongs to a named project and the task is being completed after any of these:

- code, tests, configuration, data, documentation, infrastructure, or tracker state changed;
- an audit, diagnosis, investigation, or design decision produced a usable result, even with no
  file changes.

Do not require it for ordinary questions, casual discussion, unscoped research, or work still in
progress. A blocked project task needs an explicit task-local handoff, but must not be marked done.

## Choose exactly one canonical destination

Use the first available destination:

1. Code work with a PR or MR: put the complete block at the top of its description.
2. Tracker task without a PR or MR: put the complete block in that issue or work item.
3. Project without a tracker: put the complete block in its brain task before moving it to
   `tasks/done/`.

If a brain intake task is promoted into an external tracker, set a concrete frontmatter marker such
as `promoted_to: gitlab#898`, close the brain copy, and publish the eventual completion report only
in the tracker or PR/MR. The marker must be `<provider>#<positive-id>` or a full issue/MR/PR URL
ending in its numeric id; a provider homepage or arbitrary URL is invalid. A promoted brain task
must not contain a second report block.

Never create a separate report file, shared report directory, database row, or second full copy.
The final chat response may link to the canonical report and summarize the outcome in one or two
sentences; it does not replace or duplicate the report.

## Author and validate

1. Start from [references/report-template.md](references/report-template.md). Keep the versioned
   markers and all seven headings unchanged.
2. Write for an owner deciding whether the result is acceptable. Describe application areas and
   behavior, not merely file paths or commands.
3. Set `Revision` to the delivery revision:
   - PR/MR code work: the final source-branch HEAD;
   - tracker-free brain task: the repository HEAD immediately before the separate task-closure
     commit (obtain it with `git rev-parse HEAD`);
   - result without a code revision: a concrete task version or dated result identifier.
   Never leave a placeholder. The pre-closure HEAD rule avoids a circular commit hash while still
   binding the report to the implementation it describes. The closure commit must stage only task
   records; commit implementation and documentation first.
4. State `Нет.` when a required section has no risks, unverified work, or business-logic change.
   Do not leave a section empty or comment-only.
5. Validate the exact canonical content with the project's validator. The merge/closure gate must
   execute a trusted copy outside the source branch being checked; a vendored copy is useful for
   local feedback but is not the trust boundary. For a Markdown file:

   ```bash
   python3 scripts/task-report.py validate path/to/task.md
   ```

   For PR/MR content, the provider adapter must pass the body on stdin and compare `Revision` with
   the final head SHA. Follow [references/gitlab.md](references/gitlab.md) or
   [references/github.md](references/github.md).
   The report must be visible Markdown, not an HTML comment or code fence. Provider adapters must
   fetch the full current canonical surface, enforce an end-position limit where applicable, and
   automatically revalidate edits. Tracker-only closure must fail or self-revert when no valid
   report exists.
6. If any commit or material result changes after publication, update the report and validate
   again. Green CI for an earlier report is stale evidence.

Do not mark the tracker item done, move a brain task to `tasks/done/`, or call a PR/MR merge-ready
until the report gate passes. If the provider cannot verify the canonical content, leave the task
incomplete and name the missing evidence.

## Required meaning

- `Итог`: what is now true for the owner or user.
- `Затронутые части проекта`: affected product or operational areas.
- `Бизнес-логика`: changed behavior and rules, or an explicit statement that none changed.
- `Что изменено`: the important implementation or decision, without a file dump.
- `Проверка`: automated, manual, review, and CI evidence.
- `Не проверено и риски`: known gaps, residual risk, and what deserves attention.
- `Интеграция`: revision, branch, tracker/PR/MR state, and the owner's next action.
