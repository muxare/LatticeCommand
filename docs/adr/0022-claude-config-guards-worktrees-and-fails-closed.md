# ADR-0022: The generated-file hook guards every checkout and fails closed, and the incident and review tooling is corrected ahead of the tools it waits for

| | |
| --- | --- |
| **Status** | Accepted |
| **Date** | 2026-11-07 |
| **Deciders** | Mikael Axelsson |
| **Sources** | GDD "Building it with Claude Code", "Pipeline" and "Risks"; `CLAUDE.md` "Claude Code setup" and "Teaching rules"; [findings](findings-2026-11-04.md) T7, T8 and T9; the hooks documentation at https://code.claude.com/docs/en/hooks and the worktrees documentation at https://code.claude.com/docs/en/worktrees, read on 2026-11-07 |
| **Related** | Amends [ADR-0002](0002-godot-4-as-engine.md), [ADR-0003](0003-typed-gdscript.md), [ADR-0008](0008-simulation-fidelity.md), [ADR-0011](0011-hand-authored-incidents-human-signoff.md), [ADR-0012](0012-content-mapping-is-the-contract.md), [ADR-0014](0014-scripted-blender-art-pipeline.md) and [ADR-0016](0016-claude-code-config-as-worked-example.md); see also [ADR-0010](0010-fact-sheet-single-source.md) |

## Context

The findings register recorded three defects in `.claude/`. The generated-file hook judged paths against `$CLAUDE_PROJECT_DIR`, which stays at the starting root after Claude enters a worktree, so generated files inside a worktree were not protected, and the hook allowed any edit whose path it could not read (T7). The `add-incident` skill did not collect what `content-writer` stops without and skipped the balance check, and `balance-check` neither failed a correct order that did not resolve nor handled orders needed together (T8). Two path-scoped rules lacked lines the project relies on, and `sim-reviewer` was asked to check real Claude behaviour with no source to check it against (T9).

ADR-0011 said its defects would be corrected when the tooling is built. Milestone 0 will start writing incidents before that tooling exists, so the skills they pass through need to say the right thing now, including what they cannot yet do.

## Decision

**Worktree sessions are expected and must be guarded.** The hook must judge a path from the root of the checkout holding the file, which is the nearest ancestor containing a `.git` entry, and `.claude/worktrees/<name>/` also counts as a root. It must resolve relative paths against the input's `cwd`, and resolve `..` and symlinks before judging, including when the end of the path does not exist yet. `.godot/`, `build/` and `art/models/` match only at a root, and `*.import` matches anywhere inside a checkout. Files outside any checkout are allowed. Matching ignores case, because the default macOS filesystem does.

**The hook must fail closed.** It must deny when `jq` or `realpath` is missing, when its input cannot be parsed, and when the path is unusable. It denies by exit 2 with the reason on stderr, which the hooks documentation says routes the same way as a `deny` decision, so that a denial does not depend on `jq` working. The matcher stays `Edit|Write`: `NotebookEdit` carries `notebook_path` rather than `file_path`, so adding it would deny every notebook edit, and no generated path here holds notebooks. Bash stays uncovered, as ADR-0016 decided.

**A hook that fails must also deny.** The PreToolUse handler in `.claude/settings.json` sets `"onFailure": "block"`. The hooks documentation says that without it a command hook that cannot start, exits with a code other than 0 or 2, times out or prints invalid output lets the tool call through, and that with `"block"` each of those failures does what exit 2 does on that event, which on PreToolUse blocks the call. The field belongs on the handler object beside `type` and `command`, takes `"continue"` or `"block"`, and requires Claude Code v2.1.295 or later; v2.1.318 was installed on 2026-11-07. The script still ends every denial in exit 2 itself, so that Claude sees its reason rather than a failure notice.

**Worktrees stay out of the main checkout's status.** `.gitignore` lists `.claude/worktrees/`, as the worktrees documentation recommends, so that the files of a worktree Claude Code creates there do not appear as untracked files in the main checkout.

