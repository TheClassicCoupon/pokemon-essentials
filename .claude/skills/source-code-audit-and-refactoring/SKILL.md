---
name: source-code-audit-and-refactoring
description: Use when reading, auditing, or refactoring anything under Scripts/ in this Pokemon Essentials repo — before adding a method, tracing a global, following a scene transition, changing a GameData:: class, planning a rename/move within Scripts/, or any correctness/architecture/maintainability review of engine code. Covers the two-era RGSS/pb-prefixed procedural style mixed with newer GameData::/Battle::/UI:: class code, load order across numbered script folders, and how to scope a refactor safely with no test suite.
---

# Source-Code Audit and Refactoring

## Overview
This repo runs on Ruby 3.0 via mkxp-z, but the code is two eras layered together: legacy RGSS procedural style (`pb`-prefixed globals like `pbConfirmMessage`, heavy use of `$game_*`/`$DEBUG`/`$scene`) and newer class-based code (`GameData::*`, `Battle::*`, `UI::*`). Neither era is being migrated away — match whichever convention the file being touched already uses (see CLAUDE.md; `.rubocop.yml` disables naming cops repo-wide for this reason).

This skill owns everything under `Scripts/`: architecture, runtime behavior, the public surface other code (and plugins/forks) calls into, state/lifecycle (`$game_*` globals, `$scene`), and readability/maintainability of engine code. It does **not** own the PBS→`Data/*.dat` compiler internals or packaging (`build-system-audit-and-refactoring`), PBS text-format validation (`pbs-data-validation`), or how to verify a change actually works (`verifying-essentials-changes`) — those are separate skills, cross-reference rather than duplicate.

For audit-vs-refactor mode and refactor intensity levels, see the shared refactoring model (`.claude/skills/_shared/refactoring-model.md`) — this skill doesn't restate it.

## Load Order Matters
`Scripts/` folders load alphanumerically, depth-first, by their numeric prefix. A class/module reopened in a later folder (e.g. `014_Pokemon` adding to something from `010_Data`) relies on the earlier folder having already loaded — when auditing whether a method exists yet at a given point in boot, load order is the first thing to check, not just a grep hit.

| Prefix | Layer | Look here for |
|---|---|---|
| 001_Technical | Input, file IO, plugin manager, error handling | `pbRgssOpen`, `pbPrintException`, `PluginManager` |
| 004_GameClasses | Legacy `Game_*` RGSS classes | `$game_map`, `$game_player`, `$game_system` |
| 010_Data | `GameData::*` typed data (from PBS) | `GameData::Species.get(:PIKACHU)` |
| 011_Battle | Battle engine | `Battle::Battler`, move effect handlers (`006_AI_MoveEffects`) |
| 014_Pokemon | Live `Pokemon` instances | `Pokemon#species_data` (→ `GameData::Species.get_species_form`), `Pokemon::Move` |
| 016_UI | Menu/screen implementations | Pokedex, Bag, Summary, PC, PauseMenu (`001_NonInteractiveUI`) |
| 018_AlternateBattleModes | Safari Zone, Bug Contest, Battle Frontier | `001_BattleFrontier`, `002_BattleFrontierRules`, `003_BattleFrontierGenerator` |
| 020_Debug | In-game debug menus/editors (F9) | `001_EditorScreens`, `002_AnimationEditor` |
| 021_Compiler | PBS↔Data + PBS↔map compiler | see `build-system-audit-and-refactoring` and `pbs-data-validation` |

Some subfolder names still contain spaces (`020_Debug/003_Debug menus`, `010_Data/002_PBS data`) while others have had spaces stripped in recent restructuring passes — confirm a subfolder's exact current name with `ls`/Glob rather than assuming either convention; see CLAUDE.md's folder-naming note.

