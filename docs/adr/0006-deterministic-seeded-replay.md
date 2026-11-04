# ADR-0006: A run replays exactly from one seed and a command list

| | |
| --- | --- |
| **Status** | Accepted, amended by [ADR-0020](0020-fixed-step-clock-and-numerics.md) |
| **Date** | 2026-11-04 |
| **Deciders** | Mikael Axelsson |
| **Sources** | `lattice-command-gdd.md` ("Architecture: three layers", "Learning design", "Core loop and game systems", "Pipeline" under "Content pipeline and fact accuracy"); `CLAUDE.md` (introduction to "Architecture", "Teaching rules that constrain the code") |
| **Related** | [ADR-0005](0005-three-layer-split.md), [ADR-0007](0007-no-live-claude-api-in-play.md), [ADR-0008](0008-simulation-fidelity.md), [ADR-0017](0017-test-first-headless-verification.md), [ADR-0019](0019-test-framework.md), [ADR-0020](0020-fixed-step-clock-and-numerics.md), [ADR-0021](0021-ci-on-github-actions.md) |

## Context

The game's consequences are delayed by design. Damage from a misconfiguration surfaces later, as an event scheduled at an absolute tick ([ADR-0020](0020-fixed-step-clock-and-numerics.md)), which on the strategic layer means several turns after the decision, and the incident log must trace it back to the decision that caused it. A bug in that chain is hard to see in the moment and impossible to diagnose if it cannot be reproduced, and in this project such a bug can be a wrong lesson. Agents and playtesters will both report problems, and the report needs to be something a fresh session can run.

The same property supports the project's verification. The `balance-check` skill is specified as playing each incident once per order under fixed seeds, which means nothing unless the same seed and orders produce the same result. Godot makes this easy to lose, because global random functions, frame deltas, `Time` and unstable sorts are all a line away and none of them fails visibly when it is used.

## Decision

Given the same seed, the same command list and the same code and content, a run must produce exactly the same simulation state and the same events. Commands, as defined in [ADR-0005](0005-three-layer-split.md), are the simulation's only input. [ADR-0020](0020-fixed-step-clock-and-numerics.md) amends this wording, because presentation also calls `step()` to drive the clock, which carries no player decision, so a replay is the seed, the tick-stamped commands and the final tick.

All randomness in `sim/` must come from a seeded generator that the simulation owns. Code in `sim/` must not call global random functions such as `randi`, `randf`, `randomize` or `seed`, and must not call `Array.shuffle` or `Array.pick_random`, which Godot's documentation says use the common global seed. Presentation must not draw from the simulation's generator, because a replay would then depend on what was drawn on screen; effects that do not affect the rules use their own randomness.

Simulation code must not read the wall clock or any other value that differs between runs, which includes `Time`, frame deltas, object instance IDs and the machine's locale or performance.

Simulation code must not depend on an iteration order that can vary. Godot's documentation states that dictionaries preserve insertion order, so iterating one is acceptable only when the insertion order is itself a product of the seed and commands. It also states that `Array.sort` and `Array.sort_custom` are not stable, so any sort in `sim/` whose result affects a rule must use a comparator that gives a total order, with no ties.

The clock model and numerics are not decided here. How the incident layer's real time with pause and the strategic layer's weekly turns map onto simulation time, how a command records the moment it applies, and whether floating point results match between web and desktop builds all belong to [ADR-0020](0020-fixed-step-clock-and-numerics.md), which the owner accepted on 2026-11-04, and this ADR requires only that the answer preserve exact replay.

Other points also remain open: the format of the command list and of the save file, whether a save is a replay or a snapshot, and whether the generator is one stream or several. [ADR-0020](0020-fixed-step-clock-and-numerics.md) settles the generator's implementation, an own `Pcg32`, and has a replay file record the simulation, content and engine versions it needs. It has not been established whether `RandomNumberGenerator` output is stable across a Godot upgrade, and because `sim/` does not use that class the question no longer bears on replay.

## Alternatives considered

**Driving the simulation from frame deltas, the ordinary Godot loop.** It needs no extra machinery, and it lost because frame timing varies by machine, so no two runs would match. The replacement belongs to [ADR-0020](0020-fixed-step-clock-and-numerics.md).

**Reproducing bugs from saved state alone, with a non-deterministic simulation.** A snapshot shows where a run ended up and is simple to capture. It lost because the project's failures are delayed: the cause lies turns before the symptom, so the chain has to be replayed and not merely inspected, and seeded tests would not be repeatable at all.

The sources do not record any further comparison.

## Consequences

Any bug report can be replayed from a short file, a test can pin a whole scenario, and `balance-check` can compare orders under identical conditions. The causal chain in the incident log can be checked rather than assumed. Replay also lets a subagent reproduce a problem with no knowledge of how it arose.

The costs are ongoing discipline and fragile recordings. Convenient engine features are off limits in `sim/`, and physics, animation and timers cannot decide outcomes. A correct change that adds one random draw can shift every later result, so stored replays and any test pinned to exact values can break without any bug being present. A replay is exact only against the code and content that produced it, which means that a seed and a command list are not quite the whole bug report, despite the GDD's shorthand; they also need the version they ran on.

## Staying on track

| Check | Enforced by | State |
| --- | --- | --- |
| Sessions touching `sim/` are told the rule; this informs and does not verify | `.claude/rules/sim.md` | Active |
| Diffs under `sim/` replay from a seed and a command list | `sim-reviewer` subagent, whose definition covers this and which is invoked by hand | Manual |
| The forbidden-call pattern below finds nothing in `sim/` | A CI grep step | Pending (needs CI, [ADR-0021](0021-ci-on-github-actions.md)) |
| Two runs from the same seed and commands give identical events and final state | Headless test | Pending (needs the test runner, [ADR-0019](0019-test-framework.md), and `sim/` code) |
| Incidents give the same result per order under fixed seeds | `balance-check` skill, which stops by design until its runner exists | Pending (needs seeded simulation runner) |

**Drift signals.** `grep -rnE '\b(randi|randf|randi_range|randf_range|randfn|randomize|seed)\(|\.(shuffle|pick_random)\(|\bTime\.|\bget_instance_id\(' --include='*.gd' sim/` finds anything. A `sort_custom` comparator in `sim/` can return false both ways for two different elements. A `_process`, `delta` or timer appears in `sim/`. Simulation results change when the frame rate or the window changes. A test is marked flaky or retried. A bug report arrives that cannot be reproduced from its seed and commands, and the response is to add logging instead of finding the source of the variation.

**Revisit when.** [ADR-0020](0020-fixed-step-clock-and-numerics.md) finds that exact replay across web and desktop builds cannot be achieved, or keeping replays valid across versions costs more than it returns. Either should narrow this decision explicitly in a superseding ADR.
