# ADR-0016: The repository's Claude Code configuration follows the GDD and is kept as a worked example of Domain 3

| | |
| --- | --- |
| **Status** | Accepted, amended by [ADR-0022](0022-claude-config-guards-worktrees-and-fails-closed.md) |
| **Date** | 2026-11-04 |
| **Deciders** | Mikael Axelsson |
| **Sources** | `lattice-command-gdd.md` ("Building it with Claude Code", in particular "Repository layout", "Hooks", "Subagents", "Dogfooding"; "Domain 3: Claude Code configuration and workflows"); `CLAUDE.md` ("Claude Code setup") |
| **Related** | [ADR-0014](0014-scripted-blender-art-pipeline.md), [ADR-0015](0015-live-blender-mcp-exploration-only.md), [ADR-0017](0017-test-first-headless-verification.md), [ADR-0021](0021-ci-on-github-actions.md), [ADR-0022](0022-claude-config-guards-worktrees-and-fails-closed.md) |

## Context

Domain 3 of the certification covers `CLAUDE.md`, path-scoped rules, skills, hooks and permissions, the GDD maps subagents to Domain 1, and the game teaches all of these mechanisms. The GDD makes the team's own setup a worked example, so that building the game is practice for the content, and a hook that saves the team from a bad edit can become a Night Relay incident. That only works if the configuration is correct and truthful. The documentation says that Claude Code ignores unrecognised frontmatter fields without reporting an error, so a mistaken field would quietly do nothing while looking like a working example.

## Decision

The configuration under `.claude/` must follow the GDD's "Building it with Claude Code" section, and any frontmatter field, hook event name or settings key must be checked against the current documentation when it changes. A mechanism that depends on missing tooling must be added together with that tooling, and a placeholder must not stand in for it.

**What exists on 2026-11-04.** `.claude/settings.json` defines one hook: PreToolUse with the matcher `Edit|Write`, which runs `.claude/hooks/deny-generated-edits.sh` through `$CLAUDE_PROJECT_DIR`. The script reads `tool_input.file_path`, removes the project directory prefix and returns a `permissionDecision` of `deny` for `.godot/*`, `build/*`, `*.import` and `art/models/*`. [ADR-0022](0022-claude-config-guards-worktrees-and-fails-closed.md) amends this description, because the script now judges each path from the root of the checkout holding it and denies by exit 2 with the reason on stderr, including when it cannot judge the path. Four rules in `.claude/rules/` use `paths` frontmatter: `sim.md`, `content.md`, `scenes.md` and `art.md`. Three skills exist. `add-incident` interviews the user, delegates to `content-writer`, runs `fact-check` and reports the draft as awaiting human approval. [ADR-0022](0022-claude-config-guards-worktrees-and-fails-closed.md) amends this description, because the skill now collects the full brief, stops without fact entries, and reports validation, fact-check and balance-check each as passed, failed or not run. `fact-check` uses `context: fork` with `agent: fact-checker`. `balance-check` is written, but it tells Claude to stop if `CLAUDE.md` lists no seeded runner. Three subagents exist, each with a `tools` allowlist: `content-writer` (Read, Write, Grep), `sim-reviewer` (Read, Grep, Glob) and `fact-checker` (WebFetch, Read).

**What waits for tooling.** PostToolUse on `content/**` waits for the content validator. Stop waits for the headless test command and, as the GDD and `CLAUDE.md` specify, the content validator as well. `balance-check` cannot do its work until the seeded simulation runner exists. `.mcp.json` waits for live Blender mode, as [ADR-0015](0015-live-blender-mcp-exploration-only.md) records. The GDD's CI jobs wait for [ADR-0021](0021-ci-on-github-actions.md).

**Bash is deliberately not covered.** The PreToolUse hook must not be extended to Bash in a way that blocks regeneration, because Bash is how Blender and Godot rebuild generated files. The hook therefore prevents an agent from editing a generated file by accident through the file tools, and it does not claim to be a security boundary.

**Open points.** The script compares paths against `$CLAUDE_PROJECT_DIR`, which the documentation says stays at the starting project root after Claude enters a worktree. A piped path under `.claude/worktrees/x/art/models/` was consequently allowed, as was one under the same worktree's `.godot/`, and the sources do not say whether worktree sessions are expected or how they should be guarded. The script also relies on `jq`, which no source names as a requirement, and without a usable path it exits 0, which allows the edit. The matcher does not include `NotebookEdit`, which matters little for these paths but is not stated as intended. [ADR-0022](0022-claude-config-guards-worktrees-and-fails-closed.md) settles these points: worktree sessions are expected and guarded, the hook needs `jq` and `realpath` and denies without them or without a usable path, and leaving out `NotebookEdit` is intended.

