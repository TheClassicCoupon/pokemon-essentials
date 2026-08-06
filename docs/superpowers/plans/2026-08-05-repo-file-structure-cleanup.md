# Repo File Structure & Naming Cleanup (Phases 1-3) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Clean up the repo's root-level clutter, relocate human-authored source code out from under the generated `Data/` folder, and normalize `Data/Scripts/` (soon `Scripts/`) folder naming — without changing any runtime-visible behavior.

**Architecture:** Three sequential, independently-committed, independently-verified phases. Phase 2 is load-bearing for Phase 3 (Phase 3 operates on the folder Phase 2 relocates), so phase order is fixed. No code architecture changes — this is a file/folder reorganization plan plus one binary-artifact regeneration.

**Tech Stack:** Ruby 4.0 (local interpreter available for one-off scripts), RGSS scripts run by the mkxp-z runtime (`Game.exe`), git for all moves (`git mv`, never plain `mv`, so history is preserved).

## Global Constraints

- This is a Ruby/RGSS scripting project with **no automated test suite** (see `CLAUDE.md`). Every "verify" step in this plan means a manual check — booting `Game.exe`, forcing a recompile via Ctrl+boot or the F9 debug menu, or spot-checking a specific in-game flow — not an automated test run.
- No numeric load-order prefix (`NNN_`) may change value in any task, only the text after it (folder-naming cleanup is provably load-order-neutral only if this holds).
- Every folder/file move uses `git mv` so git history follows the file.
- `Data/Scripts.rxdata` is gitignored, locally-generated, and must never be committed. It's mentioned in Task 2 only because Task 2 must regenerate it correctly as part of verifying the relocation.
- **Known-state prerequisite:** as of this plan's authoring, the local `Data/Scripts.rxdata` was found stale (didn't reflect current tracked `.rb` source at all) and was regenerated as the dynamic loader stub, confirmed via a marker-file boot test. Task 2 assumes this fixed, correct starting state — if a fresh contributor is executing this plan on a different machine, they need a valid, current `Data/Scripts.rxdata` in stub form before Task 2's edits will be verifiable (Task 2 Step 1 covers producing one from scratch either way).

---

## File Structure

Files touched across this plan:

- **Root:** new `Tools/` folder (created in Task 1); `Data/Scripts/` → `Scripts/` (moved in Task 2); `scripts_extract.rb`, `scripts_combine.rb` (edited in Task 2, then relocate into `Tools/` in Task 1 — see ordering note below); `.gitignore`, `README.md`, `CLAUDE.md` (edited in Task 2).
- **`Scripts/001_Technical/003_Intl_Messages.rb`:** one path string edited in Task 2.
- **`Scripts/*` subfolders:** renamed in Tasks 3-13, no file content changes.

**Ordering note:** Task 1 moves `scripts_extract.rb`/`scripts_combine.rb` into `Tools/`. Task 2 edits those same files' path defaults and embedded loader blob. To avoid editing files mid-move, **Task 2 must run before Task 1** relocates those two specific files — but Task 1 also moves unrelated files that have no ordering dependency. Resolution: Task 1 moves everything *except* `scripts_extract.rb`/`scripts_combine.rb` first; those two move at the end of Task 2, after their content edits are done and verified. Task lists below reflect this.

---

## Task 1: Root directory cleanup

**Files:**
- Create: `Tools/` (new folder)
- Move: `animmaker.exe`, `animmaker.txt`, `extendtext.exe`, `extendtext.txt`, `knownpoint.bmp`, `selpoint.bmp`, `townmapgen.html`, `Essentials Engine wiki.url` → `Tools/`

**Interfaces:**
- Consumes: nothing (root files as they exist today).
- Produces: `Tools/` folder containing the above files, at their original relative arrangement to each other (they reference each other by sibling-relative path).

- [ ] **Step 1: Create the Tools folder and move the unreferenced editor tooling into it**

```bash
mkdir Tools
git mv "animmaker.exe" "Tools/animmaker.exe"
git mv "animmaker.txt" "Tools/animmaker.txt"
git mv "extendtext.exe" "Tools/extendtext.exe"
git mv "extendtext.txt" "Tools/extendtext.txt"
git mv "knownpoint.bmp" "Tools/knownpoint.bmp"
git mv "selpoint.bmp" "Tools/selpoint.bmp"
git mv "townmapgen.html" "Tools/townmapgen.html"
git mv "Essentials Engine wiki.url" "Tools/Essentials Engine wiki.url"
```

