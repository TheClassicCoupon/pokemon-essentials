# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Pokémon Essentials v21.1 — a Ruby-based engine/framework for building Pokémon fangames, originally built for RPG Maker XP (RGSS) and run today via the mkxp-z runtime (`Game.exe` on Windows, configured by `mkxp.json`/`Game.ini`). This repo is the engine itself, intended to be forked and built on top of; there is no separate "app" layer.

There is no npm/cargo/make-style build system, no test suite, and no CI-run linter in this repo — it's a Ruby scripting layer loaded into a game engine at runtime. "Building" means launching the game, which triggers an in-engine compile step (see below).

## Running the game

Launch `Game.exe` (mkxp-z). It reads `Game.ini` (points at `Data\Scripts.rxdata`) and `mkxp.json` for window/runtime settings, then boots into `Scripts/999_Main/999_Main.rb`.

- The `Audio/`, `Graphics/`, and `Plugins/` folders, and almost everything under `Data/` (except `Data/messages_core.dat`) are gitignored — they contain binary game assets/compiled data not tracked in this repo. `Data/Scripts.rxdata` itself is also gitignored; it's a locally-generated script cache, not a tracked file. The human-authored `Scripts/` folder is a separate top-level folder (not under `Data/`) and is fully tracked. A working checkout needs a full copy of Essentials v21.1 assets merged with this repo's tracked files (see README.md for the fork workflow).
- In `$DEBUG` mode (i.e. not a compiled `.rgssad` release build), the engine auto-recompiles `PBS/*.txt` into `Data/*.dat` at startup whenever a PBS file is newer than the compiled data. Force a full recompile by holding Ctrl at boot, or via the in-game debug menu (F9 in-map, or during battle) → "Fully compile all data".

## Script source layout — the core architecture

Game logic is **not** stored in `Data/Scripts.rxdata` in this repo (that file is gitignored and, when present, is a tiny stub that just loads the real scripts). Instead, all scripts live as individual `.rb` files under `Scripts/`, organized into numbered top-level folders that are loaded alphanumerically, depth-first:

```
001_Technical           Core engine plumbing: input, file/IO helpers, plugin manager, debugging/errors
002_SaveData
003_GameProcessing      Core game loop, scene stack
004_GameClasses
005_Sprites
006_MapRenderer
007_ObjectsAndWindows   UI framework primitives (windows, sprites, controls)
008_Audio
009_Scenes
010_Data                GameData::* classes (Species, Move, Item, Ability, Trainer, ...) — the typed data layer built from PBS
011_Battle              Battle engine: Battle, Battler, Move, Scene, AI, per-move AI effects
012_Overworld
013_Items
014_Pokemon             Pokemon, Move (instance), MegaEvolution, ShadowPokemon, Owner
015_TrainersAndPlayer
016_UI                  Menu/screen implementations (Pokedex, Bag, Summary, PC, Mart, etc.)
017_Minigames
018_AlternateBattleModes
019_Utilities
020_Debug               Debug menus, data editors used in-game (F9)
021_Compiler            Compiles PBS/* text files and map/event data into Data/*.dat
999_Main                Entry point (mainFunction / mainFunctionDebug)
```

Only edit the individual `.rb` files under `Scripts/` — never hand-edit `Data/Scripts.rxdata` directly. `Tools/scripts_extract.rb` (rxdata → individual `.rb` files) and `Tools/scripts_combine.rb` (individual `.rb` files → rxdata) exist only for round-tripping through the raw RPG Maker XP editor and are not part of the normal git-based workflow.

## Data pipeline: PBS ↔ GameData

`PBS/` contains human-editable, plain-text data definitions (`pokemon.txt`, `moves.txt`, `abilities.txt`, `items.txt`, `trainers.txt`, `encounters.txt`, `metadata.txt`, etc.). `Scripts/021_Compiler` parses these into binary `Data/*.dat` files, which are loaded at runtime into `GameData::*` classes defined in `Scripts/010_Data/002_PBS data/` (one file per data type: `Species`, `Move`, `Item`, `Ability`, `Trainer`, `Encounter`, ...).

- Each `GameData::*` class mixes in `GameData::ClassMethods`/`ClassMethodsSymbols` (`Scripts/010_Data/001_GameData.rb`), giving uniform `.get`, `.try_get`, `.exists?`, `.each`, `.load`, `.save` accessors backed by a `DATA` hash.
- When adding/changing game data (a move, an ability, a species), the normal path is editing the relevant `PBS/*.txt` file and letting the compiler regenerate `Data/*.dat` on next boot — not hand-writing to `GameData::DATA`.
- Compiler-side PBS parsing lives in `Scripts/021_Compiler/002_Compiler_CompilePBS.rb` (PBS → Data) and `003_Compiler_WritePBS.rb` (Data → PBS, used by in-game data editors).

## Plugins

`Plugins/` (gitignored) holds third-party/optional plugin scripts, each in its own subfolder with a `meta.txt` describing name/version/dependencies/conflicts. `Scripts/001_Technical/005_PluginManager.rb` reads `meta.txt` files, resolves load order from dependencies, compiles plugin scripts into `Data/PluginScripts.rxdata`, and evals them at boot. See the large comment block at the top of that file for the `meta.txt` format and `PluginManager.register` options.

## Code style

`.rubocop.yml` targets Ruby 3.0 with most naming cops disabled — the codebase mixes two eras of convention:
- Legacy RGSS-style procedural functions with `pb`-prefixed camelCase names (e.g. `pbConfirmMessage`, `pbCompilerEachPreppedLine`) and heavy use of globals (`$game_...`, `$DEBUG`, `$scene`).
- Newer class-based code (`GameData::*`, `Battle::*`, `UI::*`) still largely using camelCase methods for consistency with the surrounding codebase.

Follow the existing convention in whichever file/area you're editing rather than imposing snake_case; `Naming/MethodName`, `Naming/MethodParameterName`, `Naming/VariableName`, and `Metrics` cops are intentionally disabled repo-wide. Double-quoted strings are preferred (`Style/StringLiterals: double_quotes`).

## Verifying changes

There is no automated test suite. Verification means launching `Game.exe` in debug mode and exercising the relevant menu/battle/map flow directly (the F9 debug menu gives access to data editors, map/event tools, and a "fully compile all data" option useful after PBS edits). If `rubocop` is installed, `rubocop` can be run against changed files to catch style issues consistent with `.rubocop.yml`.
