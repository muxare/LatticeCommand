# ADR-NNNN: The decision, stated as a sentence in the present tense

| | |
| --- | --- |
| **Status** | Proposed, Accepted, Accepted, amended by ADR-NNNN, or Superseded by ADR-NNNN |
| **Date** | YYYY-MM-DD on which the status last changed |
| **Deciders** | Who made or must make the call |
| **Sources** | GDD sections and `CLAUDE.md` sections this decision rests on |
| **Related** | Links to other ADRs |

## Context

The forces that make this a decision at all, in prose: what the project needs, what constrains it, and what goes wrong if nobody decides. Someone who has not read the GDD should understand why the question matters.

## Decision

What we do, stated firmly enough that a change can be judged against it. Use "must" and "must not" for anything a reviewer would reject a change over.

## Alternatives considered

Each real alternative, and the specific reason it lost. Leave out options nobody seriously held.

## Consequences

What becomes easier, what becomes harder, and what we have accepted as a cost. Include the costs; an ADR with only upsides is not honest.

## Staying on track

The checks that show whether the project still follows this decision. A check is **Active** when it runs today, **Pending** when it depends on something not yet built (name that thing), and **Manual** when a person or review subagent applies it.

| Check | Enforced by | State |
| --- | --- | --- |
| What is verified | The hook, test, CI job, rule or reviewer that verifies it | Active, Pending (needs X), or Manual |

**Drift signals.** The concrete things you would see in a diff, a playtest or a report if the project had started to wander from this decision.

**Revisit when.** The specific conditions under which this decision should be reopened rather than quietly worked around.
