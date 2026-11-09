# ADR-0010: Every technical claim lives in `content/facts.json`, and content references fact ids instead of carrying free text about features

| | |
| --- | --- |
| **Status** | Accepted, amended by [ADR-0023](0023-owner-decisions-on-the-open-register.md) |
| **Date** | 2026-11-04 |
| **Deciders** | Mikael Axelsson |
| **Sources** | `lattice-command-gdd.md` ("The fact sheet", "Freshness", "CI with Claude Code", "Subagents", "Scope and milestones", "Risks"); `CLAUDE.md` ("Content and fact accuracy") |
| **Related** | [ADR-0001](0001-record-architecture-decisions.md), [ADR-0007](0007-no-live-claude-api-in-play.md), [ADR-0008](0008-simulation-fidelity.md), [ADR-0009](0009-content-as-validated-json.md), [ADR-0011](0011-hand-authored-incidents-human-signoff.md), [ADR-0013](0013-teach-through-play.md), [ADR-0021](0021-ci-on-github-actions.md) |

## Context

The GDD states the problem directly: "a learning game that teaches a wrong fact is worse than no game", and Claude features change often. It rates stale facts as both likely and damaging. A game with 60 or more incidents, plus tooltips and after-action reports, would repeat the same claim about a feature many times. If each repeat were free text, a change in one feature would mean finding every sentence that mentions it, and no one could say when any of those sentences was last checked.

## Decision

`content/facts.json` is the one place that holds technical claims. Each entry must have an `id`, a one-sentence `claim`, a `source` URL in the official documentation, a `verified` date, a `verifier` and the `domains` it supports. [ADR-0023](0023-owner-decisions-on-the-open-register.md) adds a `terms` field and defines `verifier` as the person who approved the entry, never a subagent. A claim must be checked against the current documentation and must not be written from memory.

Incidents, tooltips and after-action reports must reference fact ids and must not carry free text about features. No feature name may appear in content without a fact-sheet entry, and the validator must fail the build if one does. When a feature changes, its entry changes once and every incident that references it is flagged for review.

A nightly job re-verifies facts older than 30 days and flags any whose source page changed. [ADR-0023](0023-owner-decisions-on-the-open-register.md) defines a changed source as one that no longer supports the claim. The War College shows a content version and a "last verified" date, and the release milestone requires content verified within 30 days of launch.

Several points are not settled by the sources and are not settled here. An incident's scenario and exam-format rewrite are prose, and the report must explain why wrong orders fail, so the line between naming a feature and making a claim about it will need a ruling when the first real incident is written. Recognising a feature name requires a list of names, and the entry fields do not include one. The sources do not say whether a subagent can count as the `verifier`. Tooltips must reference fact ids, but `CLAUDE.md` lists only incidents, doctrines, tech nodes and the fact sheet as content files, so where tooltip text lives, and whether the validator reaches it, is unstated.

## Alternatives considered

**A source link inside each incident**, considered while writing this ADR. It keeps the evidence next to the sentence and needs no lookup, but the same claim would be repeated and would age separately in each place, which defeats the GDD's requirement that a change touches the fact entry once.

**Verifying only before release**, considered while writing this ADR. The release milestone's 30-day requirement would be cheaper to meet alone, but the GDD assumes features change throughout a nine-month build, and a late sweep would find the errors after incidents had already been built and balanced on them.

## Consequences

A changed feature becomes one edit and a known list of incidents to review, and any sentence the player reads can be traced to a dated source. The fact sheet also doubles as a list of what the game claims, which reviewers can read on its own.

Writing an incident now costs more, because a feature with no entry must get a verified one first; the friction is deliberate. A single file will collect merge conflicts as it grows. The nightly job costs money and will raise false alarms when documentation is merely reworded.

The nightly job as specified is also harder than it reads. The fact-checker compares a claim with what the page says now and has only `WebFetch` and `Read`, so it can find a contradiction but cannot detect that a page changed unless something stores what the page said, which no entry field does. It cannot enumerate files or update `verified` either, so the surrounding job must do that. The GDD has a job step parse the JSON output and run `gh issue create`, and it records that how a changed source is detected is not yet defined. The GDD also gives two scopes for this job: "Freshness" says facts older than 30 days, and "CI with Claude Code" says all content. This ADR does not choose between them. Under [ADR-0001](0001-record-architecture-decisions.md) the disagreement remains a defect, and the owner's decision is tracked in [the findings register](findings-2026-11-04.md). Finally, the claims in the GDD and in `CLAUDE.md` themselves, such as the batch limit of 24 hours, have not yet been entered or verified, because the fact sheet does not exist.

## Staying on track

| Check | Enforced by | State |
| --- | --- | --- |
| Every entry has all seven fields, including `terms`, and an official-docs source | JSON Schema for the fact sheet, run by the validator in CI | Pending (needs the CI workflow, [ADR-0021](0021-ci-on-github-actions.md)) |
| Referenced fact ids resolve, and no feature name appears without one | Content validator `tools/validate_content.py`, which recognises a feature name by the glossary of fact `terms` ([ADR-0023](0023-owner-decisions-on-the-open-register.md)) | Active (PostToolUse and Stop hooks; CI pending [ADR-0021](0021-ci-on-github-actions.md)) |
| Claims in new or changed content match their sources | `fact-check` skill, forked into the `fact-checker` subagent, invoked by hand | Manual |
| Facts are re-verified nightly, at the scope the owner decides | Scheduled `claude -p` job in CI | Pending (needs the workflow from [ADR-0021](0021-ci-on-github-actions.md); [ADR-0023](0023-owner-decisions-on-the-open-register.md) set the scope) |
| Changing a fact flags each incident that references it | A tool that the sources do not yet specify | Pending (needs that tool to be defined and built) |
| Sessions working in `content/**` and the content-writer are told the fact-id rule | `.claude/rules/content.md` and `.claude/agents/content-writer.md`, which instruct but do not enforce | Active |

**Drift signals.** An incident file names a feature and lists no fact id. An incident's prose states a behaviour or number directly, such as a batch's cost or time limit, instead of relying on a fact. A `source` points at a blog, a forum or anything else outside the official documentation. An entry's `verified` date is more than 30 days old and no issue is open for it. A `verified` date moves with no fetched evidence behind it. A fact's claim changes and no incident is flagged. A tooltip in `ui/` contains a hard-coded claim about a feature.

**Revisit when.** The nightly job's false alarms outnumber its real findings, official documentation URLs prove too unstable to serve as sources, or the single file becomes a regular source of merge conflicts.
