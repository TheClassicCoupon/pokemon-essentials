---
name: pbs-data-validation
description: Use when editing any file under PBS/ (pokemon.txt, moves.txt, abilities.txt, items.txt, encounters.txt, metadata.txt, trainers.txt, etc.) or when a compile error references FileLineData, a section header, or a field name. Covers PBS text-format rules, how the compiler validates each field, and how to catch mistakes before booting the game.
---

# PBS Data Validation

## Overview
`PBS/*.txt` are the human-editable source of truth for game data; `Scripts/021_Compiler/002_Compiler_CompilePBS.rb` parses them into binary `Data/*.dat`, loaded into `GameData::*` classes at runtime (see the rgss-essentials-scripting skill). Never hand-edit `Data/*.dat` — it's regenerated from PBS on next boot whenever a PBS file's mtime is newer, and any manual edit there is silently discarded.

These files are large (`pokemon.txt` ~23k lines, `moves.txt` ~8.7k, `items.txt` ~6.5k) and have no schema validation outside the compiler itself — a bad line fails loudly at boot, not at save time.

## PBS Text Format Rules
- Sections are `[SomeSectionName]` (species internal name, move ID, etc.) — every file must open with a section header; a bare field line before any `[...]` raises "Expected a section at the beginning of the file."
- Fields are `FieldName = value` — one per line, no bare `key=value` without the section context.
- Must be saved as **UTF-8**. A wrong-encoding save produces the same "Expected a section" error as a missing header, which is misleading — if that error appears on a file you just edited in a non-UTF-8-aware editor, check encoding first.
- Multi-value fields are comma-separated; quoted strings follow standard quoting — an unterminated/malformed quote raises "Invalid quoted field."
- Enum-valued fields (types, egg groups, flags) must match a known enum value exactly (case-sensitive) — an unrecognized value raises "Undefined value X in Y" or "Incorrect value X in Y", naming the enum.

## What the Compiler Validates Per Field
`Scripts/021_Compiler/001_Compiler.rb` has typed field coercers (`csvInt!`, `csvPosInt!`, `csvFloat!`, `csvBoolean!`, `csvEnumField!`, etc. — all bang-suffixed) that each PBS schema field is declared against. Validation failures always append `FileLineData.linereport` to the error — this gives you the exact file and line number, so the fastest triage is: read the error, jump to that line, check the field's declared type in the relevant schema. Most schemas are a `SCHEMA` constant in the class's file under `Scripts/010_Data/002_PBS data/` (e.g. `004_Ability.rb`, `006_Item.rb`) — but `GameData::Species` (`008_Species.rb`, backing `pokemon.txt`, the biggest and most-edited PBS file) has no `SCHEMA` constant; its fields are built by a `self.schema(compiling_forms = false)` method instead, with a different field set depending on whether it's compiling a base species section or a form section. Search for `schema` (not `SCHEMA`) if grepping that file comes up empty.

| Symptom | Likely cause |
|---|---|
| "Expected a section at the beginning of the file" | Missing `[Header]`, or file not saved as UTF-8 |
| "Bad line syntax (expected syntax like XXX=YYY)" | Line isn't `Field = value` form (stray text, bad line ending) |
| "Field 'X' is not a positive integer" / "not a number" / "not a Boolean value" | Wrong type for that field — check the schema |
| "Undefined value X in Y" / "Incorrect value X in Y" | Enum field has a typo or removed/renamed value |
| "Field 'X' must contain only letters, digits, and underscores..." | An internal-name field (species/move/item ID) has invalid characters or starts with a digit |

## Verifying a PBS Edit
1. Save the file as UTF-8 with no encoding change to surrounding lines (diff it if unsure).
2. Boot `Game.exe` in debug mode — PBS files newer than compiled `Data/*.dat` auto-recompile. For a change that doesn't seem to take effect, force a full recompile: hold Ctrl at boot, or from the map (not in battle — the battle debug menu has no compile option), F9 → "Files options..." → "Compile data" ("Fully compile all data").
3. A compile failure blocks boot entirely and reports file + line via `FileLineData.linereport` — fix and reboot, there's no partial-load fallback.
4. To confirm the compiled data matches intent, the compiler's inverse (`003_Compiler_WritePBS.rb`) is what in-game data editors (F9) use to write PBS back out — editing a record via the F9 editor and diffing the resulting PBS line against what you wrote by hand is a good way to catch subtle format mismatches (field order, quoting) that don't error but silently produce wrong values.

## Common Mistakes
- Editing `Data/*.dat` directly — always discarded on next boot, edit the PBS `.txt` instead.
- Copy-pasting a block between species/moves/items and forgetting to update the `[InternalName]` header — causes a silent duplicate-key overwrite rather than a compile error: `GameData::ClassMethodsSymbols#register` (`Scripts/010_Data/001_GameData.rb`) keys `DATA` by `hash[:id]` alone, so the later section with the same internal name silently replaces the earlier one.
- Assuming a compile error's line number is the only problem — `pbCompilerEachPreppedLine` reports the first failure per file; fix and recompile rather than trying to pre-scan the whole file by eye for a 23k-line file like `pokemon.txt`.
- Not saving as UTF-8 after editing in an editor that defaults to a different encoding — produces a misleading "missing section header" error instead of an encoding error.