## Never Hand-Edit the Compiled Script Blob
`Data/Scripts.rxdata` is gitignored/a stub — it is generated from the individual `.rb` files under `Scripts/` (a top-level folder, not under `Data/`), never the other way around. `Tools/scripts_extract.rb`/`Tools/scripts_combine.rb` exist only for round-tripping through the raw RPG Maker XP editor; don't run them as part of a normal edit. If tempted to open `.rxdata` in an editor, stop — find the source `.rb` file instead (same folder/number as the feature area).

## GameData::* Pattern
Every typed data class (`Species`, `Move`, `Item`, `Ability`, `Trainer`, ...) mixes in one of three sibling modules in `Scripts/010_Data/001_GameData.rb` — `ClassMethodsSymbols` (symbol-keyed; what Species/Move/Item/Ability/Trainer/... actually extend), `ClassMethodsIDNumbers` (integer-keyed, e.g. `TownMap`, `Metadata`), or the base `ClassMethods` (used only by `Weather`/`TerrainTag`) — each giving the same uniform interface backed by a class constant `DATA` hash:

```ruby
GameData::Species.get(:PIKACHU)       # raises if missing
GameData::Species.try_get(:PIKACHU)   # nil if missing
GameData::Species.exists?(:PIKACHU)   # boolean
GameData::Species.each { |s| ... }    # iterate all
```

`.get`/`.try_get`/`.exists?` all accept a Symbol, String, Integer ID, or an instance of the class itself — when auditing a lookup site, flag one that hand-rolls type branching instead of using the accessor. Instances are populated from PBS text via `.register(hash)` at compile time (see `pbs-data-validation`) — `DATA` should never be constructed or mutated by hand outside the compiler; a refactor that does so is a correctness bug, not a style nit.

## Legacy pb-Prefixed Globals
Procedural helpers (`pbConfirmMessage`, `pbCompilerEachPreppedLine`, `pbPrintException`, `pbGetUserName`) and globals (`$game_temp`, `$game_switches`, `$PokemonGlobal`, `$scene`) are still the primary interface for overworld/menu flow control — don't wrap them in new classes speculatively during a refactor; extend them the way surrounding code does. `$scene` holds the active `Scene_*`/`UI::*` object; scene transitions go through `pbFadeOutIn` or direct `$scene =` reassignment, both idiomatic here.

## Auditing a Change's Blast Radius
Before a Level 2+ refactor (see shared refactoring model), grep for every call site of the method/global/class being touched — Ruby's dynamism (globals, `send`, `respond_to?`) means a signature change silently breaks a caller rather than failing to compile. Pay particular attention to:
- Plugin scripts (`Plugins/`, gitignored — not searchable if not installed locally; note this as an unverifiable blast-radius gap rather than assuming no plugin depends on it) and forks pulling from this repo (README's fork workflow) — a public `GameData::*`/`Battle::*` accessor is a de facto public API even without a formal contract.
- Battle AI move-effect handlers (`011_Battle/006_AI_MoveEffects`) — often referenced by an effect-ID string from PBS data (`moves.txt`), not a direct Ruby reference, so a plain grep for the method/class name won't find the PBS-side link; cross-check against `pbs-data-validation`.

## Common Mistakes
- Editing `Data/Scripts.rxdata` directly instead of the `.rb` source file.
- Introducing snake_case method names in a camelCase-convention file "for consistency with Ruby style" — this repo intentionally keeps `pb`-prefixed camelCase; `.rubocop.yml` disables `Naming/MethodName` for this reason.
- Reaching for `GameData::Species::DATA[...]` directly instead of `.get`/`.try_get` — bypasses validation and the Symbol/String/Integer normalization.
- Forgetting that `GameData::Species` (template data) and `Pokemon` (a caught/owned instance, `014_Pokemon`) are different classes — a `Pokemon` has a `.species` lookup into `GameData::Species`, it doesn't subclass it.
- Treating a clean `rubocop` run or a successful boot as proof a Level 2+ refactor is correct — neither exercises the changed flow; see `verifying-essentials-changes`.
