# ADR-0023: The vertical slice trims its onboarding to one colony, exam weights apply to incidents, and the open content, fact-sheet and CI choices are settled

| | |
| --- | --- |
| **Status** | Accepted, amended by [ADR-0024](0024-fun-measure-asset-storage-and-re-approval-issue.md) |
| **Date** | 2026-11-09 |
| **Deciders** | Mikael Axelsson |
| **Sources** | [Findings register](findings-2026-11-04.md) items T2, T3, D1 to D3 and D5 to D12; the open points of [ADR-0022](0022-claude-config-guards-worktrees-and-fails-closed.md); GDD "Design pillars", "Content mapping", "The thin bridge", "Onboarding: the first two hours", "Art pipeline", "Content pipeline and fact accuracy" and "Scope and milestones"; `CLAUDE.md` "Project status", "Teaching rules" and "Art pipeline" |
| **Related** | Amends [ADR-0004](0004-compatibility-renderer-single-threaded-web.md), [ADR-0009](0009-content-as-validated-json.md), [ADR-0010](0010-fact-sheet-single-source.md), [ADR-0012](0012-content-mapping-is-the-contract.md), [ADR-0014](0014-scripted-blender-art-pipeline.md), [ADR-0018](0018-vertical-slice-gate-and-scope.md), [ADR-0021](0021-ci-on-github-actions.md) and [ADR-0022](0022-claude-config-guards-worktrees-and-fails-closed.md) |

## Context

The findings register of 2026-11-04 left a set of design choices to the owner, and ADR-0022 left four more. Most of them have no single correct answer, but each one blocks or shapes later work: the slice cannot be planned while its onboarding contains beats it does not build, the first fact entry cannot be written while nobody knows how approval is recorded, and the validator cannot be built while its implementation and its way of recognising a feature name are undecided. On 2026-11-07 the main session wrote a recommendation for each item, and Mikael Axelsson approved all of them in that session. This ADR records those decisions and the corrections they make to the GDD, `CLAUDE.md`, `.claude/` and earlier ADRs.

## Decision

### The vertical slice (D3, D5, D10)

**The slice trims its onboarding rather than widening its scope.** Widening it would mean building research, a second colony and after-action reports before the go/no-go point, which ADR-0018 forbids. The slice's onboarding must keep the beats at 0:00, 0:10, 0:25 and 0:40 and the escort beats at 1:10 and 1:30, run at the single Harbour colony. At 0:40 the interlock unlocks through a scripted event instead of research. The expansion at 0:55, the after-action report at 1:45 and the Concord's reveal at 2:00 are not in the slice. The full two-hour onboarding in the GDD stays the design for 1.0 and arrives at Alpha with the systems it needs. The slice's exit test becomes "five players finish the slice's onboarding unaided".

**The slice includes a browser smoke test.** The web build is the reason Godot was chosen ([ADR-0002](0002-godot-4-as-engine.md), [ADR-0004](0004-compatibility-renderer-single-threaded-web.md)), so the slice must show that its web export loads and plays the first crisis in at least one current desktop browser, named in the playtest record. The full web build, with its hosting and size work, stays at Beta.

**The slice's exit test measures learning as well.** It adds Milestone 0's measure: players name the right fix more often after playing than before. Fun is still not measured by any exit test, and that remains open. [ADR-0024](0024-fun-measure-asset-storage-and-re-approval-issue.md) adds a measure of voluntary play.

### Exam weights and after-action reports (D1, D2)

**The exam weights apply to incidents, not to systems or play time.** Systems follow the concepts the certification covers, and a domain's table may have more or fewer rows than its weight implies. The launch targets of about 16, 11, 12, 12 and 9 incidents stand. The GDD's phrase that the weights set "how much play time each domain gets" is replaced.

**An after-action report shows four options, selected from the incident's orders.** They are the correct answer and the three most tempting wrong orders, and an incident whose solution is a set of orders shows that set as one option. This rests on the GDD's statement that the exam uses four options, which comes from the practice tests (D12) and has no fact entry yet. It must be checked against the exam's documented format, including how "select TWO" questions are presented, before after-action reports are built at Alpha, and if the exam shows select-two questions differently this choice is revisited.

