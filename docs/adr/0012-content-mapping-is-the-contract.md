# ADR-0012: The GDD's content mapping tables are the contract between game systems and certification concepts, and the share of systems and incidents per domain follows the exam weights

| | |
| --- | --- |
| **Status** | Accepted, amended by [ADR-0022](0022-claude-config-guards-worktrees-and-fails-closed.md) |
| **Date** | 2026-11-04 |
| **Deciders** | Mikael Axelsson |
| **Sources** | `lattice-command-gdd.md` ("Learning design", "Setting and fiction", "Content mapping", "Rival faction: the Hollow Concord", "Coverage targets", "Open questions"); `CLAUDE.md` ("Teaching rules that constrain the code") |
| **Related** | [ADR-0001](0001-record-architecture-decisions.md), [ADR-0008](0008-simulation-fidelity.md), [ADR-0009](0009-content-as-validated-json.md), [ADR-0011](0011-hand-authored-incidents-human-signoff.md), [ADR-0013](0013-teach-through-play.md), [ADR-0018](0018-vertical-slice-gate-and-scope.md), [ADR-0022](0022-claude-config-guards-worktrees-and-fails-closed.md) |

## Context

The game's promise is that playing it covers the certification, in roughly the proportions the exam tests. That promise can erode without any single bad decision: a system that is fun to build grows, a domain that is easy to write incidents for fills up, and a domain that is hard to dramatize thins out. Without a stated contract, nobody could say whether a new system belongs in the game, and nobody could show that coverage had slipped.

## Decision

The tables in the GDD's "Content mapping" section are the contract. Each game system must map to a certification concept and, in the five domain tables, to the Concord trap it trains against. A system or incident that changes this mapping must be recorded in the table, as `CLAUDE.md` requires of any correction to the GDD.

The share of game systems and incidents per domain follows the exam weights: D1 27%, D2 18%, D3 20%, D4 20% and D5 15%. At launch the game has at least 60 incidents, about 16 for D1, 11 for D2, 12 each for D3 and D4, and 9 for D5. Every one of the ten Concord doctrines (Plea, Mirror, Latewatch, Envoy, Liar, Tower, Brute, Scroll, Hand and Silencer) appears at least four times, and roughly one incident in eight needs two orders. Each doctrine is a distractor pattern, and every wrong order in an incident must be tagged with one of them. These numbers are launch targets; the sources set no distribution for the smaller incident counts at earlier milestones.

The incident targets are arithmetically sound. The counts total 60, the weights total 100, and each count is within 0.4 percentage points of its weight. One in eight of 60 is 7.5 incidents, which fits the exam's "about 12%" select-two rate of 7.2. The doctrine floor is coherent but barely binding: 60 incidents with three or four wrong orders give 180 to 240 tags, of which the floor claims 40, so one doctrine could sit at four while others take far more. The sources also do not say whether "appears" counts tags or incidents.

The systems target does not hold as of 2026-11-04. The domain tables have 8, 7, 8, 6 and 6 rows out of 35, which is 22.9%, 20%, 22.9%, 17.1% and 17.1%, against the 9.45, 6.3, 7, 7 and 5.25 rows the weights would give. D1 and D4 are short, and D2, D3 and D5 are over. The sources do not say that a table row is the unit of "system", and the five supporting-course rows belong to no domain. The GDD also uses a third measure in one place, saying the weights set "how much play time each domain gets". Under [ADR-0001](0001-record-architecture-decisions.md) this is a defect to resolve, by either correcting the tables or redefining the target; this ADR does not choose.

Two open questions remain outside this decision: the audience, which changes pacing and the War College's weight, and which practice test benchmarks learning and who owns that study. In addition, the exam structure is "distilled from two 60-question practice tests and the CCA-F question decoder in this project", and none of those files is in the repository, so the weights have no checkable source here.

## Alternatives considered

**An equal share per domain**, considered while writing this ADR. It would be simpler to plan and would simplify balancing, but it would over-train the lightest domain and under-train the heaviest, which contradicts the GDD's aim that D1 forms the campaign's backbone.

**Letting fun decide the distribution**, considered while writing this ADR. The pillar "fun without the exam" argues for this, and it would free the design. It lost because the game's purpose is transfer to an exam with known weights, and weights do not stop a system from being fun; they only decide how much of each there is.

**Measuring by play time alone**, considered while writing this ADR. The GDD's phrasing suggests it, and it is closest to what a player experiences. It cannot be checked against files in `content/` and requires telemetry that does not exist, so it cannot replace the share of systems and incidents as the checked measure.

## Consequences

Coverage becomes something that can be counted, a proposed system has an obvious first question, and the five research branches line up with the domains. A reviewer can reject a feature for having no row.

The contract constrains design, because a good idea with no concept behind it has no home outside the supporting-courses table. The targets inherit the exam's structure, so a change in the official exam guide means rework. The GDD itself anticipates that the guide may differ, since it makes the Assay Works colony conditional on the guide listing that scenario. Its own numbers disagree there too: "4–5 recurring scenarios", five colony types plus one optional, and "all six colony types" at Beta. "About" also leaves the permitted tolerance undefined, so whoever builds the coverage check must get one decided. The trap column is uneven as well: Latewatch, Liar and Silencer are attached to only two systems each, so four appearances means reusing those systems or using these doctrines elsewhere.

## Staying on track

| Check | Enforced by | State |
| --- | --- | --- |
| Incident share per domain matches the weights at launch | Coverage report from the validator over `content/` | Pending (needs incident files, the validator and a decided tolerance) |
| Each doctrine appears at least four times, and about one incident in eight needs two orders | The same coverage report | Pending (needs incident files, the validator and a definition of "appears") |
| Each incident's domain and doctrine tags are valid values | JSON Schema for incidents | Pending (needs the schema and the validator) |
| A new or changed game system has its row in the mapping tables | Pull request review | Manual |
| System share per domain follows the weights, which it does not on 2026-11-04 | Review of the GDD tables against the weights | Manual |
| A system's behaviour matches the concept in its row | `sim-reviewer` subagent on changes under `sim/`, then human review. [ADR-0022](0022-claude-config-guards-worktrees-and-fails-closed.md) amends this, because `sim-reviewer` now accepts a modelled Claude behaviour only when a fact id in `content/facts.json` backs it, and reports any other as unverified rather than passing it. | Manual |

**Drift signals.** The domain share in the content folder drifts from the weights, for example D3 climbing well above 20% because the dogfooding rule makes repository incidents easy to write. A doctrine stays near its floor while Plea and Brute fill most wrong-order tags. Two-order incidents move well away from seven or eight in 60. A feature ships with no row in the tables, or a row has no system at Beta. A table row changes and no incident referencing that system is reviewed.

**Revisit when.** The official exam guide gives different weights, scenarios or task statements, the audience question is answered in a way that changes the game's emphasis, or the learning measurement shows that matching the weights does not raise practice-test scores.
