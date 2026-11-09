# ADR-0024: The slice measures fun by voluntary play, bought asset sources stay out of the public repository, and the nightly job keeps one issue for facts due for re-approval

| | |
| --- | --- |
| **Status** | Accepted |
| **Date** | 2026-11-09 |
| **Deciders** | Mikael Axelsson |
| **Sources** | The open points of [ADR-0023](0023-owner-decisions-on-the-open-register.md); GDD "Design pillars", "Art pipeline", "CI with Claude Code", "Content pipeline and fact accuracy" and "Scope and milestones"; `CLAUDE.md` "Art pipeline" |
| **Related** | Amends [ADR-0023](0023-owner-decisions-on-the-open-register.md); touches [ADR-0014](0014-scripted-blender-art-pipeline.md), [ADR-0018](0018-vertical-slice-gate-and-scope.md) and [ADR-0021](0021-ci-on-github-actions.md) |

## Context

ADR-0023 settled the findings register of 2026-11-04 but left three points to the owner that are not deferred to Alpha. The first is what measures fun: the GDD's first pillar says the game must stand as a strategy game for people who never plan to certify, yet the slice's exit test checks only onboarding, learning and the web build, so the go/no-go gate could pass a good tutorial that nobody would play by choice. The second is where hand-made and bought assets are stored, which matters more since ADR-0023 kept the repository public, because most asset store licences forbid redistributing the source files. The third is whether the nightly fact-check flags entries that are due for re-approval; a passing check changes nothing in `content/facts.json`, so without a signal a stale entry goes unnoticed until the release test, which requires every fact to be verified within 30 days of launch. On 2026-11-09 the main session put a recommendation for each point to Mikael Axelsson, who approved all three.

## Decision

**The slice's exit test measures fun by voluntary play.** The playtest includes testers who do not plan to take the certification. Once a tester has fixed the first crisis, the person running the session tells them they may stop whenever they like, and the playtest record notes how many minutes each tester keeps playing after that point and their answer to a short "would you play this again?" question. The fun measure passes when a majority of the testers who do not plan to certify keep playing for at least ten minutes after being told they may stop. This measures what testers do rather than only what they say, because people rate a game generously in front of the person who made it.

**Source files of hand-made and bought assets are kept outside the public repository.** They live in private storage, such as a private drive folder or a private repository, and the repository holds only the exported `.glb` an asset ships as, and only when that asset's licence permits redistribution in a public repository. Each line of `art/third-party.md` gains the storage location of the asset's source file beside its file, author or vendor, source, licence and date added. An asset whose licence forbids public redistribution of even the export cannot ship from this repository until a build step that fetches it from private storage exists, and that step would need its own decision.

**The nightly job keeps one rolling issue for facts due for re-approval.** When an entry's `verified` date is older than 30 days and the `fact-checker` finds its source still supports the claim, the job adds the entry to a single open issue titled "Facts due for re-approval", which it rewrites each night as a checklist of the entries still due, and closes when the list is empty. A contradicted claim still opens its own issue, as ADR-0023 decided. The job still never edits `verified`; a person re-approves an entry by updating it, and the entry then leaves the checklist on the next run.

## Alternatives considered

**A survey alone.** It is cheap, but testers are generous when the maker is in the room, and a rating says little about whether anyone would choose to keep playing.

**An observer's judgement against a checklist.** It is subjective and hard to compare between sessions or observers.

**Leaving fun unmeasured.** The gate would test teaching only, and the GDD's first pillar would have no check before Alpha.

**Committing every asset to the repository, with or without Git LFS.** It keeps the project self-contained, but it publishes bought source files that most licences forbid sharing, and plain git would also bloat the history with large binaries for good.

**One issue per entry due for re-approval.** Each could be assigned and closed alone, but every 30 days the whole fact sheet would produce a burst of issues.

**No issue for entries due for re-approval.** Re-approval would rely on someone remembering, and stale entries would surface only at the release test.

## Consequences

The slice's gate now tests all three things the GDD calls risky: whether the incidents teach, whether the onboarding can be finished, and whether people play by choice. The cost is recruiting testers without exam plans, and the slice may fail on fun when it passes on teaching, which is the point of measuring it. The slice ends soon after its onboarding, so ten minutes of voluntary play may not be possible for a tester who fixes the first crisis late; the playtest record should note when a tester runs out of content rather than stopping by choice.

The public repository stays within asset licences, at the cost of a second storage place that a fresh clone does not include, so a contributor needs access to the private store to rebuild an asset from its source.

Stale facts become visible each night without noise, at the cost of one more job step that rewrites an issue body through `gh`.

The palette colours for the Admiralty, Night Relay and Assay Works stay deferred to Alpha, and the validator's runtime is still chosen when the validator is built, as ADR-0023 decided.

**On acceptance.** In the same change, the GDD and `CLAUDE.md` were corrected, ADR-0023 took the status "Accepted, amended by ADR-0024" with a pointer beside each passage this ADR settles, and the ADR index was updated.

## Staying on track

| Check | Enforced by | State |
| --- | --- | --- |
| The slice's playtest record includes testers without exam plans, their minutes of voluntary play after being told they may stop, and their answer on playing again | Milestone 1 playtest record | Pending (needs the vertical slice) |
| No source file of a hand-made or bought asset is committed, and every committed export's licence permits public redistribution | Pull request review | Manual |
| Every line of `art/third-party.md` names the storage location of the asset's source | Pull request review | Manual |
| The nightly job keeps one rolling issue for entries due for re-approval and never edits `verified` | Scheduled workflow | Pending (needs the workflow, see ADR-0021) |

**Drift signals.** A playtest counts only testers who are studying for the exam, or reports the survey answer without the minutes played. A `.blend` file or a purchased pack appears in a commit. A manifest line has no storage location. The nightly job opens one issue per stale entry, or a stale entry sits in the checklist for weeks.

**Revisit when.** The slice's content is too short for ten minutes of voluntary play to mean anything, an asset the game needs cannot be redistributed publicly in any form, or the rolling issue proves too quiet to prompt re-approval.
