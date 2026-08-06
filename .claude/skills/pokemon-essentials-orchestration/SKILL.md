---
name: pokemon-essentials-orchestration
description: Use when a task's scope isn't obviously owned by one skill — a broad audit, a cross-cutting rename, "review the whole X system," anything spanning multiple Scripts/ subsystems, PBS data, and the compile pipeline together, or when deciding whether to delegate part of a task to a subagent. Also use when unsure which repo-local skill applies before starting work.
---

# Pokemon Essentials Orchestration

## Overview
This repo is a single Ruby engine codebase (no separate services/packages), but it has real internal boundaries: ~20 numbered `Scripts/` subsystems loaded in a fixed order, a text-based PBS data layer, a compiler bridging the two, and no automated verification (everything is manual, in-`Game.exe`). This skill routes a task to the right repo-local skill(s) and says when/how to split work across subagents. It doesn't restate any owned skill's content — just where to send the work.

## Skill Map

| Skill | Owns | Activates on |
|---|---|---|
| `source-code-audit-and-refactoring` | `Scripts/**/*.rb` architecture, runtime behavior, refactors | Reading/editing/auditing/refactoring script code |
| `build-system-audit-and-refactoring` | PBS→Data compiler mechanism, plugin load pipeline, versioning, vendored runtime binaries, absence of CI | Compile-pipeline failures, packaging/versioning questions, plugin load issues |
| `pbs-data-validation` | `PBS/*.txt` format rules, per-field compiler validation | Editing any `PBS/*.txt` file, a `FileLineData`/section-header compile error |
| `verifying-essentials-changes` | The manual in-`Game.exe` verification workflow | Before claiming any change works/is fixed/is complete |
| `claude-repository-adaptation` | Keeping this `.claude/` configuration itself accurate as the repo changes | After a rename/restructure, or after a task hit repeated friction |

Cross-cutting rule of thumb: editing `Scripts/021_Compiler/*` touches both `source-code-audit-and-refactoring` (it's Ruby code) and `build-system-audit-and-refactoring` (it's the pipeline mechanism) — read both rather than picking one.

## Major Subsystem Map
Full folder table lives in CLAUDE.md — don't duplicate it here. In short: `001_Technical`→`009_Scenes` are engine plumbing; `010_Data` is the typed PBS-backed data layer; `011_Battle` is the battle engine; `014_Pokemon` is live Pokemon instances (distinct from `010_Data`'s species templates); `016_UI` is menu/screen implementations; `018_AlternateBattleModes` is Safari Zone/Bug Contest/Battle Frontier; `020_Debug` is in-game F9 tooling; `021_Compiler` is the PBS/map compiler.

## Common Task → Skill Combinations
- "Add a new move/ability/item" → `pbs-data-validation` (add the PBS entry) + `source-code-audit-and-refactoring` (implement the effect handler if new) + `verifying-essentials-changes` (confirm in a real battle).
- "Refactor the battle AI" → `source-code-audit-and-refactoring` (own the change, use the shared refactoring model's intensity levels) + `verifying-essentials-changes`.
- "Why won't the game boot" → `build-system-audit-and-refactoring` first (pipeline-level: plugin/compile/vendored-binary) — only drop to `pbs-data-validation` once a `FileLineData` line number narrows it to one file.
- "Audit code quality / find dead code / review architecture in area X" → `source-code-audit-and-refactoring`, audit-only mode per the shared refactoring model.
- "Set up tests" / "add CI" → neither exists yet; see `claude-repository-adaptation`'s deferred test-infrastructure plan and `build-system-audit-and-refactoring`'s CI section before proposing either as if it already exists in some form.

## High-Risk Areas
- Changing a `GameData::*` public accessor signature or a PBS schema field — de facto public API for forks/plugins that can't be grepped locally (`Plugins/` is gitignored). Treat as Level 3 per the shared refactoring model even if the local blast radius looks small.
- Anything touching `Data/Scripts.rxdata` directly, or the vendored runtime binaries at repo root (`Game.exe`, DLLs, `mkxp.json`, `soundfont.sf2`) — see `source-code-audit-and-refactoring` and `build-system-audit-and-refactoring` respectively for why these are traps, not normal files.
- Renaming/moving a `Scripts/` folder — this repo is mid-restructure (see CLAUDE.md's folder-naming note) and a rename can silently break a hookify rule's path pattern or a skill's path claim; see `claude-repository-adaptation`.

## Delegation Patterns
This is a one-repo, one-branch-at-a-time codebase with no test suite to run in parallel — most tasks are cheaper done directly than delegated. Delegate when:
- **A grep/verification sweep spans many folders** — e.g. "find every caller of this method across Scripts/" or "confirm this skill's path claims still hold" — dispatch an Explore or general-purpose subagent with the specific grep target and expected output (file:line list), not an open-ended "look around" prompt.
- **A Level 3/4 refactor (shared refactoring model) touches several independent numbered folders** — bounded per-folder inspection assignments (read this folder, report what calls into the changed surface) can run in parallel; reconcile results yourself before deciding the actual change.
- **Independent validation of a finding matters** — e.g. confirming a proposed dead-code removal really has zero call sites before deleting it.

Don't delegate: single-file edits, anything needing `Game.exe` interaction (subagents can't launch/observe the running game — verification stays with the primary agent per `verifying-essentials-changes`), or small lookups cheaper to Grep directly.

## Escalation
If a task's friction doesn't match what any skill anticipated (repeated fix-loops, a wrong path claim, an error a hook/skill's message didn't predict), that's not a one-off — escalate to `claude-repository-adaptation` rather than solving it silently and moving on.
