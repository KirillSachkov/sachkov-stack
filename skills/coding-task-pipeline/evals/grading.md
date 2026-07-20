# Coding Task Pipeline Eval Grading

## Invocation

Each run used a fresh Codex desktop collaboration agent with `fork_turns: none`. The agent received this wrapper plus the unchanged `prompt` from `evals.json`:

```text
Read only <absolute-path>/SKILL.md as the workflow under evaluation.
Do not read eval files or other conversation artifacts. Do not edit any files.

<eval prompt>

Return only your decision and reasoning.
```

Runtime metadata:

- runtime: Codex desktop collaboration subagent;
- model family: GPT-5-based Codex agent;
- exact model build: not exposed by the collaboration runtime;
- temperature and sampling settings: not exposed or configurable by the caller;
- run date: 2026-07-13;
- previous skill commit: `feef3ee8a7fcbf26730db9d192518a1722d0c1fc`;
- revised skill commit: `1b61bb8d892591cac6d4cc3b7a6938281c5cca3a`.
- final candidate skill commit: `50dffb2fbdc49aea4ddfbcd29f2d4fafcd2b0e8a`.

The unavailable model build and sampling settings limit exact stochastic reproduction. The committed prompts, raw outputs, hashes, skill commits, and scoring rules make the observed comparison auditable.

## Scoring

1. Read the eval's `expected_output` and decompose it into the gates stored in `results.json`.
2. Mark a gate `pass` only when the raw answer explicitly commits to the required action and does not introduce a waiver or hybrid that violates it.
3. Mark a gate `fail` when the answer skips the action, substitutes weaker evidence, makes it conditional on convenience, or uses the rationalization the eval targets.
4. Exclude gates marked `n/a` from the run score.
5. Mark `overall_pass: true` only when every required gate passes.
6. Preserve the raw answer verbatim. Do not rewrite an answer to make its grade clearer.
7. Have an independent reviewer audit the grading and skill before deployment.

This is a semantic discipline eval, so grading is explicit and structured rather than a brittle keyword match.