## Alternatives considered

The sources state no rejected alternatives, so these were considered while writing this ADR. **Relying on instructions in `CLAUDE.md` alone to protect generated files** would be simpler, but the GDD's Domain 3 table names exactly that as a trap, the Plea, since prompts guide and hooks guarantee. **Extending the hook to Bash** would close the gap, but deciding from a shell string which command is a legitimate regeneration is fragile, and `CLAUDE.md` chooses to leave Bash open. **Adding the PostToolUse and Stop hooks now** would make the configuration look complete, but it would run commands that do not exist and teach the wrong lesson.

## Consequences

The configuration can be used as teaching material, and every gap in it is named. Real moments in the repository can feed incidents, as "Dogfooding" intends.

The costs are that the configuration must be rechecked as Claude Code changes, and that it duplicates what the GDD and `CLAUDE.md` describe. Leaving Bash open means that a shell command can overwrite a generated file without being stopped, so only review or a later CI check can catch that. The documentation also sets limits on what the planned hooks can promise. PostToolUse runs after the tool has finished and cannot prevent the action, and it does not fire for a file that Bash rewrites. Stop has no matcher support, as the GDD's hook table records, and an 8-consecutive-continuation cap means that Stop can delay "done" but cannot strictly guarantee it. A matcher tests only the tool name, so the planned `content/**` scope goes in the handler's `if` field, as the GDD specifies, and whether `Edit(/content/**)` also catches Write must be checked when the hook is added.

## Staying on track

| Check | Enforced by | State |
| --- | --- | --- |
| Edit and Write calls on `.godot/`, `build/`, `*.import` and `art/models/**` are denied, and other paths pass | `deny-generated-edits.sh` through PreToolUse; verified on 2026-11-04 by piping sample JSON into the script with `CLAUDE_PROJECT_DIR` set, not by provoking a denial in a live session. [ADR-0022](0022-claude-config-guards-worktrees-and-fails-closed.md) amends this check to cover worktrees and unusable input, and its own check records how that was verified. | Active |
| Frontmatter fields, hook event names and settings keys exist in the documentation | The person or agent changing them. Checked on 2026-11-04 against the hooks, subagents, skills, memory, settings and MCP pages at code.claude.com; no existing `.claude` file uses an unrecognised field | Manual |
| The hook's scope stays Edit and Write, and Bash remains available for regeneration | Pull request review of `.claude/settings.json` | Manual |
| Content edits run the validator and return errors to Claude | PostToolUse hook | Pending (needs the content validator) |
| "Done" is held back until headless tests and content validation pass | Stop hook | Pending (needs the headless test command that [ADR-0019](0019-test-framework.md) settles, and the content validator) |
| Each incident's correct order alone resolves it across fixed seeds. [ADR-0022](0022-claude-config-guards-worktrees-and-fails-closed.md) amends this check, because a solution may be one order or a set of orders needed together, and each solution, and no other play, must resolve the incident. | `balance-check` skill | Pending (needs the seeded simulation runner) |
| The Blender MCP server is shared through `.mcp.json` | The committed file | Pending (needs live Blender mode to be set up) |

**Drift signals.** `.claude/settings.json` gains a hook that calls a command that does not exist, or a command path that does not go through `$CLAUDE_PROJECT_DIR`. A rule loses its `paths`, or a skill or agent carries a field the documentation does not list. `sim-reviewer` or `fact-checker` gains a write tool. A generated file changes through a shell command with no change to its source. The content validator or test command lands while its hook is still absent, or `CLAUDE.md` still calls a tool missing after it has arrived. Personal preferences appear in the committed settings rather than in `.claude/settings.local.json`.

**Revisit when.** The documentation changes the behaviour of an event or field used here, the exam's Domain 3 content changes, the team starts working regularly in worktrees, or generated files are damaged through Bash often enough that leaving it open no longer holds up. [ADR-0022](0022-claude-config-guards-worktrees-and-fails-closed.md) amends this paragraph, because worktree sessions are now expected and guarded, so regular work in them no longer reopens this decision.
