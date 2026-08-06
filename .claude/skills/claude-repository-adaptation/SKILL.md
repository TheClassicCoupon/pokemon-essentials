---
name: claude-repository-adaptation
description: Use when adding, updating, splitting, retiring, or auditing anything in this repo's .claude/ configuration (skills, hookify rules, CLAUDE.md) — including when a skill/hook's claims turn out stale or wrong (renamed file, moved method, restructured folder), after any rename/move/restructure in this session, when a task hit repeated fix-loops or the same mistake twice, or when the user explicitly asks to audit or fix Claude's setup for this repo.
---

# Claude Repository Adaptation and Maintenance

## Overview
This repo's `.claude/` configuration (`.claude/skills/`, gitignored `.claude/hookify.*.local.md` rules, `CLAUDE.md`) is small, repo-specific, and expected to keep changing as the codebase keeps restructuring (three folder-rename passes have already landed in recent history). This skill governs *that configuration* — what to add, when to trust an existing skill/hook's claims, and how to keep the set from rotting or sprawling. It is the scoped-down, repo-local counterpart to `superpowers:writing-skills` and `hookify:writing-rules` — apply their frontmatter/format/SDO conventions without their adversarial pressure-testing machinery, since these are technique/reference notes for one repo, not public discipline-enforcing skills distributed to strangers.

## Where Things Live and Why
- Skills: `.claude/skills/<name>/SKILL.md`, committed to the repo — not `~/.claude/skills/` (invisible to a fresh clone) and not folded into `CLAUDE.md` (which is always-loaded; skills load on demand, keeping default context small).
- Hookify rules: `.claude/hookify.{name}.local.md`. The `.local.md` suffix is real — `.gitignore` excludes `.claude/*.local.md`, so these are personal automation, not something a fresh clone gets. The hookify plugin itself is enabled repo-wide via `.claude/settings.json`. If a rule should be guaranteed for every contributor rather than personal convenience, that's a signal it may belong in `settings.json`'s `hooks` block instead — flag that distinction rather than assuming.
- Shared reference: `.claude/skills/_shared/refactoring-model.md` — the audit/refactor operating model used by `source-code-audit-and-refactoring` and `build-system-audit-and-refactoring`. Update it once, not per-skill.
- `CLAUDE.md` — repo overview, folder table, running/verifying basics. Broad, always-loaded, kept short; detailed procedure belongs in a skill instead.

## Deciding Where New Guidance Belongs

| The guidance is... | Put it in |
|---|---|
| A mechanical, always-true trigger tied to a file pattern or command ("editing PBS/*.txt → check X", "never edit Data/Scripts.rxdata") | A hookify rule — fires without the agent having to remember or judge |
| A judgment call, technique, or reference that only applies to specific tasks | A skill — hookify rules should *point at* the skill, not restate its content |
| Short, always relevant, rarely changes, applies regardless of what's being touched | CLAUDE.md |
| Shared by 2+ refactor-type skills | `_shared/refactoring-model.md`, referenced by name from each |
| One-off / specific to a single past mistake, unlikely to recur | Nothing |

## Adding or Updating a Skill or Hook
1. Confirm it's non-obvious and would recur (per `superpowers:writing-skills`'s "when to create") — not a one-off.
2. Skills: standard shape — YAML frontmatter (`name`, `description` starting with "Use when..." stating triggers only, never a workflow summary — a summarized description causes agents to act on the summary instead of reading the body), then Overview / patterns / quick-reference table / common mistakes. Cross-reference other skills by plain name in prose, not `@file` links (force-loads context) or `[[wiki-links]]` (that's the memory system's syntax).
3. Hooks: confirm it's mechanical and pattern-matchable (a file path, a command substring, a stop-time checklist) — if it needs judgment, it's a skill, not a hook. Check `hookify:writing-rules` for current frontmatter/operator syntax rather than copying an existing rule blind. If it dispatches to a skill, keep the message body short: what was touched, which skill to invoke, one line on why — don't duplicate the skill's content, the two will drift.
4. **Verify before writing anything down**: any file path, method name, or line number about to be asserted must be confirmed against the current repo (Grep/Glob/Read) — never recalled from a prior conversation or assumed from a filename.
5. Test immediately: for a hook, touch a matching file or run a matching command and confirm it fires (rules are read dynamically, no restart needed). For a skill, a lightweight check is enough — dispatch a subagent with only the new/changed SKILL.md plus a realistic task and confirm it retrieves and applies the guidance correctly; that's this repo's right-sized testing tier, not the full pressure-scenario battery `superpowers:writing-skills` uses for public discipline skills.

## Level 1 — Routine Adaptation (default, ambient)
After a normal task that changed repo files, revealed durable repo knowledge, or exposed friction, run a low-cost check reusing the current task's context/diff — don't do a repo-wide scan for this. Apply only narrow, high-confidence fixes: a stale path, an outdated command, a hookify pattern that no longer matches. Skip this check when nothing durable changed or a broader audit already just ran.

