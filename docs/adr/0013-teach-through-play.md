# ADR-0013: The game teaches through play, with no quizzes during play, visible real terms, delayed and traceable consequences, and a thin optional bridge to the exam

| | |
| --- | --- |
| **Status** | Accepted |
| **Date** | 2026-11-04 |
| **Deciders** | Mikael Axelsson |
| **Sources** | `lattice-command-gdd.md` ("Vision", "Learning design", "Incident layer", "Bridge to the exam", "Onboarding", "Scope and milestones", "Risks", "Open questions"); `CLAUDE.md` ("Teaching rules that constrain the code", "Project status") |
| **Related** | [ADR-0001](0001-record-architecture-decisions.md), [ADR-0005](0005-three-layer-split.md), [ADR-0006](0006-deterministic-seeded-replay.md), [ADR-0008](0008-simulation-fidelity.md), [ADR-0010](0010-fact-sheet-single-source.md), [ADR-0011](0011-hand-authored-incidents-human-signoff.md), [ADR-0012](0012-content-mapping-is-the-contract.md), [ADR-0017](0017-test-first-headless-verification.md), [ADR-0018](0018-vertical-slice-gate-and-scope.md), [ADR-0020](0020-fixed-step-clock-and-numerics.md) |

## Context

The vision is that players learn the CCAR-F content without studying, because the game's rules are the certification's concepts. That can fail in two opposite ways. If the game behaves like a study tool, it stops being a game, and players who are not preparing for the exam leave. If the fiction takes over, players learn the metaphor and not the concept, which the GDD names as its biggest risk: someone who knows "interlocks" but not "PreToolUse hook" gains nothing in the exam. Many small interface and scoring choices, each harmless in isolation, can push the game either way.

## Decision

The game must not quiz during play, and nothing may interrupt a crisis. Players learn because winning requires the content. Incidents run in real time with pause, and during onboarding the game pauses automatically on the first incident of each kind.

Real terms stay visible. Fiction names sit on top, but every tooltip, menu and log line must carry the real term, such as "Interlock" with "PreToolUse hook".

Consequences are delayed and traceable. Damage from a misconfiguration surfaces later, as an event scheduled at an absolute tick ([ADR-0020](0020-fixed-step-clock-and-numerics.md)), which on the strategic layer means several turns after the decision, and the incident log must always show the causal chain back to the decision. Only a fix at the causal layer closes an incident. A fix at the wrong layer appears to work, then the incident recurs or the Concord exploits it.

The bridge to the exam is thin and optional. After-action reports restate a closed incident in exam format, the player can skip them, and reading them earns Insight. The bridge must not use exam vocabulary that play has not already taught. Speed must never be rewarded over reading the log.

Two points stay open. The War College is the first: the GDD says "the game never quizzes" yet describes a timed mode of scenario questions with a mock score, while `CLAUDE.md` says "during play". Because the mode is unlockable and interrupts no crisis, it does not break the rule against interrupting a crisis, but a timed mode does sit uneasily with the rule on speed, so this reading needs a person's confirmation and the GDD's wording needs correcting either way. The second is the GDD's open questions: the audience, which decides whether the War College is central; the licensing boundary on how closely reports may mirror the exam's format; and which practice test measures learning and who owns that study. How delay works in the vertical slice, which has one colony and no strategy layer, is settled by [ADR-0020](0020-fixed-step-clock-and-numerics.md): a delayed consequence is an event scheduled at an absolute tick, one mechanism across both layers.

## Alternatives considered

**Quizzes that interrupt play.** The GDD rejects these explicitly, in the opening of "Learning design" and in "What the bridge must never do": players are meant to learn because winning requires the content.

**Fiction names alone.** This would read better and leave interfaces less crowded, but the GDD says transfer to the exam depends on the vocabulary, and it lists learning the metaphor instead of the term as a risk of high impact.

**A mandatory bridge.** Requiring each report would guarantee exposure to the exam's format. The GDD chooses otherwise, keeping the bridge thin and optional "so the game stays a game", and pays players for reading instead.

**Immediate feedback on wrong orders**, considered while writing this ADR. It would be easier to build and easier to understand, and it would reduce frustration. It loses because the exam's distractors tempt by appearing to work, so a wrong order that fails at once would teach the player to spot the game's signal and not the mistake.

## Consequences

Vocabulary and judgement are practised in play, so the game can be enjoyed without the exam. The temptation of the Concord's quick fixes is real because those fixes work for a while.

The costs are real too. Delay makes each incident harder to build and harder to test, since the simulation must record the link from a decision to its later damage, so that the log can show it and a seeded run can replay it. Delayed punishment risks feeling unfair if the chain is hard to read, which is why tracing is not optional. Carrying two names on every label costs screen space. Optional is not the same as free: a player who skips reports loses Insight and therefore research speed, and may also transfer less to the exam, which the project accepts. Whether this design teaches at all can only be shown by playtests, so no automated check below can prove it. Enforcement of the real-term rule is also weak as of 2026-11-04: `CLAUDE.md` states it, but `.claude/rules/scenes.md`, which loads for `scenes/**` and `ui/**`, does not mention it, and `.claude/rules/content.md` loads only for `content/**`.

## Staying on track

| Check | Enforced by | State |
| --- | --- | --- |
| Every session is told the teaching rules | `CLAUDE.md`, which instructs but does not enforce | Active |
| Every tooltip, menu and log line carries the real term | An automated check over UI strings and a screenshot review | Pending (needs UI code and a decided home for UI text) |
| A wrong-layer fix appears to work and then recurs, and the correct fix closes the incident | Seeded simulation tests and the `balance-check` skill | Pending (needs the simulation and the seeded runner) |
| Every wrong order declares a delayed consequence | JSON Schema for incidents, `tools/schemas/incident.schema.json`, run by the validator | Active (PostToolUse and Stop hooks; CI pending [ADR-0021](0021-ci-on-github-actions.md)) |
| The incident log shows the causal chain back to the decision | Simulation test against the event stream, plus playtest | Pending (needs the simulation core and incident log) |
| No score or reward depends on resolving an incident quickly | Simulation test once scoring exists, and pull request review | Pending (needs the scoring rules) |
| Nothing interrupts a crisis, and reports can be skipped | Windowed playtest and pull request review of `scenes/` and `ui/` | Manual |
| Reports use only vocabulary that play has already taught | The human reviewer in step 5 of the pipeline in [ADR-0011](0011-hand-authored-incidents-human-signoff.md) | Manual |
| Players can state the real term, not only the fiction name | Playtest term-recall check and the slice exit test, in which players describe a PreToolUse hook in their own words | Pending (needs the vertical slice build) |

**Drift signals.** A tooltip or log line reads "Interlock" with no "PreToolUse hook" beside it. A modal question appears during an incident. A time bonus, a speed-based Insight award or a best-time score appears. Pause is restricted or made costly. A wrong order fails at once with a message saying it was wrong. The incident log has a gap between symptom and decision. A report must be read in order to continue, or uses a term the player has not unlocked. Playtesters say "interlock" and cannot say what it is in Claude.

**Revisit when.** The vertical slice's exit test fails on term recall or on finishing unaided, players judge the delay unfair even with the causal chain visible, the audience question makes the War College central, or the licensing answer limits the format of after-action reports.