**`add-incident` must collect the full brief and report every pipeline step.** It must collect the concept, the Concord trap, each wrong order's delayed consequence and the fact ids, and must stop if a fact id has no entry in `content/facts.json`. It must then report validation, fact-check and balance-check each as passed, failed or not run. A step whose tool does not exist is not run, which is neither a pass nor a reason to leave it out.

**`balance-check` must test solutions, not single orders.** A solution is one correct order or a required set of orders. The check must play the control with no order, each solution, each smaller part of a required set, each wrong order alone, and each required set with one order swapped for a wrong one, over a horizon that passes every declared or scheduled consequence. It fails if a solution does not resolve the incident, if any other play does, or if a wrong order's declared consequence does not surface or does not trace back to that order. A pass is evidence for the human reviewer and not approval.

**`sim-reviewer` must check modelled behaviour against `content/facts.json`.** Only a fact id backs a behaviour, never its memory, `CLAUDE.md`, the GDD or the brief. A behaviour without a fact is reported as unverified and is not a pass. `sim.md` repeats the Godot 3 rule, and `scenes.md` carries the real-term rule.

**Fact entries are drafted, verified and approved by separate hands.** The main session drafts each entry in `content/facts.json` from the current official documentation, the `fact-checker` subagent verifies it against its `source`, and a person approves it. No agent writes an entry from memory. This applies [ADR-0010](0010-fact-sheet-single-source.md)'s rule that a claim is checked against the current documentation and never written from memory, and neither ADR-0010 nor ADR-0011 says who writes an entry, so neither is amended.

**Lucky seeds stay strict for now.** `balance-check` fails a wrong order whose declared consequence stays quiet under any seed, following ADR-0008's "must": a fix at the wrong layer must recur or be exploitable, and the log must trace it back. `CLAUDE.md` says distractors work "just often enough", so a seed on which a wrong order gets away with it is possible, and it is still reported as a failure. This rule is revisited when the seeded simulation runner fixes the number of seeds.

## Alternatives considered

**Keep using `$CLAUDE_PROJECT_DIR` and also strip a `.claude/worktrees/*/` prefix.** This is shorter, but a git worktree can sit outside the project directory, where the prefix never matches.

**Keep the `permissionDecision` JSON for denials.** It is the richer format and was what ADR-0016 described, but it needs `jq` to produce output, so a missing `jq` would need a second denial path anyway.

**Give `sim-reviewer` WebFetch.** The register offered this. It lost because it would make a second place where documentation is read and interpreted, whereas [ADR-0010](0010-fact-sheet-single-source.md) makes the fact sheet the single source, and a behaviour found to be missing there should produce a fact entry that lasts.

**Wait until the tooling is built, as ADR-0011 said.** That leaves Milestone 0's first incidents going through a skill known to skip steps silently.

## Consequences

Generated files are now protected in worktrees, and an edit is not let through because the hook could not judge it. The cost of failing closed is that a machine without `jq` or `realpath` cannot Edit or Write anything in the project until they are installed, and CI or a new contributor would meet this first.

A hook that cannot start, crashes or times out now denies the edit as well, because the handler sets `onFailure` to `block`. The cost is that a broken hook blocks every Edit and Write in the project until it is repaired, and that the field requires Claude Code v2.1.295 or later, so an older version gives no such protection.

Some things remain unguarded. A directory with no `.git` outside `.claude/worktrees/` counts as outside any checkout, a dangling symlink is judged by its own path, and a nested repository counts as its own root.

Two checks cannot pass yet, by design. `add-incident` stops before drafting until `content/facts.json` exists, and `sim-reviewer` reports every modelled behaviour as unverified until then. The main session now owns drafting a fact entry, and because `fact-checker` reads entries from `content/facts.json`, a draft has to be written there before it can be verified. How a person's approval of an entry is recorded, and which name goes in its `verifier` field when the subagent verifies and a person approves, are not decided, and ADR-0010 already leaves open whether a subagent can count as the `verifier`.

