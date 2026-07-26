# GitHub adapter

Put the v1 block first in `.github/pull_request_template.md`. Vendor the canonical validator as
`.github/scripts/task-report.py` on the protected default branch, fetch the full current PR body,
and validate it against the current head SHA. Use `pull_request_target` only for metadata validation:
never checkout or execute code from the untrusted PR branch.

```yaml
name: Project task report
on:
  pull_request_target:
    types: [opened, edited, synchronize, reopened]

concurrency:
  group: project-task-report-${{ github.event.pull_request.number }}
  cancel-in-progress: true

permissions:
  contents: read
  pull-requests: read
  statuses: write

jobs:
  project-task-report:
    runs-on: ubuntu-latest
    steps:
      - name: Publish pending status on PR head
        env:
          GH_TOKEN: ${{ github.token }}
          HEAD_SHA: ${{ github.event.pull_request.head.sha }}
        run: |
          gh api --method POST "repos/$GITHUB_REPOSITORY/statuses/$HEAD_SHA" \
            -f state=pending \
            -f context='project-task-report:trusted' \
            -f description='Validating the current PR report' \
            -f target_url="$GITHUB_SERVER_URL/$GITHUB_REPOSITORY/actions/runs/$GITHUB_RUN_ID"
      - uses: actions/checkout@v4
        with:
          ref: ${{ github.event.repository.default_branch }}
      - name: Fetch current PR snapshot
        id: snapshot
        env:
          GH_TOKEN: ${{ github.token }}
          PR_NUMBER: ${{ github.event.pull_request.number }}
          REPORT_PATH: ${{ runner.temp }}/pr-body.md
          SNAPSHOT_PATH: ${{ runner.temp }}/pr-snapshot.json
        run: |
          gh api "repos/$GITHUB_REPOSITORY/pulls/$PR_NUMBER" > "$SNAPSHOT_PATH"
          python3 - "$SNAPSHOT_PATH" "$REPORT_PATH" "$GITHUB_OUTPUT" <<'PY'
          import hashlib
          import json
          import sys
          from pathlib import Path

          snapshot = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
          body = snapshot.get("body") or ""
          Path(sys.argv[2]).write_text(body, encoding="utf-8")
          with Path(sys.argv[3]).open("a", encoding="utf-8") as output:
              output.write(f"body_hash={hashlib.sha256(body.encode()).hexdigest()}\n")
              output.write(f"head_sha={snapshot['head']['sha']}\n")
          PY
      - name: Validate task-local report
        id: validate
        continue-on-error: true
        run: python3 .github/scripts/task-report.py validate "$RUNNER_TEMP/pr-body.md" --expected-revision "${{ steps.snapshot.outputs.head_sha }}" --max-prefix-chars 400
      - name: Publish final status on PR head
        if: ${{ always() && !cancelled() }}
        env:
          GH_TOKEN: ${{ github.token }}
          PR_NUMBER: ${{ github.event.pull_request.number }}
          HEAD_SHA: ${{ steps.snapshot.outputs.head_sha || github.event.pull_request.head.sha }}
          SNAPSHOT_BODY_HASH: ${{ steps.snapshot.outputs.body_hash }}
          VALIDATION_OUTCOME: ${{ steps.validate.outcome }}
        run: |
          gh api "repos/$GITHUB_REPOSITORY/pulls/$PR_NUMBER" > "$RUNNER_TEMP/pr-current.json"
          if ! python3 - "$RUNNER_TEMP/pr-current.json" "$HEAD_SHA" "$SNAPSHOT_BODY_HASH" <<'PY'
          import hashlib
          import json
          import sys
          from pathlib import Path

          current = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
          body_hash = hashlib.sha256((current.get("body") or "").encode()).hexdigest()
          raise SystemExit(current["head"]["sha"] != sys.argv[2] or body_hash != sys.argv[3])
          PY
          then
            state=pending
            description='PR changed; the newest run must validate it'
          elif [ "$VALIDATION_OUTCOME" = success ]; then
            state=success
            description='Current PR report is valid'
          else
            state=failure
            description='Current PR report is missing, stale, or invalid'
          fi
          gh api --method POST "repos/$GITHUB_REPOSITORY/statuses/$HEAD_SHA" \
            -f state="$state" \
            -f context='project-task-report:trusted' \
            -f description="$description" \
            -f target_url="$GITHUB_SERVER_URL/$GITHUB_REPOSITORY/actions/runs/$GITHUB_RUN_ID"
          [ "$state" = success ]
```

Require the exact `project-task-report:trusted` commit-status context in branch protection. Do not
require only the workflow job: a `pull_request_target` workflow run belongs to trusted default-branch
execution, while the explicit status above is attached to the current PR head SHA. Prove once that a
missing report and a stale revision fail, then restore a current report and require the latest head
status to pass. The workflow must never checkout or execute the PR branch.
The per-PR concurrency group suppresses obsolete runs, while the immediate pre-publication fetch is
the snapshot compare-and-set: a changed body or head may publish only `pending`, never a stale final
success. Do not rely on concurrency alone because cancellation and final-step timing can race.

For tracker-only work, add a second trusted workflow on the default branch for
`issues: [closed, edited]`. On `edited`, return immediately unless the issue is still closed. Fetch
the full current issue body and validate it; when no report exists, check whether a linked merged PR
has a valid report bound to its head SHA. If neither surface is valid, reopen the issue through the
API and add a short diagnostic comment. Revalidate a linked merged PR when its report is edited; if
that report was the evidence for closing issues and becomes invalid, reopen those issues. Grant the
workflow only `issues: write`, `pull-requests: read`, and `contents: read`; it must not execute issue
or PR content. This makes both closure and later evidence removal self-reverting rather than relying
on an agent instruction.

Primary reference: GitHub pull request templates,
<https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/about-issue-and-pull-request-templates>.
