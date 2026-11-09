# ADR-0018: A paper prototype comes first, an eight-week vertical slice is the go/no-go gate, and the strategy layer is not built ahead of the slice

| | |
| --- | --- |
| **Status** | Accepted, amended by [ADR-0023](0023-owner-decisions-on-the-open-register.md) |
| **Date** | 2026-11-04 |
| **Deciders** | Mikael Axelsson |
| **Sources** | `lattice-command-gdd.md` ("Scope and milestones", "Out of scope for 1.0", "Risks and open questions", "Onboarding: the first two hours"); `CLAUDE.md` ("Project status", "Architecture") |
| **Related** | [ADR-0004](0004-compatibility-renderer-single-threaded-web.md), [ADR-0007](0007-no-live-claude-api-in-play.md), [ADR-0011](0011-hand-authored-incidents-human-signoff.md), [ADR-0013](0013-teach-through-play.md), [ADR-0017](0017-test-first-headless-verification.md) |

## Context

The biggest risk to this project is pedagogical and not technical: a game can be fun and still teach the metaphor in place of the concept. The GDD holds that the riskiest question is whether incidents are fun and teach, and that the cluster map is known territory. A grand strategy game invites building its large, familiar systems first, which would spend months before that question has any answer. The plan runs to about nine months for a team of two or three, so the question has to be settled while abandoning or changing course is still cheap.

## Decision

The project must prove the teaching loop before building the strategy layer around it. Work follows the GDD's milestones in order, and the strategy layer must not be built ahead of the vertical slice.

Milestone 0 is a two-week paper prototype of ten incidents played as cards with a game master, with the simulation rules in a spreadsheet. Its exit test is that testers name the right fix more often after playing than before. Milestone 1 is the eight-week vertical slice: one Harbour colony in 3D, the ship's log, the refit menu, interlocks, three Concord doctrines and the first two hours of onboarding. Its exit test is that five players finish onboarding unaided and describe a PreToolUse hook in their own words. [ADR-0023](0023-owner-decisions-on-the-open-register.md) trims the slice's onboarding to one colony and adds the before-and-after measure and a browser smoke test to this exit test.

Three later milestones follow. Alpha takes 12 weeks and exits when a full campaign is playable and readiness gauges correlate with a practice test score. Beta takes 10 weeks and exits when players who finish score higher on a fresh practice test than a study-guide control group. Release takes 4 weeks and exits with content verified within 30 days of launch.

The vertical slice is the go/no-go point. That sentence is all the sources state about the gate. "Go" is not defined beyond the slice's exit test and the next milestone, Alpha, which is where the cluster map first appears. "No-go" is not defined at all.

Out of scope for 1.0 are multiplayer, procedurally generated incidents, live calls to the Claude API during play, and content beyond the CCAR-F and its supporting courses. The schema leaves room for later certifications as new campaigns, but that content must not enter 1.0.

**Open points.** The sources do not say who makes the go/no-go call, what happens on a no-go (stopping, reworking the slice, or changing the design), or whether passing the exit test is sufficient for "go" or only necessary. They do not say what a failed paper prototype means for starting the slice, or give a tester count or margin for "more often". The stated risk is whether incidents are "fun and teach", yet the slice's exit test measures finishing onboarding and describing a hook, and nothing measures fun. The strategy layer's boundary is also unclear. The slice names one colony, but the onboarding it includes has a second colony join at 0:55 with Reach and Credits to split and has first research at 0:40, which are strategic-layer activities, and an after-action report at 1:45, which is otherwise listed under Alpha. The sources do not say how much of that the slice builds for real and how much it stubs. The slice's incident count is unstated. The GDD says the Compatibility renderer must prove itself in the slice, while the web build is listed under Beta, so whether the slice must be tested on the web is also open.

## Alternatives considered

The GDD's reasoning implies the first of these, and the rest were considered while writing this ADR. **Building the strategy layer first** would produce an impressive frame quickly, but it lost because the cluster map is known territory and would answer nothing about the main risk. **Skipping the paper prototype** would save two weeks, but those two weeks test the teaching idea before any engine work is committed. **Including a live Claude API or generated incidents in 1.0** might widen the content, but the GDD rules them out for determinism, offline play, cost and accuracy; [ADR-0007](0007-no-live-claude-api-in-play.md) and [ADR-0011](0011-hand-authored-incidents-human-signoff.md) record those decisions.

## Consequences

The riskiest question gets an answer about ten weeks in, and a poor result costs far less than it would at the end. Scope arguments can be settled against a written list, and the presentation, simulation and content work all have a small first target.

The costs are that the first ten weeks produce little that looks like a grand strategy game, and that decisions made for the slice may need rework when the strategy layer arrives. Five players are a small sample, and a passing result can be fragile. Because the no-go path and the decider are unstated, a disappointing result could be argued away unless these points are settled before the playtest. Keeping the out-of-scope items out also means turning down attractive features.

## Staying on track

| Check | Enforced by | State |
| --- | --- | --- |
| Testers name the right fix more often after playing than before | Milestone 0 playtest with a game master | Pending (needs the paper prototype and its ten incidents) |
| Five players finish onboarding unaided and describe a PreToolUse hook in their own words | Milestone 1 playtest | Pending (needs the vertical slice) |
| Strategy-layer work does not start before the gate is passed | Review of plans and pull requests against this ADR | Manual |
| Changes do not add multiplayer, procedural incidents, live API calls or content beyond the CCAR-F and its supporting courses | Pull request review; `sim-reviewer` for `sim/` | Manual |
| Later exit tests for Alpha, Beta and Release are met | Each milestone's own measure | Pending (needs those milestones, and the benchmark practice test that the GDD lists as an open question) |

**Drift signals.** Before the gate, `sim/` gains weekly turn processing, or `scenes/` gains a cluster map, or `content/` gains colony types other than the Harbour or doctrines beyond the slice's three. A networking layer, an API key setting, an `HTTPRequest` to a model endpoint or an incident generator appears. Incidents appear for another certification. A milestone is called done without a recorded playtest, or its exit test is reworded after the results come in. The slice passes eight weeks with no recorded decision about it.

**Revisit when.** Either exit test fails, the slice substantially overruns its eight weeks, the open points on the decider and the no-go path are answered, or the GDD's open questions on audience or platform are settled in a way that changes what the slice has to prove.
