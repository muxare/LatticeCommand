# ADR-0011: Incidents are hand-authored and original, pass a five-step pipeline, and are signed off by a person who has studied for the certification

| | |
| --- | --- |
| **Status** | Accepted, amended by [ADR-0022](0022-claude-config-guards-worktrees-and-fails-closed.md) |
| **Date** | 2026-11-04 |
| **Deciders** | Mikael Axelsson |
| **Sources** | `lattice-command-gdd.md` ("Pipeline", "Incident schema", "Out of scope for 1.0", "Risks", "Open questions", "Daily workflow", "Dogfooding", "Bridge to the exam"); `CLAUDE.md` ("Content and fact accuracy", "Architecture") |
| **Related** | [ADR-0001](0001-record-architecture-decisions.md), [ADR-0007](0007-no-live-claude-api-in-play.md), [ADR-0009](0009-content-as-validated-json.md), [ADR-0010](0010-fact-sheet-single-source.md), [ADR-0012](0012-content-mapping-is-the-contract.md), [ADR-0016](0016-claude-code-config-as-worked-example.md), [ADR-0022](0022-claude-config-guards-worktrees-and-fails-closed.md) |

## Context

An incident is the unit in which the game teaches, so an incorrect one teaches a wrong exam answer with all the authority of a game rule. An incident that copies a real exam item is a different failure, and one that accuracy checks would not catch. At the same time the game needs at least 60 incidents from a team of two or three, which makes machine generation attractive. The project needs to say how much of the work a machine may do and who is accountable for the result.

## Decision

Incidents are hand-authored for accuracy, and procedurally generated incidents are out of scope for 1.0. Every incident must be original and must not reproduce real exam items. AI may draft an incident but must not approve one: a person who has studied for the certification signs off.

Each incident must pass five steps in order before it ships. In the first, a designer or the content-writer subagent drafts it from a scenario brief, using the interview pattern to establish the scenario, the correct fix and the tempting wrong fixes; the GDD also wants scenarios to come from real moments in this repository. In the second, the schema check runs through the PostToolUse hook. In the third, the fact-checker subagent compares each referenced claim with its source. In the fourth, the balance-check skill plays the incident with each order under fixed seeds and confirms that only the correct order resolves it at the causal layer. [ADR-0022](0022-claude-config-guards-worktrees-and-fails-closed.md) amends this step, because an incident's solution may be one order or a set of orders needed together, and the check plays each solution, each part of a set and each wrong order, and fails unless the solutions, and nothing else, resolve it. In the fifth, the person approves it.

Several things stay open. The licensing boundary is the GDD's open question 4: whether after-action reports can mirror the exam's format closely without reproducing real items. It is not settled here, and until it is, the only rule is the one above. The sources also name no reviewer, and the incident schema has no field recording an approval, so where a sign-off is recorded is undefined. The War College reframes seen incidents "with fresh numbers and names" and echoes return "with the scenario changed"; the sources do not say whether these variants are authored and reviewed in advance or produced at runtime, and the second would conflict with this decision. Whoever designs those features must settle that with a person first.

## Alternatives considered

**Procedurally generated incidents.** The GDD excludes these from 1.0 and gives the reason: "hand-authored only, for accuracy". The fact sheet and the simulation can verify a claim or an outcome, but not whether a generated scenario teaches the distinction it is meant to teach.

**Adapting real exam items.** This would be the fastest route to exam-like content, and the rule against reproducing real items excludes it. How close is too close is the open licensing question.

**AI drafts with automated checks and no human approval**, considered while writing this ADR. The validator, fact-checker and balance-check cover structure, claims and outcomes, and together they would remove the review bottleneck. They cannot judge whether a wrong order is truly tempting or whether a scenario is too close to a real item, and those judgements are why the project requires a person.

## Consequences

Each shipped incident has a known path and an accountable person, and the content-writer subagent can raise drafting speed without changing who answers for accuracy.

The cost is a bottleneck: 30 incidents for Alpha and 60 or more for Beta must each wait for a reviewer with the right background, which the GDD already lists as a risk. The pipeline also cannot yet run end to end. The validator, the hook, the fact sheet and the seeded runner do not exist, so the ten paper-prototype incidents cannot pass through it and must do so before any of them ships.

The existing definitions do not fully match the pipeline either. The `add-incident` skill's interview does not ask for the fact ids or the concept, while the content-writer stops when a brief lacks them. The skill also goes from draft to fact-check to "awaiting human approval" without running balance-check. And balance-check plays each incident "once per order", which does not cover incidents that need two concurrent orders. These are defects to correct when that tooling is built; this ADR does not change them. [ADR-0022](0022-claude-config-guards-worktrees-and-fails-closed.md) amends this, because it corrected all three defects on 2026-11-07, ahead of the tooling, so that Milestone 0's first incidents do not pass through skills known to skip steps.

## Staying on track

| Check | Enforced by | State |
| --- | --- | --- |
| Sessions in `content/**` are told that incidents are original, and the content-writer is also told that a draft needs human approval | `.claude/rules/content.md` and `.claude/agents/content-writer.md`, which instruct but do not enforce | Active |
| A draft comes from a structured brief and is reported as awaiting approval | `add-incident` skill and `content-writer` subagent | Pending (needs `content/facts.json` and an interview that collects fact ids and the concept). [ADR-0022](0022-claude-config-guards-worktrees-and-fails-closed.md) amends this, because the interview now collects the concept, the Concord trap, each wrong order's delayed consequence and the fact ids, so the check waits only for `content/facts.json`. |
| Step 2: the schema check runs on every content edit | PostToolUse hook on `content/**` | Pending (needs the content validator) |
| Step 3: referenced claims match their sources | `fact-check` skill and `fact-checker` subagent | Pending (needs `content/facts.json`) |
| Step 4: only the correct order resolves the incident at the causal layer | `balance-check` skill, which, as of 2026-11-04, stops by its own instruction | Pending (needs the seeded simulation runner and handling for two-order incidents). [ADR-0022](0022-claude-config-guards-worktrees-and-fails-closed.md) amends this check, because the skill now handles orders needed together and fails a solution that does not resolve, so it waits for the runner and a schema field recording orders needed together. |
| Step 5: a qualified person approved the incident | Pull request review by that person | Manual |
| The incident does not reproduce a real exam item | The same person, since nothing automated compares against exam items | Manual |
| No code generates incidents in 1.0 | Pull request review | Manual |

**Drift signals.** An incident merges with no named person approving it. Many incidents are approved in one sitting, with no comments. An incident has no balance-check result behind it once the runner exists. Code under `sim/` or `ui/` assembles scenarios from templates. War College or echo text exists that no reviewer has seen. A wrong order resolves an incident at the causal layer. An incident's scenario closely follows a practice-test question.

**Revisit when.** The licensing question is answered, review capacity blocks the 30-incident Alpha target, the War College and echo designs require variants at runtime, or scope after 1.0 reopens generated content.