- [ ] **Step 2: Verify nothing references the old root-level paths**

```bash
grep -rn "animmaker\|extendtext\|knownpoint\.bmp\|selpoint\.bmp\|townmapgen\.html" Data/Scripts/
```

Expected: no matches (already confirmed during spec research, this is a re-confirmation).

- [ ] **Step 3: Verify the game still boots**

Launch `Game.exe` from the repo root, confirm normal boot to the title screen, no missing-file errors. Close the game.

- [ ] **Step 4: Verify the relocated tools still function**

From `Tools/`, launch `animmaker.exe` and `extendtext.exe` directly. Confirm both open without complaining about missing `knownpoint.bmp`/`selpoint.bmp` (they resolve those via sibling-relative path, which is preserved since all four files moved together).

- [ ] **Step 5: Commit**

```bash
git add -A
git status
git commit -m "Move unreferenced RPG Maker XP editor tooling into Tools/"
```

---

## Task 2: Relocate `Data/Scripts/` to a top-level `Scripts/` folder

**Files:**
- Move: `Data/Scripts/` → `Scripts/`
- Modify: `scripts_extract.rb`, `scripts_combine.rb` (path defaults + embedded loader blob), `Scripts/001_Technical/003_Intl_Messages.rb:24`, `.gitignore`, `README.md`, `CLAUDE.md`
- Move (after editing): `scripts_extract.rb`, `scripts_combine.rb` → `Tools/`

**Interfaces:**
- Consumes: `Tools/` folder from Task 1 (destination for the final sub-step).
- Produces: `Scripts/` at repo root, containing everything formerly under `Data/Scripts/`. `Data/Scripts.rxdata` (gitignored, not committed) regenerated to load from `Scripts/` instead of `Data/Scripts/`. This is what Tasks 3-13 operate on.

- [ ] **Step 1: Move the folder**

```bash
git mv "Data/Scripts" "Scripts"
```

- [ ] **Step 2: Update the path defaults in both round-trip tools**

In `scripts_extract.rb`, change both occurrences of the default parameter:

```ruby
# Before (appears twice: in `self.dump` and `self.from_folder`)
def self.dump(path = "Data/Scripts", rxdata = "Data/Scripts.rxdata")
...
def self.from_folder(path = "Data/Scripts", rxdata = "Data/Scripts.rxdata")
```

```ruby
# After
def self.dump(path = "Scripts", rxdata = "Data/Scripts.rxdata")
...
def self.from_folder(path = "Scripts", rxdata = "Data/Scripts.rxdata")
```

Note `rxdata` does **not** change — the compiled cache stays at `Data/Scripts.rxdata`, matching `Game.ini`'s `Scripts=Data\Scripts.rxdata` setting, which is untouched.

Make the identical edit in `scripts_combine.rb` (both files currently have byte-identical bodies apart from their final two lines).

- [ ] **Step 3: Replace the embedded loader blob in both files**

In both `scripts_extract.rb` and `scripts_combine.rb`, inside `self.createLoaderScripts`, replace the `txt = "..."` line with this pre-validated blob (decompiles to the same loader source, with `load_scripts_from_folder("Data/Scripts")` changed to `load_scripts_from_folder("Scripts")` — verified via a full decompress → edit → recompress → `Marshal.dump`/`Marshal.load` → re-inflate round trip that reproduced the exact edited source):

