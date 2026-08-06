---
name: maintaining-project-skills
description: Use when the user asks to add, update, split, retire, or audit a skill in this repo's .claude/skills/ directory, when a repo skill's claims turn out stale or wrong (renamed file, moved method, restructured folder), after a repo-restructuring change large enough that existing skills might reference paths that no longer exist, or — without waiting to be asked — when a task hit repeated fix-loops, the same class of mistake more than once, or an error that didn't match what a skill/hook/CLAUDE.md said should happen: that friction is itself a signal to audit, not just a one-off execution slip.
---

# Maintaining Project Skills

## Overview
This repo's skill set (`.claude/skills/`) is small, repo-specific, and expected to keep changing as the codebase gets restructured toward something more maintainable. This skill governs *this* skill set specifically: what to add, when to trust an existing skill's claims, and how to keep the set from rotting or sprawling. It is the scoped-down, repo-local counterpart to `superpowers:writing-skills` — that skill's RED-GREEN-REFACTOR/pressure-testing process is built for public discipline-enforcing skills distributed to strangers; skills here are technique/reference notes for one codebase read by one team, so apply its structural conventions (frontmatter, SDO description, quick-reference tables) without its adversarial subagent testing machinery.

## Where Skills Live and Why
Skills live at `.claude/skills/<name>/SKILL.md`, committed to the repo — not `~/.claude/skills/` (user-level, invisible to teammates/future clones) and not folded into `CLAUDE.md` (CLAUDE.md is always-loaded context; skills load on demand, keeping the default context small). See `.claude/settings.json` for which plugins are enabled at the project level alongside these.

## Deciding Where New Guidance Belongs

| The guidance is... | Put it in |
|---|---|
| A mechanical, always-true constraint ("never edit Data/*.dat by hand") | A hookify rule (`PreToolUse` block), not a skill — skills are for judgment calls, hooks are for enforceable ones |
| Short, always relevant, rarely changes | CLAUDE.md |
| A judgment call, technique, or reference that only applies to specific tasks | A skill here |
| One-off / specific to a single past bug | Nothing — don't create a skill for something that won't recur |

## Adding or Updating a Skill
1. Confirm the guidance is non-obvious and would recur across tasks (per `superpowers:writing-skills`'s "when to create" criteria) — not a one-off.
2. Follow the standard SKILL.md shape: YAML frontmatter (`name`, `description` starting with "Use when..." and stating triggers only, never a workflow summary — see `superpowers:writing-skills` for why summarized descriptions cause agents to skip the body), then Overview / patterns / quick-reference table / common mistakes.
3. Cross-reference other project skills by plain name in prose ("see the pbs-data-validation skill") — not `@file` links (force-loads context) and not `[[wiki-links]]` (that's the memory system's syntax, not skill cross-referencing).
4. Verify before writing anything down: any file path, method name, or line number you're about to assert in a skill must be confirmed against the current repo (Grep/Read), not recalled from a prior conversation or assumed from the file's name.
5. Run one lightweight check before considering it done: dispatch a subagent with only the new/changed SKILL.md plus a realistic task, and confirm it retrieves and applies the guidance correctly. This is the "Technique/Reference" testing tier from `superpowers:writing-skills`, not the full pressure-scenario battery — reserve the heavier process for a skill that's actually meant to stop the *user's* behavior under pressure (rare in a single-person repo).

## Handling Repo Restructuring
When a change touches file/folder layout broadly (not just content within a file):
1. Grep across `.claude/skills/*/SKILL.md` for path fragments likely to have moved (folder number prefixes like `010_Data`, `021_Compiler`; specific filenames named in tables).
2. For each hit, re-verify the path still resolves. A memory or skill claim about a repo path is a claim about *when it was written* — treat a mismatch as the skill being stale, not the repo being wrong.
3. Update the skill in place rather than leaving a note — stale path references in a reference skill are worse than no skill, because they're trusted by default.

## Handling Repeated Friction (Not Just File Changes)
A rename or a moved file is the *easy* case to catch — it's mechanical, greppable, and the "Handling Repo Restructuring" section above covers it. The harder, more important case is friction that isn't obviously about a path at all: a task took more fix-loop rounds than it should have, a subagent got stuck on the same class of mistake twice, the user corrected you more than once about the same thing, or something happened that the relevant skill/hook/CLAUDE.md text simply didn't predict. Don't file that under "bad luck" or "the subagent was careless" by default — the first hypothesis should be that a skill, a hookify rule, or CLAUDE.md is encoding an assumption that's stale, incomplete, or was never quite right, and the friction is that assumption surfacing.

This repo is expected to keep restructuring substantially over its life — the methodology documented today is not expected to survive unchanged. Treat that as a standing reason to re-check documented assumptions readily, not as a reason to wait for things to settle before bothering.

When you notice this kind of friction, without waiting to be asked:
1. Ask what specifically went wrong and whether any skill, hookify rule, or CLAUDE.md section asserted (implicitly or explicitly) that it wouldn't happen, or gave guidance that turned out incomplete.
2. Check all three together — skills, hooks (see `maintaining-project-hooks`), and CLAUDE.md — not just whichever one you were touching when the friction happened. They're maintained as a set in practice, and an assumption baked into one often has a sibling in another (a hookify rule pointing at a skill whose trigger condition is also wrong, for instance).
3. Fix what you find in place, the same as any other audit — don't just leave a note for later.
4. If nothing in the docs actually predicted or caused the friction (it really was a one-off execution mistake), that's a valid conclusion too — but reach it by checking, not by assuming.

## Retiring or Merging Skills
- Two skills covering overlapping triggers is a sign to merge, not to keep both "just in case" — an agent picking between near-duplicate descriptions is a coin flip, not a design.
- If a skill's entire subject no longer exists in the repo (feature removed, area rewritten from scratch), delete the skill folder rather than marking it deprecated in place — a skill that's still discoverable but wrong is more dangerous than a missing skill.

## Common Mistakes
- Writing a skill for a hookify-able mechanical rule instead of an actual hook — skills are advisory (an agent can still misjudge when they apply), hooks are enforced.
- Padding a description with what the skill *does* rather than *when to use it* — makes future-agent triggering worse, not better (per `superpowers:writing-skills`' SDO guidance).
- Trusting a path/method claim in an existing skill without grepping to confirm it still holds, especially after any restructuring pass.
