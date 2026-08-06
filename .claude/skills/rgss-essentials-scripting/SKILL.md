---
name: rgss-essentials-scripting
description: Use when reading or editing files under Scripts/ in this Pokemon Essentials repo — before adding a method, tracing a global, following a scene transition, or touching a GameData:: class. Covers RGSS/pb-prefixed procedural conventions mixed with newer GameData::/Battle::/UI:: class code, and the load order across numbered script folders.
---

# RGSS Essentials Scripting

## Overview
This repo runs on Ruby 3.0 via mkxp-z, but the code is two eras layered together: legacy RGSS procedural style (`pb`-prefixed globals like `pbConfirmMessage`, heavy use of `$game_*`/`$DEBUG`/`$scene`) and newer class-based code (`GameData::*`, `Battle::*`, `UI::*`). Neither era is being migrated away — match whichever convention the file you're editing already uses (see CLAUDE.md, `.rubocop.yml` disables naming cops repo-wide for this reason).

## Load Order Matters
`Scripts/` folders load alphanumerically, depth-first, by their numeric prefix. A class/module reopened in a later folder (e.g. `014_Pokemon` adding to something from `010_Data`) relies on the earlier folder having already loaded. When grepping for a definition, the numeric prefix tells you roughly what layer you're in — `010_Data` = typed data classes, `011_Battle` = battle engine, `014_Pokemon` = live Pokemon instances (distinct from `010_Data`'s `GameData::Species`, the species template), `016_UI` = screens.

| Prefix | Layer | Look here for |
|---|---|---|
| 001_Technical | Input, file IO, plugin manager, error handling | `pbRgssOpen`, `pbPrintException`, `PluginManager` |
| 004_GameClasses | Legacy `Game_*` RGSS classes | `$game_map`, `$game_player`, `$game_system` |
| 010_Data | `GameData::*` typed data (from PBS) | `GameData::Species.get(:PIKACHU)` |
| 011_Battle | Battle engine | `Battle::Battler`, move effect handlers |
| 014_Pokemon | Live `Pokemon` instances | `Pokemon#species_data` (→ `GameData::Species.get_species_form`), `Pokemon::Move` |
| 016_UI | Menu/screen implementations | Pokedex, Bag, Summary, PC |
| 021_Compiler | PBS↔Data + PBS↔map compiler | see the pbs-data-validation skill |

## Never Hand-Edit the Compiled Script Blob
`Data/Scripts.rxdata` is gitignored/a stub — it is generated from the individual `.rb` files under `Scripts/` (a top-level folder, not under `Data/`), never the other way around. `Tools/scripts_extract.rb`/`Tools/scripts_combine.rb` exist only for round-tripping through the raw RPG Maker XP editor; don't run them as part of a normal edit. If you're tempted to open `.rxdata` in an editor, stop — find the source `.rb` file instead (it has the same folder/number in its path as the feature area).

## GameData::* Pattern
Every typed data class (`Species`, `Move`, `Item`, `Ability`, `Trainer`, ...) mixes in one of three sibling modules in `Scripts/010_Data/001_GameData.rb` — `ClassMethodsSymbols` (symbol-keyed; what Species/Move/Item/Ability/Trainer/... actually extend), `ClassMethodsIDNumbers` (integer-keyed, e.g. `TownMap`, `Metadata`), or the base `ClassMethods` (used only by `Weather`/`TerrainTag`) — each giving the same uniform interface backed by a class constant `DATA` hash:

```ruby
GameData::Species.get(:PIKACHU)       # raises if missing
GameData::Species.try_get(:PIKACHU)   # nil if missing
GameData::Species.exists?(:PIKACHU)   # boolean
GameData::Species.each { |s| ... }    # iterate all
```

`.get`/`.try_get`/`.exists?` all accept a Symbol, String, Integer ID, or an instance of the class itself — don't write your own type-branching lookup, use the accessor. Instances are populated from PBS text via `.register(hash)` at compile time (see the pbs-data-validation skill) — don't construct or mutate `DATA` by hand outside the compiler.

## Legacy pb-Prefixed Globals
Procedural helpers (`pbConfirmMessage`, `pbCompilerEachPreppedLine`, `pbPrintException`, `pbGetUserName`) and globals (`$game_temp`, `$game_switches`, `$PokemonGlobal`, `$scene`) are still the primary interface for overworld/menu flow control — don't wrap them in new classes speculatively; extend them the way surrounding code does. `$scene` holds the active `Scene_*`/`UI::*` object; scene transitions go through `pbFadeOutIn` or direct `$scene =` reassignment, both idiomatic here.

## Common Mistakes
- Editing `Data/Scripts.rxdata` directly instead of the `.rb` source file.
- Introducing snake_case method names in a camelCase-convention file "for consistency with Ruby style" — this repo intentionally keeps `pb`-prefixed camelCase; `.rubocop.yml` disables `Naming/MethodName` for this reason.
- Reaching for `GameData::Species::DATA[...]` directly instead of `.get`/`.try_get` — bypasses validation and the Symbol/String/Integer normalization.
- Forgetting that `GameData::Species` (template data) and `Pokemon` (a caught/owned instance, `014_Pokemon`) are different classes — a `Pokemon` has a `.species` lookup into `GameData::Species`, it doesn't subclass it.