**Self-triggering conditions — don't wait to be asked:**
- **This session renamed, moved, or restructured** something a skill or hookify rule references by name (a folder path, filename, trigger glob). Grep `.claude/skills/*/SKILL.md` and `.claude/hookify.*.local.md` for the old name/path immediately, before considering the rename done — not at a later cleanup pass. A hookify rule's `regex_match` trigger is highest priority to check: a rule whose pattern no longer matches anything doesn't error, it silently stops firing, which is worse than no rule because nothing signals its absence.
- **A task this session hit repeated fix-loops, the same mistake twice, or an error that a skill/hook/CLAUDE.md's text didn't predict.** Don't file that under "bad luck" by default — the first hypothesis should be that a skill, hookify rule, or CLAUDE.md encodes a stale or incomplete assumption, and the friction is that assumption surfacing. Check skills, hooks, and CLAUDE.md together (they're maintained as a set — an assumption baked into one often has a sibling in another, e.g. a hookify rule pointing at a skill whose trigger condition is also wrong), not just whichever one was directly involved. Fix what's found in place, the same as any audit.
- **Test infrastructure prerequisites now exist** (a test project/framework/directory got added) — see "Deferred: Test-Code Audit and Refactoring" below; that's the trigger to create the skill, not before.

## Level 2 — Repository Evolution Audit
Run a broader audit when repo evolution materially changes what needs documenting: major restructuring, a new/removed subsystem, changed load order, a new plugin/tool/workflow, changed testing status, or a large cross-component change. Use architectural significance and workflow impact, not line count, to decide this is warranted.

Audit each `.claude/` resource for: accuracy, activation/suppression quality (false positives and negatives), missing capability, stale assumption, conflict/duplication with another resource, correct context ownership (is this in the skill/hook/CLAUDE.md that should own it?). Route a Level 2 audit through `pokemon-essentials-orchestration` to divide it by repo area (one subagent per numbered `Scripts/` region or per skill file) and reconcile centrally — don't read the entire configuration and the entire touched repo area into one pass if it can be split.

## Level 3 — Capability Failure Recovery
If the user explicitly asks to audit Claude's skills/hooks/CLAUDE.md/behavior for this repo, that request is itself evidence that Level 1/2 adaptation already failed somewhere — treat it as a systemic-failure investigation, not routine maintenance. Determine: why stale knowledge wasn't caught automatically; whether a skill/hook should have been created/updated/invoked and wasn't; whether activation/suppression rules were wrong; whether `pokemon-essentials-orchestration` routed the task incorrectly; whether a prior adaptation pass was ineffective; whether conflicting guidance blocked a correction. Then do an exhaustive pass: read every skill and hook file in full, verify every path/method/table claim against the current repo (Grep/Glob, not memory), check hookify regex patterns against real files, check for overlap/duplication, and fix what's found rather than only reporting it.

## Adaptation Efficiency and Loop Prevention
- Reuse current task context/diff; avoid full repository scans for Level 1.
- Don't create a skill or hook for one-time or trivial work.
- This skill's own edits (fixing a stale path, adding a rule) do not themselves trigger another adaptation pass — only materially new evidence (a fresh rename, fresh friction) restarts the cycle.
- Consolidate related updates into one pass rather than one commit-sized edit per finding.
- Stop when guidance is accurate and no capability gap remains — the goal is staying current, not continual rewriting.

## Deferred: Test-Code Audit and Refactoring
Not created — this repo has no test framework, test directory, or automated test command (confirmed: no `spec/`/`test/` tree, no CI). Creating a speculative test skill would document conventions that don't exist. See `references/test-infrastructure-plan.md` for the staged prerequisite plan (framework recommendation, initial test targets, readiness criteria). When those prerequisites land, that's a Level 1 self-trigger to inspect the implemented conventions and create the real skill — don't wait to be asked.

## Current Skill/Hook Inventory (verify before trusting — snapshot, not generated)

| Resource | Purpose |
|---|---|
| `pokemon-essentials-orchestration` | Task routing across repo-local skills |
| `source-code-audit-and-refactoring` | `Scripts/**/*.rb` audit/refactor |
| `build-system-audit-and-refactoring` | Compile pipeline, plugin load, versioning, no-CI |
| `pbs-data-validation` | `PBS/*.txt` format/field validation |
| `verifying-essentials-changes` | Manual in-`Game.exe` verification |
| `claude-repository-adaptation` | This skill |
| `hookify.pbs-edit-validation` (file, `PBS/*.txt`) | Dispatch to `pbs-data-validation` |
| `hookify.rgss-script-edit` (file, `Scripts/*.rb`) | Dispatch to `source-code-audit-and-refactoring` |
| `hookify.skill-maintenance` (file, `.claude/skills/**/*.md`) | Dispatch to this skill |
| `hookify.hook-maintenance` (file, `.claude/hookify.*.local.md`) | Dispatch to this skill |
| `hookify.block-rxdata-edit` (file, block, `Data/Scripts.rxdata`) | Hard-block direct edits to the gitignored binary |
| `hookify.verify-before-claiming-done` (stop) | Reminder to verify in `Game.exe` before claiming done |
| `hookify.skill-hook-friction-check` (stop) | Reminder to audit on repeated friction |

## Common Mistakes
- Writing a skill for a hookify-able mechanical rule instead of an actual hook.
- Duplicating a target skill's guidance into a hook message body instead of a short pointer — creates two places that can go stale independently.
- Trusting a path/method claim in an existing skill without grepping to confirm it still holds, especially right after a restructuring pass.
- Running a Level 2/3 audit for something a Level 1 targeted fix would have covered — check the trigger conditions above before escalating.
- Forgetting hookify rules are gitignored — don't assume a rule that works locally is visible to a fresh clone.
