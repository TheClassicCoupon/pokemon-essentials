# Deferred: Test Infrastructure Plan

Referenced from `claude-repository-adaptation`'s "Deferred: Test-Code Audit and Refactoring" section. This is a recommendation, not an implemented plan — do not implement it during a routine adaptation pass; only act on it if the user explicitly asks to set up testing.

## Why deferred
As of this writing there is no `spec/`, `test/`, or equivalent directory, no test framework in the codebase, and no CI to run one. The engine is loaded and driven almost entirely through mkxp-z's `Game.exe` and heavy use of global state (`$game_*`, `$PokemonGlobal`, `$scene`), which makes naive "test the whole engine" infrastructure both hard to write and slow to run. Inventing a test skill ahead of any actual test code would document conventions nobody has established yet.

## Stage 1 — Foundation recommendation
- **Framework:** RSpec is the conventional choice for Ruby 3.0 and needs no engine boot for logic that doesn't touch `$game_*`/RGSS globals or mkxp-z-provided classes (`Graphics`, `Audio`, `Input`, `RPG::*`).
- **Scope constraint:** most of `Scripts/` is unsuitable for unit testing as-is because it's entangled with mkxp-z runtime globals that only exist inside `Game.exe`. Realistic first-target code is pure-logic pieces reachable without booting the engine — e.g. PBS-line parsing/coercion helpers in `Scripts/021_Compiler/001_Compiler.rb` (the `csv*!` coercers), and any `GameData::*` lookup/normalization logic that only needs a hash, not the running engine.
- **Structure:** a top-level `spec/` directory mirroring `Scripts/`'s numbered-folder structure for whatever subset is covered, plus a `spec_helper.rb` that stubs or excludes the mkxp-z-only globals rather than trying to boot the real engine.
- **Command:** `bundle exec rspec` (would need a `Gemfile` — none currently exists in this repo either, confirm before assuming Bundler is set up).
- **Local/CI:** local-only initially; a headless CI run can't exercise anything requiring `Game.exe`/a display, so CI value is limited to the pure-logic subset plus `rubocop`.

## Stage 2 — Initial test priorities (once Stage 1 exists)
In priority order: PBS field coercers/validators (`csvInt!`, `csvEnumField!`, etc. — high-value, pure logic, currently a common source of confusing runtime errors per `pbs-data-validation`); `GameData::*` accessor normalization (`.get`/`.try_get`/`.exists?` Symbol/String/Integer/instance handling); any known-defect area surfaced by a future audit. Don't write placeholder/no-op tests to pad coverage.

## Stage 3 — Readiness criteria
Before creating the `Test-Code Audit and Refactoring` skill, confirm: a working `bundle exec rspec` (or equivalent) command; a clear directory convention; at least one meaningful test category actually implemented (not just scaffolding); safe test isolation from the real `Data/`/`PBS/` trees (tests should not read/write the developer's live game data); documented environment requirements (Ruby version, gems).

## Stage 4 — Trigger
Once Stage 3's criteria are met, that's a Level 1 self-trigger for `claude-repository-adaptation`: inspect the implemented conventions (don't assume they match this plan exactly) and create `.claude/skills/test-code-audit-and-refactoring/SKILL.md` following the same repo-local skill conventions as the other required skills.
