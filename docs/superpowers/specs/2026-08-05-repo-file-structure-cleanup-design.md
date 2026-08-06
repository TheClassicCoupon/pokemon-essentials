# Repo File Structure & Naming Cleanup (Pass 2)

## Context

Pass 1 of repo cleanup (commit `46eeb1bc`) gitignored large binary assets and removed unused junk files. This pass focuses on the project's file/folder structure and naming, to make the repo read more like a conventional codebase, while respecting the engine's real constraints:

- The mkxp-z runtime (a compiled binary we cannot inspect or modify) loads scripts from `Data/Scripts/` by walking that folder alphanumerically, depth-first. The `Data/Scripts/` path itself is fixed by the runtime. Everything *inside* it sorts by name, which is why subfolders/files carry `NNN_` numeric prefixes today.
- Top-level asset folders expected by the runtime/RPG Maker XP conventions (`Audio/`, `Graphics/`, `Fonts/`, `Plugins/`, `Data/`) are also effectively fixed — we have no way to verify or override what the closed-source runtime expects there.
- `PBS/*.txt` and `Text_english_core/*.txt` filenames are read by our own Ruby compiler code (`Data/Scripts/021_Compiler/`), not the runtime directly, so they *can* be renamed as long as the corresponding code is updated in lockstep.

Given the mixed risk profile, this cleanup is split into three independently testable phases, executed in order, each verified in `Game.exe` before moving to the next.

## Goals

- Improve clarity of the project's file/folder structure and naming so it better resembles a conventional codebase.
- Do this without changing any runtime-visible behavior (load order, data compiled, UI text, save compatibility).
- Keep each change small enough to verify manually (no automated test suite exists — see `CLAUDE.md` verification guidance).

## Non-goals

- Renaming individual `.rb` script files within `Data/Scripts/` (hundreds of files, already reasonably descriptive — out of scope for this pass, could be a future pass if desired).
- Any change to the `NNN_` numeric-prefix load-order mechanism itself (explicit manifest/require system was considered and explicitly rejected as higher-risk than warranted).
- Touching top-level engine-owned folders (`Audio/`, `Graphics/`, `Fonts/`, `Plugins/`, `Data/` itself) or root engine binaries (`Game.exe`, DLLs, `Game.ini`, `Game.rxproj`).

## Phase 1 — Root directory cleanup

**Change:** Create a new `Tools/` folder at repo root. Move into it, as a unit (they reference each other by sibling-relative paths):

- `animmaker.exe`, `animmaker.txt`
- `extendtext.exe`, `extendtext.txt`
- `knownpoint.bmp`, `selpoint.bmp`
- `townmapgen.html`
- `scripts_extract.rb`, `scripts_combine.rb`
- `Essentials Engine wiki.url`

Confirmed via grep across `Data/Scripts/` that none of these filenames are referenced anywhere in the Ruby scripts. `Game.exe`, its DLLs, `Game.ini`, `Game.rxproj`, `mkxp.json`, and `soundfont.sf2` (referenced by relative path inside `mkxp.json`) stay exactly where they are — moving them has no naming-clarity benefit and only adds risk.

**Risk:** Very low. Nothing in the compiled or scripted game logic depends on these paths.

**Verification:**
1. Launch `Game.exe`, confirm normal boot to title screen with no missing-file errors, confirm `soundfont.sf2`-backed MIDI BGM still plays if applicable.
2. From the new `Tools/` folder, launch `animmaker.exe` and `extendtext.exe` directly and confirm they still function (they depend on sibling files `knownpoint.bmp`/`selpoint.bmp` via relative path).
3. `git status` review before commit to confirm only the intended moves are staged.

## Phase 2 — `Data/Scripts/` folder naming cleanup

**Change:** Within `Data/Scripts/`, rename subfolders to remove spaces and normalize casing, keeping every `NNN_` numeric prefix identical (so depth-first alphanumeric load order is provably unchanged). Examples:

