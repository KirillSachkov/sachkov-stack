# GitLab adapter

GitLab supports repository merge request templates under
`.gitlab/merge_request_templates/`. Put the v1 block first in `Default.md`; keep the complete block
within the first 2700 characters for a compact, reviewable contract. The marker itself must begin
within the first 400 characters.

Do not validate `CI_MERGE_REQUEST_DESCRIPTION`: it is a pipeline-creation snapshot and GitLab can
truncate it at 2700 characters. Fetch the full current MR through the API with `CI_JOB_TOKEN`, use
the returned `description`, and compare `Revision` with the returned current `sha`.

Vendor the canonical validator as `.claude/scripts/task-report.py`, then add an MR pipeline job:

```yaml
project-task-report:
  stage: test
  image: python:3.13-alpine
  before_script:
    - apk add --no-cache curl > /dev/null
  rules:
    - if: '$CI_PIPELINE_SOURCE == "merge_request_event"'
  script:
    - |
      curl --fail --silent --show-error --header "JOB-TOKEN: $CI_JOB_TOKEN" \
        "$CI_API_V4_URL/projects/$CI_PROJECT_ID/merge_requests/$CI_MERGE_REQUEST_IID" \
        --output /tmp/task-report-mr.json
    - |
      python3 -c 'import json,sys; from pathlib import Path; data=json.loads(Path(sys.argv[1]).read_text()); Path(sys.argv[2]).write_text(data.get("description") or "", encoding="utf-8")' \
        /tmp/task-report-mr.json /tmp/task-report-description.md
    - |
      REPORT_REVISION="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1], encoding="utf-8"))["sha"])' /tmp/task-report-mr.json)"
      python3 .claude/scripts/task-report.py validate /tmp/task-report-description.md \
        --expected-revision "$REPORT_REVISION" --max-prefix-chars 400 --max-end-chars 2700
```

Enable GitLab project settings `only_allow_merge_if_pipeline_succeeds=true` and
`allow_merge_on_skipped_pipeline=false`; without the former, a failing report job is advisory.
The CI job is defense in depth, not the trust boundary: source branches can change their CI file and
vendored validator. Add a project webhook whose receiver and validator run outside the repository
branch. Subscribe it to merge request, issue, and pipeline events and authenticate it with
`X-Gitlab-Token`.
The trusted receiver must:

1. On MR open/reopen, description edit, and source-commit update, fetch the full current MR, validate
   its description against current `sha`, and use the Commits API to set an external
   `project-task-report:trusted` status on that SHA, exact current native MR `pipeline_id`, and the
   exact ref returned by the selected native MR `head_pipeline` (pending, then success or failed).
   Do not derive or hardcode the status ref: self-hosted GitLab versions can reject a source-branch
   ref for an MR pipeline. Accept the write only when GitLab's response binds the status to that same
   pipeline id and ref; treat a mismatch as failure. Serialize evaluation per
   project/MR and re-fetch the SHA, description, and pipeline before publishing the final status; if
   any changed, discard that result and evaluate the new snapshot. The source branch cannot remove
   this status.
2. On every Pipeline Hook for a native MR pipeline, attach a fresh trusted status to that exact
   pipeline. After an MR edit or update, wait a bounded interval for the current native pipeline; if
   none exists, create one through the MR pipelines API. Never report success on a separate fallback
   external pipeline, because that can leave the latest native pipeline without the required status.
3. On issue close or description update while closed, fetch the current issue description. Allow closure when it contains a valid
   report or when a related merged MR has a valid report bound to its SHA; otherwise reopen the
   issue and add a short diagnostic note. When an already-merged MR report is edited, revalidate any
   issues whose closure depends on it and reopen them if the evidence is no longer valid. This is the
   closure gate for no-MR audits/diagnoses and prevents later removal of completion evidence.
4. Reconcile open MRs and recently updated closed issues periodically so a missed or unsupported
   webhook delivery cannot leave a stale green status or an invalid closed task. Persist a bounded
   issue watermark plus failed-item retry set across restarts, isolate failures per object and per
   pass, and use the same serialized snapshot protocol for MRs.
5. Store the project token and webhook secret only in a root-owned runtime environment file. Use a
   least-privilege project access token, validate the project id, cap request size, and return 5xx
   on transient API failure so GitLab retries.

Because editing an MR description does not itself create a new MR pipeline, a manual instruction to
create one is not a hard gate. The webhook or bounded reconciliation must change the status
automatically, and Pipeline Hook processing must cover every replacement pipeline.

Before declaring merge-ready, prove both negative cases once in a safe branch: a missing report
fails, and a report whose `Revision` names the previous commit fails. Then restore the current
report and require both the CI job and trusted external status to pass. If release/hotfix MRs
intentionally skip the full suite, create a report-only MR pipeline rather than skipping the
pipeline entirely.

Primary references:

- GitLab description templates: <https://docs.gitlab.com/user/project/description_templates/>
- GitLab predefined variables: <https://docs.gitlab.com/ci/variables/predefined_variables/>
- GitLab CI job token API access: <https://docs.gitlab.com/ci/jobs/ci_job_token/>
- GitLab merge request pipelines: <https://docs.gitlab.com/ci/pipelines/merge_request_pipelines/>
- GitLab Projects API: <https://docs.gitlab.com/api/projects/>
- GitLab webhook events: <https://docs.gitlab.com/user/project/integrations/webhook_events/>
- GitLab external commit statuses: <https://docs.gitlab.com/ci/ci_cd_for_external_repos/external_commit_statuses/>
- GitLab Commits API: <https://docs.gitlab.com/api/commits/>