### Art (D6, D7)

**"Every shipped asset comes from a script" applies to hard-surface assets.** Advisor characters and creatures are modelled by hand or bought, and each such asset must be listed in `art/third-party.md` with its file, its author or vendor, its source, its licence and the date it was added. The manifest is created with the first such asset. Where those files are stored is not decided here. [ADR-0024](0024-fun-measure-asset-storage-and-re-approval-issue.md) keeps their source files outside the public repository.

**The colours for the Admiralty, Night Relay and Assay Works are deferred to Alpha**, because the slice has only the Harbour.

### Smaller GDD corrections (D8, D9, D12)

Beta's contents read "all five colony types, plus the Assay Works if it is built", because the Assay Works is optional. The War College section states that its time limit mirrors the exam and is not a speed reward, and that finishing early earns nothing. The practice tests and question decoder behind the exam targets stay outside the repository for now. Only the Alpha and Beta exit tests need them, and Milestone 0 uses its own before-and-after question set.

### The fact sheet (ADR-0022's open point, D11)

**`verifier` names the person who approved the entry, and `verified` is the date of that approval.** An entry is approved only after the `fact-checker` subagent has verified it against its `source`, and the commit that adds or re-approves the entry names that check. A subagent never counts as the `verifier`. This settles the point ADR-0010 left open and the one ADR-0022 left open. The recommendation approved in the session proposed a separate `approved` date, and it was folded into the existing `verified` field while this ADR was written, because both dates would record the same event.

**Each entry gains a `terms` field listing the feature names it backs.** The union of these lists is the glossary the validator uses to recognise a feature name in content, which ADR-0010 noted the entry fields could not supply.

**The content validator runs as a standard JSON Schema validator outside Godot**, plus a project script for the checks a schema cannot express, such as a glossary term in content without a fact id. Hand-writing a schema engine in GDScript was rejected. The runtime and library are chosen when the validator is built. On 2026-11-07 the machine had the system Python 3.9.6 without the `jsonschema` package and Node from Homebrew, so either choice adds a dependency to the hooks and CI.

### CI's nightly fact-check (T2, T3)

**The nightly job re-checks facts whose `verified` date is older than 30 days**, not all content, which keeps its cost bounded and matches the release test. **A source counts as changed when the `fact-checker` finds that the page no longer supports the claim**, not when the page's bytes change, because documentation pages are reworded often and a hash would raise false alarms. A contradicted claim opens an issue. [ADR-0024](0024-fun-measure-asset-storage-and-re-approval-issue.md) adds one rolling issue for entries due for re-approval. A passing check changes nothing in the file, because no agent approves an entry, so a person re-approves a stale entry by updating `verified` after reading the check.

**The repository stays public.** It has a GitHub remote, `github.com/muxare/LatticeCommand`, which Mikael created on 2026-11-07, and he chose to keep it public over the session's recommendation of a private repository. This settles ADR-0021's open point on visibility. The costs are that GitHub disables scheduled workflows in a public repository after 60 days without activity, that pull requests from forks need the workflows' secrets handled with care, and that every incident's exam-format rewrite is published as it is written, while the GDD's open question on licensing exam-style content is still unanswered.

### Incidents and tests (ADR-0022's other open points)

**An incident has exactly one solution: one correct order, or one set of orders needed together.** A single-order incident records a set of one, and alternative correct orders are not allowed, because no source asks for them. `balance-check` and `add-incident` are updated to match. The incident schema records the solution as one list of order ids, and widening it to alternatives later would need a superseding ADR.

**`tests/**` gets no path-scoped rule yet.** One is added when `tests/run.gd` exists and a convention appears that is worth enforcing.

## Alternatives considered

**Widening the slice to build research, a second colony and after-action reports.** It would keep the GDD's onboarding whole, but it builds strategy-layer systems before the gate and adds weeks to an eight-week slice.