Several points stay open. The incident schema does not yet say how a file records alternatives or orders needed together, and only required sets have a source in the GDD and ADR-0008, so alternative correct orders may not be needed at all. The number of seeds, how a horizon is derived, and whether order within a tick may change the result are undefined until the runner exists. `tests/**` has no path-scoped rule and relies on `CLAUDE.md`. Trailing `dir/**` in rule `paths` is not confirmed by the documentation's pattern table and has not been seen to load.

**On acceptance.** Mikael Axelsson accepted this ADR on 2026-11-07, and in the same change the amended ADRs took the status "Accepted, amended by ADR-0022", each keeping its original sentence or check row with a one-sentence pointer beside it, as ADR-0001 requires and as ADR-0020 did for ADR-0005 and ADR-0006. The pointers sit beside ADR-0016's description of the script, its description of `add-incident`, its open points, its piped-JSON check, its "correct order alone" check and its worktree condition under "Revisit when"; the hook checks in ADR-0002 and ADR-0014; the check in ADR-0003 saying `sim.md` does not repeat the rule; the `sim-reviewer` checks in ADR-0008 and ADR-0012; and ADR-0011's step 4 in its Decision, its paragraph of defects and its checks for the brief and step 4. ADR-0016's description of `add-incident` and ADR-0011's step 4 in its Decision were not in the proposed list, and were given pointers because they state what this ADR replaced. The index, its statuses and its count of checks changed in the same change.

## Staying on track

| Check | Enforced by | State |
| --- | --- | --- |
| Edit and Write calls on generated paths are denied in the main checkout and in worktrees, unusable input is denied, and other paths pass | `deny-generated-edits.sh` through PreToolUse; verified on 2026-11-04 by a 74-case piped table, which is not kept in the repository, and by two live denials in a session (`build/` and `.claude/worktrees/probe/art/models/`); on 2026-11-07, after `onFailure` was set, an ordinary path piped in was allowed with exit 0 and an `art/models/` path was denied with exit 2. A hook that fails to start, crashes or times out has not been provoked in a live session | Active |
| `add-incident` reports each pipeline step as passed, failed or not run | The skill's own instructions, reviewed by the person approving the incident | Manual |
| `balance-check` fails a solution that does not resolve and any other play that does | `balance-check` skill | Pending (needs the seeded simulation runner and a schema field for orders needed together) |
| Modelled Claude behaviour in a `sim/` diff is backed by a fact id or reported as unverified | `sim-reviewer` subagent, invoked by hand | Manual |
| The PreToolUse handler keeps `"onFailure": "block"`, and `.claude/worktrees/` stays ignored | Pull request review of `.claude/settings.json` and `.gitignore`; on 2026-11-07 `jq` read `block` from the settings and `git check-ignore` matched a path under `.claude/worktrees/` | Manual |
| Each fact entry was drafted from the current official documentation, verified by `fact-checker` and approved by a person | Review by the person approving the entry | Pending (needs `content/facts.json`) |

**Drift signals.** The hook starts stripping `$CLAUDE_PROJECT_DIR` again, or gains an `exit 0` on a failed parse. The handler loses `onFailure`, or `.claude/worktrees/` leaves `.gitignore`. A fact entry arrives with no `fact-checker` result or no named person behind it. A report from `add-incident` omits a step instead of saying it was not run. A review from `sim-reviewer` passes a behaviour without citing a fact id.

**Revisit when.** The documentation changes hook input, exit-code or `onFailure` behaviour, a `WorktreeCreate` hook is added, the incident schema settles how required sets are recorded, or the seeded simulation runner fixes the number of seeds and the horizon, which is also when the strict rule for lucky seeds is revisited.