| Current | New |
|---|---|
| `002_Save data` | `002_SaveData` |
| `003_Game processing` | `003_GameProcessing` |
| `004_Game classes` | `004_GameClasses` |
| `004_Game classes/001_Switches and Variables` | `001_SwitchesAndVariables` |
| `006_Map renderer` | `006_MapRenderer` |
| `007_Objects and windows` | `007_ObjectsAndWindows` |
| `011_Battle/006_AI MoveEffects` | `006_AI_MoveEffects` |
| `011_Battle/007_Other battle code` | `007_OtherBattleCode` |
| `011_Battle/008_Other battle types` | `008_OtherBattleTypes` |
| `012_Overworld/001_Overworld visuals` | `001_OverworldVisuals` |
| `012_Overworld/002_Battle triggering` | `002_BattleTriggering` |
| `015_Trainers and player` | `015_TrainersAndPlayer` |
| `016_UI/001_Non-interactive UI` | `001_NonInteractiveUI` |
| `018_Alternate battle modes` | `018_AlternateBattleModes` |
| `018_Alternate battle modes/001_Battle Frontier` | `001_BattleFrontier` |
| `018_Alternate battle modes/002_Battle Frontier rules` | `002_BattleFrontierRules` |
| `018_Alternate battle modes/003_Battle Frontier generator` | `003_BattleFrontierGenerator` |
| `020_Debug/001_Editor screens` | `001_EditorScreens` |
| `020_Debug/002_Animation editor` | `002_AnimationEditor` |

Folders not listed (already clean, e.g. `001_Technical`, `005_Sprites`, `008_Audio`, `009_Scenes`, `010_Data`, `013_Items`, `014_Pokemon`, `017_Minigames`, `019_Utilities`, `021_Compiler`, `999_Main`) are left as-is.

**Risk:** Low. No numeric prefixes change, no files move between folders, only whitespace/casing in folder names changes.

**Verification, per batch (recommend batching by top-level folder):**
1. Hold Ctrl at boot (or use F9 debug menu → "Fully compile all data") to force a full recompile.
2. Confirm no load errors / missing script errors on boot.
3. Spot-check one flow touching the affected area (e.g. after renaming `011_Battle/*`, start a wild battle; after `016_UI/*`, open the Bag/Pokédex/Summary screens).
4. Commit each batch separately so a regression is easy to bisect.

## Phase 3 — PBS / `Text_english_core` filename review

**Change:** Candidates to evaluate and rename, each requiring a matching code change:

- `PBS/pokemon.txt`, `pokemon_forms.txt`, `pokemon_metrics.txt` — rename to align with the `Species`/`SpeciesMetrics` `GameData` class names (exact new names TBD at implementation time, e.g. `species.txt` family). Requires updating the `PBS_BASE_FILENAME` constant in `Data/Scripts/010_Data/002_PBS data/008_Species.rb` (and `010_SpeciesMetrics.rb`), since `021_Compiler/001_Compiler.rb#get_all_pbs_files_to_compile` matches sibling files by that constant's prefix.
- `PBS/cup_*_pkmn*.txt` — reconcile the `pkmn` abbreviation with the spelled-out `pokemon` used elsewhere in PBS filenames.
- `PBS/Shadow Pokémon backup/` — rename to an ASCII-safe `PBS/shadow_pokemon_backup/`. Confirmed via grep that no script reads this folder (it's inert archival data), so this is a pure filesystem rename.
- `Text_english_core/*.txt` (SCREAMING_SNAKE_CASE) vs. `PBS/*.txt` (lower_snake_case) — investigate how `Text_english_core` basenames are resolved (likely also centralized, similar to `PBS_BASE_FILENAME`) before committing to specific renames; document the finding and either reconcile casing or record why it's intentionally different.

Exact final naming choices for the `pokemon.txt` family and `cup_*_pkmn*` files will be confirmed with the user at implementation time before renaming, since these are subjective/taste calls, not mechanical cleanups.

**Risk:** Highest of the three phases — requires coordinated renames of both a data file and the code that names it, and any mismatch silently breaks data compilation for that category.

**Verification, per file/family renamed:**
1. Full recompile (Ctrl+boot or F9 → "Fully compile all data") and confirm the affected data compiles without error.
2. Open the relevant F9 debug data editor for that category and confirm it loads and saves correctly.
3. For `Text_english_core` files specifically, confirm in-game text (names, descriptions, dex entries as applicable) still renders correctly.
4. Commit each renamed family separately.

## Rollout

Three commits minimum (one per phase), each preceded by the verification steps above. If a phase's verification fails, fix or revert that phase's commit before starting the next phase — phases are not parallelized specifically so a regression stays isolated to a small, known diff.