**Stubbing the dropped beats with placeholder screens.** It keeps the onboarding's shape, but a stubbed expansion or report teaches nothing and still has to be designed, tested and later replaced.

**Making the weights apply to systems too.** The tables would have to be rebalanced by row, and the register showed that a row is not a stable unit of "system".

**A separate `approved` date beside `verified`.** It was the recommendation as approved, and it lost while this ADR was written because the two would always hold the same date.

**A private repository.** It was the recommendation, because of the open licensing question and the 60-day rule, and Mikael chose to keep the repository public.

**Hashing source pages to detect change.** Reworded or restyled pages would raise an issue every night, and the `fact-checker` has no store for the hashes.

**Allowing alternative correct orders.** It would cover incidents with two equally good fixes, but no source asks for them, the exam's single-answer format argues against them, and they complicate `balance-check`.

## Consequences

The slice is smaller and closer to its eight weeks, and its exit test now measures learning and the web build's basic viability. The cost is that the slice no longer tests the full onboarding, so the expansion, the first report and the reveal are first played at Alpha, where a problem with them is more expensive.

The first fact entry can be written, since its fields and its approval are now defined, and the validator has a clear shape. Both cost a dependency outside Godot, and every person who approves a fact, or re-approves a stale one, is now on the critical path for content.

The four-option report rests on a claim about the exam that has no fact entry yet, and the domain tables are no longer held to the weights, so a domain could end up thin in systems while meeting its incident count.

Several points stay open: what measures fun, where hand-made and bought assets are stored, the remaining three palette colours, whether the nightly job also opens an issue for an entry that is due for re-approval, and the runtime of the validator. [ADR-0024](0024-fun-measure-asset-storage-and-re-approval-issue.md) settles fun, asset storage and the re-approval issue.

**On acceptance.** In the same change, the GDD, `CLAUDE.md`, `.claude/rules/content.md`, `.claude/skills/add-incident` and `.claude/skills/balance-check` were corrected, the findings register recorded the outcome, and each amended ADR took the status "Accepted, amended by ADR-0023" with a one-sentence pointer beside the passage this ADR replaces.

## Staying on track

| Check | Enforced by | State |
| --- | --- | --- |
| The slice builds no research, second colony or after-action report | Review of plans and pull requests against this ADR and ADR-0018 | Manual |
| The slice's playtest records the onboarding result, the before-and-after measure and the browser smoke test with the browser named | Milestone 1 playtest record | Pending (needs the vertical slice) |
| Domain balance is judged by incident counts | Review of incident pull requests; a coverage count in the content validator | Manual; the count is Pending (needs the validator) |
| The four-option report rests on a verified fact about the exam's format | `content/facts.json` entry cited by the report's design | Pending (needs the fact entry, before Alpha) |
| Hand-made and bought assets are listed in `art/third-party.md` | Pull request review | Manual |
| Every fact entry names a person as `verifier` and lists its `terms` | Content schema | Pending (needs the schemas and validator) |
| Content naming a glossary term without the fact id fails | Content validator | Pending (needs the validator) |
| The nightly job checks only entries older than 30 days and opens an issue only for a contradicted claim | Scheduled workflow | Pending (needs the workflow, see ADR-0021) |
| The nightly workflow shows activity within 60 days, so the public repository's schedule is not disabled | Scheduled workflow history | Pending (needs the workflow) |
| An incident has one solution, recorded as one list of order ids | Incident schema; `balance-check` | Pending (needs the schema and the seeded simulation runner) |

**Drift signals.** A slice plan adds a research screen, a second colony or a report "just as a stub". A domain is called balanced because of its row count. A fact entry names a subagent as `verifier`, or a nightly job edits `verified` itself. An incident file lists two alternative correct answers. A bought model arrives without a manifest line.

**Revisit when.** The slice playtest shows the trimmed onboarding cannot be finished or teaches too little, the exam's documented format differs from four single-answer options, a real incident needs two alternative fixes, the nightly job's issues prove too noisy or too quiet, or the validator's runtime turns out to be unavailable in CI.