```ruby
		txt = "x\x9C}SK\x8F\x9B0\x10\xBEG\xCA\x7F\x18\xD8H\x8062\x9Bc\x0Fi\x0F}\xA9\xA7V\x9B\xDC\x02E<\x86\xC4]b#\xDB4\xDD\x86\xFC\xF7\xB5!\xE0\xD0m{\x01\xE6\xF5\xCD\xCC7\x1Fw\xB0=P\t\x05G\t\x8C+8q\xF1\x04\xB4\x04u@\xD8\xA7G\x04\x1DD\x96\x8B\xE7Za\xE1\xCCg\xF3Y\x81:*\xD2\x1C\xB34\x7FJ\x04\xD6\\\xA8\xF9\f\xC0\x98\x9D\x1F\xD6\xB0p\xC8h\x92\xBC\xE2\f'\x19\x04\xD3\xFCp\x866S\xAD\xF1\xEB\x88\"\xB2\xC9\x1C?\x8C\xCE~T\xDC\a\xD1%\f\xE0\xEC\xEE\xEE\xCE\x8B\xD5%\xD6\xCF\xC7\xCF\x9BM\xB2y\xFF\xF8\xE5\xDBv\xB3[\xAC\x88\xE2\t\x8Dw\xAB\xF8\xE2^\fB\xF7\x10\xA8\x1A\xC1L\xEF#J\x99\xEE\x11\xEE\xC1\x8DX\xC4\\\xFDa{\xFF\xE0\x94\xF9\xDA\xEF\x06\xF3\x19\xB2bXI\xA4Tbb\x17C!\xB80\xB0\x9A\f\vI$\xFD\x8D\xF0v\ro\x1E\x1E\xFA\xD1?\xD1\n\t\xAF\x91\xF9\xDEXL*\xBE\xF7\x96\xE0\x9D<\xBD\x05\xB4e\v%9\t\xAA\xD0_8A?,\xF4\r\xC1\xDB\x0EE\x86i\xC59dtO\xE0k\xA3\xEAF\x01e0\x055\xA5XI\xBC\x81\xE8\\f\x8F\x9Be*\x9E\x16\x89\xCC\x05\xAD\x95LJ\xC1\x8FI\xC9\xAB\x02\x85_\xA7\xEA\x10\x98\x8AR\x8F-5\xC4\x1Avqgwq9\xDA\x1F\xA8 %\x17\xE6P}\x91\x96\x88\xD9\xA4o\xCC\xF0\x972\xC4\x94\xB0^\x83G<h\xDB\xE1\x9Bx}\x8A\x8Ev\xD4\x14T`\xAE\xB8x~\xD7\xE1\x98\x9B\x84\xE6 e\xD0\xE7\x8D\xADI\xDD\xC8\x83_\x06\xA6\xD2)w\xE1\xF7\x88\x84q\x9Fc7\xBE\x0E~\x9B\xABS#\"\xB2EH\x87l\xC3\xC3\xF8\xEA\xF3\xA5\x16\xA9cM\xB3\xD6d\xA1\x9C\x17F\xB7\xF6\x98\xD3Y\x97\xE0\n\xB7\xBF\xA5\xCEh;\x14\xA2\xC9)\x86cf\xB8\xA7l\x18\x11\x7F\xA6\x95o\x10\x97\xC0h\xB5\x1CW\x15(\xF3\x06a\xD3\xDD\xE5\xE3\xA0/\xAB\x85\x9B\x00ax\xF2\xAD\xEC&\x00C\xD1\xAD*\xCD\xCFc\xED\xE5\xAB\x1F4\x98t\xFA\x9B\xCC_\xF1v\xBD\x8Ae\xEE\xEA\xB0\xDCu\x8E+\x81\xFFU\x9C%\xB2\xF3\x05\x7FJ\xF6\x9F\xC5nO\x89t\x83\x17\b\x9Ad6"
