---
name: verifying-essentials-changes
description: Use before claiming any change to this Pokemon Essentials repo works, is fixed, or is complete — there is no automated test suite, so "done" means launched and exercised in Game.exe. Also use when a change produces no visible error but you're unsure it took effect, or when triaging a boot failure or exception.
---

# Verifying Essentials Changes

## Overview
This repo has no test suite and no CI (see CLAUDE.md). "Verification" is not optional or skippable — it means launching `Game.exe` (mkxp-z) in debug mode and exercising the actual menu/battle/map flow the change touches. Static review (reading the diff, checking it "looks right") is not verification here; RGSS/mkxp-z errors are frequently silent-at-parse, loud-at-runtime.

## Verification Checklist
1. **Recompile if PBS or map data changed.** Debug-mode boot auto-recompiles PBS files newer than `Data/*.dat`, but if you're unsure it picked up the change, force it: hold Ctrl at boot, or from the map (not in battle — the battle debug menu has no compile option) F9 → "Files options..." → "Compile data". See the pbs-data-validation skill for PBS-specific failure modes.
2. **Boot and reach the actual feature.** A script-only change to, say, battle AI needs an actual battle triggered, not just a clean boot. Don't report success from "the game launched" alone.
3. **Exercise the golden path, then at least one edge case** — the case that's most likely to break (empty party, fainted Pokemon, item at max stack, evolution mid-battle, etc. depending on what changed).
4. **Watch for exceptions.** RGSS runtime errors show a message box and write to `errorlog.txt` in the game's working directory — check it if a change silently no-ops or the game exits unexpectedly, not just when an error dialog appears.
5. **If `rubocop` is installed**, run it against changed files for style consistency with `.rubocop.yml` (Ruby 3.0 target, naming cops disabled — see the rgss-essentials-scripting skill). This catches style drift, not correctness — it is not a substitute for steps 1-4.

## Reporting Results
State plainly what was and wasn't exercised — e.g. "Booted, triggered a wild battle, confirmed the new AI branch fires when the AI's HP < 20%; did not test double battles." Don't say a change "works" or "is fixed" based only on reading the code or a clean compile — those confirm the code parses, not that it behaves correctly. If you can't launch the game in the current environment, say so explicitly instead of asserting success.

## Common Mistakes
- Treating a successful PBS recompile (no compile error) as proof the new data is *correct*, rather than merely well-formed — reachable-but-wrong values (e.g. a move's effect ID pointing at the wrong handler) don't raise compile errors.
- Reporting "fixed" after only reading `errorlog.txt` was empty on a run that never actually reached the changed code path.
- Skipping the edge case because the golden path worked — RGSS silently swallowing exceptions in some UI draw loops means broken edge cases can look fine until a specific save state hits them.
