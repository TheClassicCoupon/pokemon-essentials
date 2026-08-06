# Shared Refactoring Model

Not a skill (no `SKILL.md`, not independently discoverable) — a reference the `source-code-audit-and-refactoring` and `build-system-audit-and-refactoring` skills both point at, so the audit/refactor model is defined once. Cross-reference it by name ("see the shared refactoring model") rather than duplicating it.

## Operating Modes

**Audit-Only** — user asks for findings, recommendations, or a plan ("what's wrong with X", "review Y", "how would you refactor Z"): establish baseline, inspect the requested scope, prioritize findings, recommend changes and how to verify them (see `verifying-essentials-changes`), do not modify files without explicit authorization.

**Audit-and-Refactor** — user asks for improvement, correction, cleanup, or restructuring ("clean up X", "fix Y", "refactor Z"): establish baseline, pick the proportionate intensity level below, implement the justified changes, verify in `Game.exe` (there's no test suite to run instead), document behavioral changes. An instruction to audit-and-refactor authorizes implementation within the requested scope — don't stop at a plan when the user already asked for the change.

## Refactor Intensity

| Level | Scope | Requires |
|---|---|---|
| 1 — Targeted Cleanup | Safe rename, local simplification, verified dead code removal, small script fix, single-file duplication removal | Just do it, verify the touched flow |
| 2 — Component Refactor | A full class, one `Scripts/0NN_*` numbered folder, one PBS data type end-to-end, one script/tool | Concise plan, compatibility check (does anything outside the component call into it?), verify the component's flows in-engine |
| 3 — Cross-Component Refactor | Crosses numbered-folder boundaries, changes a `GameData::*` public accessor, changes a PBS schema field, touches both compiler and runtime sides of the data pipeline | Staged plan, dependency analysis (grep every caller/`GameData::X.get` site before changing a signature), verify every affected flow in-engine, not just the one you were thinking about |
| 4 — Repository-Wide Refactor | Load-order restructuring, renaming/moving numbered folders, changing the two-era code-style convention, anything that would break a fork's merge from upstream Essentials | Full baseline, prioritized findings, explicit design decision recorded (not just executed), staged implementation, incremental in-engine verification per stage, full final verification, rollback note |

Level 3 and 4 are not routine cleanup — don't reach for them because a smaller fix "would be nicer if generalized." This repo has no test suite, so higher levels lean harder on manual in-engine verification at each stage rather than a final check alone — a Level 4 change that only gets verified once at the end has no way to isolate which stage broke something.

## Common Principles

- Solve a demonstrated problem — don't refactor speculatively "while you're in there."
- Preserve intended behavior unless a change is justified and stated.
- When behavior is unclear (undocumented legacy `pb`-prefixed helper, an AI effect handler with no comments), read call sites and exercise the flow in `Game.exe` to characterize actual behavior before changing it — there's no test suite to lock behavior down, so this manual characterization step is the only safety net.
- Separate mechanical changes (renames, moves) from behavioral changes (logic changes) — don't mix them in one pass; a rename-only pass is easy to verify by grep, a behavior change needs in-engine exercise.
- Match the existing convention in the file/area being touched (see CLAUDE.md's Code style section) rather than imposing a preferred style.
- Avoid speculative extensibility — this codebase already carries two eras of convention; don't add a third "for future flexibility."
- Preserve unrelated user changes — check `git status`/`git diff` before starting, don't fold unrelated cleanup into the same change.
- Update CLAUDE.md/skills if the refactor changes a path, method, or convention they document (see `claude-repository-adaptation`).
- Report what could not be verified (e.g. "did not test double battles" or "did not test the mkxp-z Linux/macOS build") rather than implying full coverage.

## Delegation

For Level 3/4 work, or any audit spanning more than ~3 numbered folders, route through the `pokemon-essentials-orchestration` skill to divide the work into bounded subagent assignments (one folder/subsystem per agent, verify-path-and-command tasks, etc.) rather than reading everything into the primary context directly.