```

- [ ] **Step 4: Update the one other hardcoded reference**

In `Scripts/001_Technical/003_Intl_Messages.rb:24`:

```ruby
# Before
Dir.all("Data/Scripts").each do |script_file|
```

```ruby
# After
Dir.all("Scripts").each do |script_file|
```

- [ ] **Step 5: Update `.gitignore`**

Currently:

```gitignore
# Data folder, but not Data/Scripts folder or messages_core.dat
# Data/Scripts.rxdata is a locally-generated script cache — not tracked (see CLAUDE.md)
Data/*
!Data/Scripts/
!Data/messages_core.dat
```

Change to:

```gitignore
# Data folder, except messages_core.dat
# Data/Scripts.rxdata is a locally-generated script cache — not tracked (see CLAUDE.md)
Data/*
!Data/messages_core.dat
```

(`Scripts/` is now its own top-level tracked folder, outside the `Data/*` ignore rule entirely — no carve-out needed.)

- [ ] **Step 6: Update documentation references**

In `README.md`, replace the three `Data/Scripts/` mentions (in the "Scripts" section) with `Scripts/`. In `CLAUDE.md`, update the "Script source layout" section's references to `Data/Scripts/` to say `Scripts/` instead (the folder tree diagram's path context, and the sentence "Only edit the individual `.rb` files under `Data/Scripts/`").

- [ ] **Step 7: Regenerate the local `Data/Scripts.rxdata` stub from the new location**

`scripts_combine.rb`'s trailing `Scripts.from_folder` call won't help here — it refuses to touch an rxdata that already looks "combined" (>10 sections), and after Task 2 Step 1's move plus Step 2/3's edits, we specifically need the *stub* form regenerated from `Scripts/`, not a full bake-in. Run this one-off command from the repo root (do not commit this script; it's a manual verification step, matching the technique already used once this session to fix the pre-existing stale-rxdata problem):

```bash
ruby -e '
require "zlib"
content = File.read("scripts_combine.rb", encoding: "ASCII-8BIT")
m = content.match(/txt = ("(?:\\.|[^"\\])*")/m)
raw = eval(m[1])
source = Zlib::Inflate.inflate(raw)
raise "blob still points at old path" unless source.include?(%q{load_scripts_from_folder("Scripts")})
File.open("Data/Scripts.rxdata", "wb") { |f| Marshal.dump([[62054200, "Main", raw]], f) }
puts "Rewrote Data/Scripts.rxdata to load from Scripts/"
'
```

Expected output: `Rewrote Data/Scripts.rxdata to load from Scripts/` (the `raise` guards against running this before Step 3 is actually saved).

- [ ] **Step 8: Verify via the marker-file boot test**

Temporarily add this as the very first line of `Scripts/999_Main/999_Main.rb` (before `class Scene_DebugIntro`):

```ruby
File.write("STRUCTURE_TEST_MARKER.txt", "loaded from current source at #{Time.now}")
```

```bash
rm -f STRUCTURE_TEST_MARKER.txt
(./Game.exe &) ; sleep 6
ls -la STRUCTURE_TEST_MARKER.txt
cat STRUCTURE_TEST_MARKER.txt
```

Expected: the file exists with a current timestamp — proving the game loaded `999_Main.rb` (and by extension, the whole `Scripts/` tree) from the new location. Then:

```bash
taskkill //IM Game.exe //F
```

Remove the temporary `File.write` line from `999_Main.rb` and delete `STRUCTURE_TEST_MARKER.txt`.

- [ ] **Step 9: Broader smoke test**

Boot `Game.exe` again (without the marker line this time — it's already been removed). Confirm: title screen loads, start/continue a game, move the player character in the overworld, open the main menu, trigger one wild battle, save and reload. This exercises code from many different original folders (`003_Game processing`, `004_Game classes`, `009_Scenes`, `011_Battle`, `012_Overworld`, `016_UI`), giving confidence the whole tree loaded correctly, not just `999_Main.rb`.

- [ ] **Step 10: Force a full recompile as an unrelated general-health check**

Hold Ctrl while launching `Game.exe` (or use the F9 debug menu → "Fully compile all data" once in-game). Confirm PBS compilation still completes without error — this phase didn't touch `PBS/` or the compiler, so this should be a no-op pass, but it's a cheap confirmation nothing else broke.

- [ ] **Step 11: Move the two round-trip tool scripts into Tools/ now that their edits are done and verified**

```bash
git mv "scripts_extract.rb" "Tools/scripts_extract.rb"
git mv "scripts_combine.rb" "Tools/scripts_combine.rb"
```

- [ ] **Step 12: Update the two remaining path references these files use for themselves**

Both files reference `Data/ScriptsBackup.rxdata` (an absolute-from-repo-root path, unaffected by which folder the tool script itself lives in) — no change needed there, since these are invoked from the repo root regardless of which folder they physically live in. Confirm this by re-reading the moved files and checking no `path`/`rxdata` default still says `Data/Scripts` (should already be `Scripts` / `Data/Scripts.rxdata` from Steps 2-3):

```bash
grep -n "Data/Scripts\"" Tools/scripts_extract.rb Tools/scripts_combine.rb
```

Expected: no matches (the only remaining `Data/Scripts` substring should be `Data/Scripts.rxdata`, which is correct and unchanged).

- [ ] **Step 13: Commit**

```bash
git add -A
git status
git commit -m "Relocate Scripts/ out from under Data/, decoupling source from compiled cache"
```

---

## Task 3: Rename `002_Save data`

**Files:**
- Move: `Scripts/002_Save data/` → `Scripts/002_SaveData/`

**Interfaces:**
- Consumes: `Scripts/` folder from Task 2.
- Produces: `Scripts/002_SaveData/`.

- [ ] **Step 1: Rename**

```bash
git mv "Scripts/002_Save data" "Scripts/002_SaveData"
```

- [ ] **Step 2: Verify**

Force a full recompile (Ctrl+boot or F9 → "Fully compile all data"). Confirm no load errors on boot. Start a game, save, then load that save — this folder holds the save-data scripts.

- [ ] **Step 3: Commit**

```bash
git add -A
git commit -m "Rename Scripts/002_Save data to 002_SaveData"
```

---

## Task 4: Rename `003_Game processing`

**Files:**
- Move: `Scripts/003_Game processing/` → `Scripts/003_GameProcessing/`

**Interfaces:**
- Consumes: `Scripts/` folder from Task 2.
- Produces: `Scripts/003_GameProcessing/`.

- [ ] **Step 1: Rename**

```bash
git mv "Scripts/003_Game processing" "Scripts/003_GameProcessing"
```

- [ ] **Step 2: Verify**

Force a full recompile. Confirm no load errors on boot. Move the player around the overworld and open the main menu (this folder holds core game-loop/interpreter code, exercised by both).

- [ ] **Step 3: Commit**

```bash
git add -A
git commit -m "Rename Scripts/003_Game processing to 003_GameProcessing"
```

---

## Task 5: Rename `004_Game classes` and its subfolder

**Files:**
- Move: `Scripts/004_Game classes/` → `Scripts/004_GameClasses/`
- Move: `Scripts/004_GameClasses/001_Switches and Variables/` → `Scripts/004_GameClasses/001_SwitchesAndVariables/`

**Interfaces:**
- Consumes: `Scripts/` folder from Task 2.
- Produces: `Scripts/004_GameClasses/001_SwitchesAndVariables/`.

- [ ] **Step 1: Rename the parent folder, then the child**

```bash
git mv "Scripts/004_Game classes" "Scripts/004_GameClasses"
git mv "Scripts/004_GameClasses/001_Switches and Variables" "Scripts/004_GameClasses/001_SwitchesAndVariables"
```

- [ ] **Step 2: Verify**

Force a full recompile. Confirm no load errors on boot. In-game, toggle a switch or check a variable's effect if easily accessible (e.g. via the F9 debug menu's variable/switch viewer), otherwise a normal boot + overworld movement is sufficient since switches/variables are pervasively used.

- [ ] **Step 3: Commit**

```bash
git add -A
git commit -m "Rename Scripts/004_Game classes to 004_GameClasses (and its Switches and Variables subfolder)"
```

---

## Task 6: Rename `006_Map renderer`

**Files:**
- Move: `Scripts/006_Map renderer/` → `Scripts/006_MapRenderer/`

**Interfaces:**
- Consumes: `Scripts/` folder from Task 2.
- Produces: `Scripts/006_MapRenderer/`.

- [ ] **Step 1: Rename**

```bash
git mv "Scripts/006_Map renderer" "Scripts/006_MapRenderer"
```

- [ ] **Step 2: Verify**

Force a full recompile. Confirm no load errors on boot. Load into an overworld map and confirm tiles/autotiles render correctly, walk to trigger a map transition.

- [ ] **Step 3: Commit**

```bash
git add -A
git commit -m "Rename Scripts/006_Map renderer to 006_MapRenderer"
```

---

## Task 7: Rename `007_Objects and windows`

**Files:**
- Move: `Scripts/007_Objects and windows/` → `Scripts/007_ObjectsAndWindows/`

**Interfaces:**
- Consumes: `Scripts/` folder from Task 2.
- Produces: `Scripts/007_ObjectsAndWindows/`.

- [ ] **Step 1: Rename**

```bash
git mv "Scripts/007_Objects and windows" "Scripts/007_ObjectsAndWindows"
```

- [ ] **Step 2: Verify**

Force a full recompile. Confirm no load errors on boot. Open the main menu and any submenu (Bag, Pokédex) — this folder holds core UI window primitives used everywhere.

- [ ] **Step 3: Commit**

```bash
git add -A
git commit -m "Rename Scripts/007_Objects and windows to 007_ObjectsAndWindows"
```

---

## Task 8: Rename subfolders of `011_Battle`

**Files:**
- Move: `Scripts/011_Battle/006_AI MoveEffects/` → `Scripts/011_Battle/006_AI_MoveEffects/`
- Move: `Scripts/011_Battle/007_Other battle code/` → `Scripts/011_Battle/007_OtherBattleCode/`
- Move: `Scripts/011_Battle/008_Other battle types/` → `Scripts/011_Battle/008_OtherBattleTypes/`

**Interfaces:**
- Consumes: `Scripts/` folder from Task 2.
- Produces: renamed subfolders under `Scripts/011_Battle/` (the `011_Battle` folder itself keeps its name).

- [ ] **Step 1: Rename all three**

```bash
git mv "Scripts/011_Battle/006_AI MoveEffects" "Scripts/011_Battle/006_AI_MoveEffects"
git mv "Scripts/011_Battle/007_Other battle code" "Scripts/011_Battle/007_OtherBattleCode"
git mv "Scripts/011_Battle/008_Other battle types" "Scripts/011_Battle/008_OtherBattleTypes"
```

- [ ] **Step 2: Verify**

Force a full recompile. Confirm no load errors on boot. Start a wild battle, use a move that triggers AI on the opposing side (any standard trainer/wild battle exercises AI), win or flee, confirm no errors.

- [ ] **Step 3: Commit**

```bash
git add -A
git commit -m "Rename Scripts/011_Battle subfolders (AI MoveEffects, Other battle code/types)"
```

---

## Task 9: Rename subfolders of `012_Overworld`

**Files:**
- Move: `Scripts/012_Overworld/001_Overworld visuals/` → `Scripts/012_Overworld/001_OverworldVisuals/`
- Move: `Scripts/012_Overworld/002_Battle triggering/` → `Scripts/012_Overworld/002_BattleTriggering/`

**Interfaces:**
- Consumes: `Scripts/` folder from Task 2.
- Produces: renamed subfolders under `Scripts/012_Overworld/` (the `012_Overworld` folder itself keeps its name).

- [ ] **Step 1: Rename both**

```bash
git mv "Scripts/012_Overworld/001_Overworld visuals" "Scripts/012_Overworld/001_OverworldVisuals"
git mv "Scripts/012_Overworld/002_Battle triggering" "Scripts/012_Overworld/002_BattleTriggering"
```

- [ ] **Step 2: Verify**

Force a full recompile. Confirm no load errors on boot. Walk into tall grass (or any wild-encounter-enabled tile) to confirm battle triggering still works, confirm overworld visual effects (e.g. weather, reflections if the current map has them) still render.

- [ ] **Step 3: Commit**

```bash
git add -A
git commit -m "Rename Scripts/012_Overworld subfolders (Overworld visuals, Battle triggering)"
```

---

## Task 10: Rename `015_Trainers and player`

**Files:**
- Move: `Scripts/015_Trainers and player/` → `Scripts/015_TrainersAndPlayer/`

**Interfaces:**
- Consumes: `Scripts/` folder from Task 2.
- Produces: `Scripts/015_TrainersAndPlayer/`.

- [ ] **Step 1: Rename**

```bash
git mv "Scripts/015_Trainers and player" "Scripts/015_TrainersAndPlayer"
```

- [ ] **Step 2: Verify**

Force a full recompile. Confirm no load errors on boot. Open the player's trainer card / summary if accessible, start a trainer battle if convenient, otherwise a normal boot + party menu check is sufficient.

- [ ] **Step 3: Commit**

```bash
git add -A
git commit -m "Rename Scripts/015_Trainers and player to 015_TrainersAndPlayer"
```

---

## Task 11: Rename subfolder of `016_UI`

**Files:**
- Move: `Scripts/016_UI/001_Non-interactive UI/` → `Scripts/016_UI/001_NonInteractiveUI/`

**Interfaces:**
- Consumes: `Scripts/` folder from Task 2.
- Produces: renamed subfolder under `Scripts/016_UI/` (the `016_UI` folder itself keeps its name).

- [ ] **Step 1: Rename**

```bash
git mv "Scripts/016_UI/001_Non-interactive UI" "Scripts/016_UI/001_NonInteractiveUI"
```

- [ ] **Step 2: Verify**

Force a full recompile. Confirm no load errors on boot. Open the Bag, Pokédex, and Summary screens (the highest-traffic UI screens under `016_UI`).

- [ ] **Step 3: Commit**

```bash
git add -A
git commit -m "Rename Scripts/016_UI subfolder Non-interactive UI to NonInteractiveUI"
```

---

## Task 12: Rename `018_Alternate battle modes` and its subfolders

**Files:**
- Move: `Scripts/018_Alternate battle modes/` → `Scripts/018_AlternateBattleModes/`
- Move: `Scripts/018_AlternateBattleModes/001_Battle Frontier/` → `Scripts/018_AlternateBattleModes/001_BattleFrontier/`
- Move: `Scripts/018_AlternateBattleModes/002_Battle Frontier rules/` → `Scripts/018_AlternateBattleModes/002_BattleFrontierRules/`
- Move: `Scripts/018_AlternateBattleModes/003_Battle Frontier generator/` → `Scripts/018_AlternateBattleModes/003_BattleFrontierGenerator/`

**Interfaces:**
- Consumes: `Scripts/` folder from Task 2.
- Produces: `Scripts/018_AlternateBattleModes/` with all three subfolders renamed.

- [ ] **Step 1: Rename the parent, then all three children**

```bash
git mv "Scripts/018_Alternate battle modes" "Scripts/018_AlternateBattleModes"
git mv "Scripts/018_AlternateBattleModes/001_Battle Frontier" "Scripts/018_AlternateBattleModes/001_BattleFrontier"
git mv "Scripts/018_AlternateBattleModes/002_Battle Frontier rules" "Scripts/018_AlternateBattleModes/002_BattleFrontierRules"
git mv "Scripts/018_AlternateBattleModes/003_Battle Frontier generator" "Scripts/018_AlternateBattleModes/003_BattleFrontierGenerator"
```

- [ ] **Step 2: Verify**

Force a full recompile. Confirm no load errors on boot. If a Battle Frontier facility is reachable from the debug menu or a nearby save, enter it and start one battle; otherwise, a clean full recompile with no load errors is the practical verification here, since Battle Frontier content is usually gated behind significant progress.

- [ ] **Step 3: Commit**

```bash
git add -A
git commit -m "Rename Scripts/018_Alternate battle modes and its Battle Frontier subfolders"
```

---

## Task 13: Rename subfolders of `020_Debug`

**Files:**
- Move: `Scripts/020_Debug/001_Editor screens/` → `Scripts/020_Debug/001_EditorScreens/`
- Move: `Scripts/020_Debug/002_Animation editor/` → `Scripts/020_Debug/002_AnimationEditor/`

**Interfaces:**
- Consumes: `Scripts/` folder from Task 2.
- Produces: renamed subfolders under `Scripts/020_Debug/` (the `020_Debug` folder itself keeps its name).

- [ ] **Step 1: Rename both**

```bash
git mv "Scripts/020_Debug/001_Editor screens" "Scripts/020_Debug/001_EditorScreens"
git mv "Scripts/020_Debug/002_Animation editor" "Scripts/020_Debug/002_AnimationEditor"
```

- [ ] **Step 2: Verify**

Force a full recompile. Confirm no load errors on boot. Press F9 in-map to open the debug menu, open one editor screen (e.g. the map editor or an item/species data editor) and the animation editor, confirm both open without error.

- [ ] **Step 3: Commit**

```bash
git add -A
git commit -m "Rename Scripts/020_Debug subfolders (Editor screens, Animation editor)"
```

---

## Self-Review Notes

- **Spec coverage:** Phase 1 → Task 1. Phase 2 → Task 2. Phase 3's 11 folder renames → Tasks 3-13, one per top-level-folder batch, matching the spec's explicit "commit each batch separately" instruction. Phase 4 intentionally excluded (see plan intro) — needs its own plan once exact PBS/text renames are chosen with the user.
- **Placeholder scan:** no TBD/TODO steps; every step has literal commands or literal code. The one item the spec left open (Phase 4 naming) is excluded from this plan entirely rather than stubbed in.
- **Type consistency:** n/a (no functions/APIs defined across tasks) — cross-task consistency here means "the path each task's Step 1 renames FROM matches exactly what the previous task's Step 1 renamed TO," which was checked against the spec's table and Task 2's relocation.
- **Ordering fix applied:** original draft had Task 1 moving `scripts_extract.rb`/`scripts_combine.rb` before Task 2 edited them. Fixed by splitting Task 1's file list (excludes those two) and adding them as the final step of Task 2, after their content edits are verified.
