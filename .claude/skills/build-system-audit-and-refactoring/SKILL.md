---
name: build-system-audit-and-refactoring
description: Use for anything about how this repo turns inputs into a runnable/distributable game — the PBS-to-Data compiler (Scripts/021_Compiler), the plugin manager's load/compile step, versioning, packaging or distributing a fork, the vendored mkxp-z runtime binaries, or the absence of CI/CD. Also use when diagnosing a boot/compile failure that isn't a single PBS field error (that's pbs-data-validation) but a pipeline-level problem — wrong load order, plugin conflict, stale Data/*.dat, missing vendored runtime file.
---

# Build-System Audit and Refactoring

## Overview
This repo has no npm/cargo/make-style build system and no CI/CD (no `.github/workflows` directory exists). "Building" is entirely in-engine: `Game.exe` (the mkxp-z runtime) reads `Game.ini`/`mkxp.json`, loads `Scripts/999_Main/999_Main.rb`, and — in `$DEBUG` mode — compiles `PBS/*.txt` and plugin scripts into `Data/*.dat`/`Data/PluginScripts.rxdata` at startup. That compile step, the plugin load pipeline, and packaging a distributable fork are this skill's scope. It does not own per-field PBS validation rules (`pbs-data-validation` owns that detail) or runtime `Scripts/` code (`source-code-audit-and-refactoring`) — this skill owns the pipeline mechanism and its failure modes, those own the content.

For audit-vs-refactor mode and refactor intensity levels, see the shared refactoring model (`.claude/skills/_shared/refactoring-model.md`).

## The Vendored Runtime — Unusual and Easy to Miss
Unlike a typical "engine repo," this repo tracks the mkxp-z runtime binaries themselves in git, not just the game logic: `Game.exe`, `x64-msvcrt-ruby310.dll`, `zlib1.dll`, `soundfont.sf2`, and `mkxp.json` are all tracked (confirmed via `git ls-files`). `Game.ini` and `Game.rxproj` are *not* tracked (gitignored / local RPG Maker XP project files) — don't confuse the two groups. A refactor or cleanup pass that treats everything at repo root as "probably generated" risks deleting or gitignoring a tracked, load-bearing binary. If a build-system change needs a newer mkxp-z build, that's a deliberate binary replacement + commit, not something to automate or script.

## The Compile Pipeline
`Scripts/021_Compiler/001_Compiler.rb` defines the typed field coercers (`csvInt!`, `csvPosInt!`, `csvFloat!`, `csvBoolean!`, `csvEnumField!`, etc.). `002_Compiler_CompilePBS.rb` drives PBS-text → `Data/*.dat`; `003_Compiler_WritePBS.rb` is the inverse, used by in-game data editors (F9) to write PBS back out. `004_Compiler_MapsAndEvents.rb` compiles map/event data separately from PBS text data.

- Trigger: any `PBS/*.txt` file newer than its compiled `Data/*.dat` counterpart, checked at boot in `$DEBUG` mode only.
- Force a full recompile: hold Ctrl at boot, or F9 (map, not battle) → "Files options..." → "Compile data" → "Fully compile all data".
- A compile failure blocks boot entirely (no partial-load fallback) and reports file + line via `FileLineData.linereport`.
- Release/non-`$DEBUG` builds skip the auto-recompile check entirely — a compiled `.dat` mismatch with PBS source would ship silently in a release build. There's no observed packaging script in this repo (`Tools/` has no packager, no `.rgssad`/`.rgss3a` artifacts tracked or found) — treat "how a release build is actually produced/distributed" as unverified/undocumented rather than assuming a workflow that doesn't exist. If asked to build a release, say this is unautomated in the current repo rather than guessing at a packaging command.

## Plugin Load Pipeline
`Scripts/001_Technical/005_PluginManager.rb` scans `Plugins/` (gitignored — not present or inspectable unless the user has plugins installed locally) for per-plugin `meta.txt` files, resolves load order from declared dependencies/conflicts, compiles the resulting scripts into `Data/PluginScripts.rxdata`, and evals them at boot after core `Scripts/` load. The large comment block at the top of that file documents the `meta.txt` format and `PluginManager.register` options — read it directly rather than inferring the format, since `meta.txt` isn't itself tracked (lives inside the gitignored `Plugins/` tree).

## Versioning
`README.md` states this repo is "Based on Essentials v21.1" — that's the only version marker found; there's no `VERSION` file, gemspec, or package manifest. Forks pull upstream changes via git merge/pull (README's fork workflow: fork this repo, drop a copy of Essentials v21.1 assets into the clone, then merge upstream commits). A build-system audit that assumes semver tagging or a changelog file should first confirm one doesn't exist rather than inventing one.

## CI/CD
None exists (`.github/` is absent). If asked to add CI, that's new infrastructure, not a fix to something broken — treat it as a Level 3/4 change per the shared refactoring model (crosses into workflow territory the repo has never had) and confirm the user actually wants CI added versus just wanting local rubocop/verification tightened, since a headless mkxp-z run in CI (no display, no `Game.exe` interaction) can't exercise the manual verification flow that `verifying-essentials-changes` relies on — at most it could run `rubocop` and confirm PBS compiles without a display-dependent boot, which is a narrower guarantee than the in-engine verification this repo currently relies on.

## Diagnosing Pipeline-Level Failures

| Symptom | Likely cause |
|---|---|
| Boots but data change isn't reflected | `Data/*.dat` mtime not stale relative to PBS — force recompile (hold Ctrl / F9 menu) |
| Compile error naming a PBS file + line | Per-field PBS problem — see `pbs-data-validation`, not this skill |
| Plugin fails to load / load-order-dependent crash | Check the plugin's `meta.txt` dependencies/conflicts against `PluginManager`'s resolution in `005_PluginManager.rb` |
| Boots in debug but the built/release path behaves differently | No auto-recompile outside `$DEBUG` — verify `Data/*.dat` was actually regenerated before treating this as a code bug |
| Missing DLL / runtime crash on launch | One of the tracked vendored binaries (`Game.exe`, `*.dll`, `soundfont.sf2`, `mkxp.json`) may be missing/mismatched in the checkout — confirm against `git ls-files`, not assumed to be generated |

## Common Mistakes
- Assuming a packaging/release script exists somewhere in `Tools/` — it doesn't; `Tools/` holds only the RPG Maker XP round-trip scripts and two standalone GUI utilities (`animmaker.exe`, `extendtext.exe`), unrelated to packaging.
- Treating the vendored runtime binaries at repo root as generated/ignorable — they're tracked; don't add them to `.gitignore` or delete them during a "clean up loose root files" pass without checking `git ls-files` first.
- Conflating a compile-pipeline failure (this skill) with a single bad PBS field (`pbs-data-validation`) — the former blocks boot with a pipeline-level trace, the latter blocks boot with a `FileLineData.linereport` pointing at one line.
- Proposing CI/CD or an automated release pipeline as though it already exists in some minimal form — it doesn't; frame it as new infrastructure requiring explicit buy-in.
