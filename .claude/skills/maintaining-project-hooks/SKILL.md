---
name: maintaining-project-hooks
description: Use when the user asks to add, update, disable, retire, or audit a hookify rule in this repo's .claude/ directory (hookify.*.local.md files), when a rule's trigger fires on the wrong files or stops firing after a restructure, or when deciding whether a piece of guidance belongs in a hook versus a skill.
---

# Maintaining Project Hooks

## Overview
This repo enforces a handful of mechanical, always-true rules via the **hookify** plugin rather than relying on an agent to remember them. Rules live as `.claude/hookify.{name}.local.md` files and fire on file edits, bash commands, prompt submission, or session stop. This skill governs *this* rule set specifically: when a hookify rule is the right tool, how to write one that matches this repo's conventions, and how to keep rules from drifting out of sync with the code they watch. For rule *syntax* (frontmatter fields, operators, event types), defer to the `hookify:writing-rules` skill — this skill covers repo-specific judgment, that one covers mechanics.

## Where Hooks Live and Why
Rules live at `.claude/hookify.{name}.local.md`. The `.local.md` suffix is real: `.gitignore` excludes `.claude/*.local.md` (see the "Local (personal) hookify rules" entry), so these are personal/local automation, not something teammates get on clone. The hookify plugin itself is enabled repo-wide via `.claude/settings.json` (`"hookify@claude-plugins-official": true`), but the individual rule files are not tracked. If a rule should be guaranteed for every contributor rather than personal convenience, that's a signal it may belong as an actual Claude Code hook in `settings.json`'s `hooks` block instead of a hookify rule — flag that distinction to the user rather than assuming.

## Deciding: Hook, Skill, or CLAUDE.md?

| The guidance is... | Put it in |
|---|---|
| A mechanical, always-true trigger tied to a file pattern or command ("editing PBS/*.txt → check X", "never edit Data/Scripts.rxdata") | A hookify rule — fires without the agent having to remember or judge |
| A judgment call, technique, or reference that only applies to specific tasks | A skill (see `maintaining-project-skills`) — hookify rules should *point at* the skill, not restate its content |
| Short, always relevant, rarely changes, applies regardless of what file is being touched | CLAUDE.md |
| One-off / specific to a single past mistake that's unlikely to recur | Nothing |

The established pattern in this repo is a **pairing**: a hookify rule with `event: file` and a narrow `regex_match` on `file_path`, whose entire message body is "you're touching X, invoke skill Y for the how" — not restating the skill's content. See `hookify.pbs-edit-validation.local.md` → `pbs-data-validation`, `hookify.rgss-script-edit.local.md` → `rgss-essentials-scripting`, and `hookify.skill-maintenance.local.md` → `maintaining-project-skills` for the shape to copy. `hookify.verify-before-claiming-done.local.md` (`event: stop`) and `hookify.block-rxdata-edit.local.md` (`action: block`) are the two rules that don't follow this pairing — they enforce process/prevent an action directly rather than dispatching to a skill.

## Adding or Updating a Rule
1. Confirm it's mechanical and pattern-matchable (a file path, a command substring, a stop-time checklist) — if it needs judgment about *whether* it applies, it's a skill, not a hook.
2. Check `hookify:writing-rules` for current frontmatter/operator syntax rather than copying an existing rule blind — syntax is that skill's source of truth, not this one.
3. Pick the narrowest `regex_match` that captures the intended files — verify the pattern against real paths in this repo (Grep for the folder) rather than assuming a path still exists.
4. If the rule should dispatch to a skill, keep the message body short: what was touched, which skill to invoke, one line on why it matters. Don't duplicate the skill's content into the hook message — the two will drift.
5. Name the file `hookify.{kebab-name}.local.md`, matching the `name:` field in frontmatter.
6. Test immediately: touch a matching file (or run a matching command) and confirm the rule fires as expected — rules are read dynamically, no restart needed.

## Current Rules (quick reference)

| Rule | Event | Trigger | Purpose |
|---|---|---|---|
| `pbs-edit-validation` | file | `PBS/*.txt` | Dispatch to `pbs-data-validation` skill |
| `rgss-script-edit` | file | `Scripts/*.rb` | Dispatch to `rgss-essentials-scripting` skill |
| `skill-maintenance` | file | `.claude/skills/*.md` | Dispatch to `maintaining-project-skills` skill |
| `hook-maintenance` | file | `.claude/hookify.*.local.md` | Dispatch to this skill |
| `block-rxdata-edit` | file (block) | `Data/Scripts.rxdata` | Hard-block direct edits to the gitignored binary |
| `verify-before-claiming-done` | stop | always | Reminder to launch `Game.exe` before claiming a fix works |

Re-verify this table against the actual files in `.claude/` when auditing — it's a snapshot, not generated, and will drift if a rule is added, renamed, or removed without updating it here.

## Handling Repo Restructuring
When a change moves or renames the files a rule's `regex_match` targets:
1. Grep `.claude/hookify.*.local.md` for path fragments that reference the moved area (folder prefixes, filenames).
2. Re-verify each hit's pattern still matches real paths — a rule that silently stops firing is worse than a missing rule, because nobody notices its absence.
3. Update the pattern in place.

## Common Mistakes
- Writing a hookify rule for something that needs judgment (an agent still has to decide *how* to apply it) — that belongs in a skill, with the hook (if any) just pointing at it.
- Duplicating a target skill's guidance into the hook message body instead of a short pointer — creates two places that can go stale independently.
- Forgetting rules are gitignored (`.claude/*.local.md`) — don't assume a rule that works locally is visible to a fresh clone or another contributor.
- Writing an overly broad `regex_match` (e.g. matching on a bare folder name with no extension) that fires on unrelated files.
