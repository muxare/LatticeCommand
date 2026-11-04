# ADR-0001: Architecture decisions are recorded as numbered, immutable ADRs that each carry their own checks

| | |
| --- | --- |
| **Status** | Accepted |
| **Date** | 2026-11-04 |
| **Deciders** | Mikael Axelsson |
| **Sources** | `lattice-command-gdd.md` (all sections, in particular "Technology: engine, language and architecture"); `CLAUDE.md` (introduction, "Project status") |
| **Related** | All other ADRs |

## Context

The project is about to move from a design document to a nine-month build, with Claude Code doing most of the implementation across many separate sessions. Each session starts without memory of why the last one chose what it did. A decision that exists only as a sentence in a 570-line design document is easy to overlook, and easier still to undo by accident, because the document records what the game should be far more thoroughly than it records what was rejected and why.

The teaching goal raises the stakes. In this project a wrong simulation rule teaches a wrong exam answer, so drift is not only a maintenance cost but a defect in the product. The project needs a short, stable reference that a person or an agent can check a change against, and it needs to say how anyone would notice that the project had drifted.

## Decision

Architecture decisions are recorded as individual Markdown files in `docs/adr/`, named `NNNN-short-title.md` and numbered in the order they are written. `docs/adr/README.md` is the index.

An ADR records a decision that is expensive to reverse, or that constrains more than one layer or more than one piece of work. Ordinary implementation choices do not need one.

The GDD remains the design source of truth, as `CLAUDE.md` states, and an ADR does not replace it. The GDD says what the game is; an ADR says which structural choice was made, what it was chosen over, and how adherence is checked. Where the two disagree, neither silently wins: the disagreement is a defect, and the change that resolves it corrects both documents in the same commit.

An Accepted ADR is immutable in substance. To change a decision, write a new ADR that supersedes the old one, set the old one's status to "Superseded by ADR-NNNN", and correct the GDD and `CLAUDE.md` in the same change. An ADR that replaces only part of an earlier one sets the earlier one's status to "Accepted, amended by ADR-NNNN" and keeps the rest in force, and the earlier ADR keeps its original sentence with a one-sentence pointer beside it. Fixing a typo or updating the State column of a check is not a change of substance and does not need a new ADR.

A status of Accepted means that a person has made the decision. An ADR that an agent drafted may be Accepted from the start only when it records a decision a person has already written down in the GDD or `CLAUDE.md`, and it must cite where. Any other agent-written ADR stays Proposed until a person accepts it, which mirrors the project's rule for incidents: AI drafts, humans sign off.

Every ADR must end with a "Staying on track" section following `0000-template.md`. Its checks are labelled Active, Pending or Manual, and a Pending check must name what it is waiting for. A plan for a large feature must cite the ADRs it touches alongside the GDD section it implements, and a plan or change that conflicts with an Accepted ADR must either be changed or come with a superseding ADR. It must not proceed on the quiet.

## Alternatives considered

**Keeping decisions in the GDD alone.** The GDD already holds a decision table for language and a table of alternatives for the engine. It lost because it mixes design and architecture in one long document, has no way to mark a decision as superseded, and gives nowhere natural to state how adherence is checked.

**Keeping decisions in `CLAUDE.md` alone.** That file loads into every session, which is exactly why it must stay short. It distils the rules to follow and cannot also carry the reasoning and the rejected alternatives. It points to the ADRs instead.

**A single decisions log.** One file is simpler to create, but it grows into the same problem as the GDD and makes supersession and linking clumsy. Separate files can be cited individually in a plan or a review.

## Consequences

A plan or a review can cite a specific decision, and a new session can read one short file instead of reconstructing the reasoning. Rejected options stay rejected for a stated reason, so they do not come back as fresh ideas each month.

The cost is upkeep and some duplication, because a decision can now appear in the GDD, in `CLAUDE.md` and in an ADR. The rule that one change corrects all three is what keeps that duplication honest, and it depends on discipline until tooling exists. A second cost is that many early checks are Pending, because the tooling they depend on does not exist yet. That is accurate rather than embarrassing, and the index collects those gaps in one place so they stay visible.

## Staying on track

| Check | Enforced by | State |
| --- | --- | --- |
| Plans for large features cite the relevant ADRs and GDD section | Review of the plan by the person approving it | Manual |
| A change that conflicts with an Accepted ADR comes with a superseding ADR | Pull request review | Manual |
| Every ADR has the template's sections and is listed in the index | Pull request review | Manual |
| Pending checks are converted to Active when their tooling lands | The change that adds the tooling updates the State column and the index | Manual |

**Drift signals.** A pull request changes an architectural boundary and cites no ADR. A GDD section is corrected but the ADR resting on it still says the old thing. The index's list of pending checks stays the same while the tooling those checks wait for has already been merged. An ADR is Accepted without a named person having decided it.

**Revisit when.** ADRs are written after the fact more often than before it, which would mean the process costs more than it returns, or the number of files makes the index hard to scan.
