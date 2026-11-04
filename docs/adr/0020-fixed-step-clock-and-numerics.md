# ADR-0020: The simulation advances by integer ticks, commands carry their tick, and rule values are integers

| | |
| --- | --- |
| **Status** | Accepted |
| **Date** | 2026-11-04 |
| **Deciders** | Mikael Axelsson |
| **Sources** | `lattice-command-gdd.md` ("Core loop and game systems", "Architecture: three layers", "Pipeline"); `CLAUDE.md` ("Architecture", "Teaching rules that constrain the code") |
| **Related** | [ADR-0004](0004-compatibility-renderer-single-threaded-web.md), [ADR-0005](0005-three-layer-split.md), [ADR-0006](0006-deterministic-seeded-replay.md), [ADR-0008](0008-simulation-fidelity.md), [ADR-0009](0009-content-as-validated-json.md), [ADR-0019](0019-test-framework.md), [ADR-0021](0021-ci-on-github-actions.md) |

## Context

[ADR-0006](0006-deterministic-seeded-replay.md) requires exact replay from one seed and a command list, and leaves open how that is achieved. The GDD has a weekly strategic turn and a real-time-with-pause incident layer, and before this decision it said nothing about how time advances, how a command records when it applies, or how numbers behave across builds. The game ships on desktop and web, and a bug report from a browser must replay on a developer's Mac and in CI.

**Tested on 2026-11-04.** One probe ran on Godot 4.7.2 as native macOS arm64, native macOS x86_64 under Rosetta (the same universal editor binary, headless) and WebAssembly (the official single-threaded debug and release templates in headless Chrome 156, which matched each other). Each case hashed the exact bits of 200,000 results, or 1,000,000 for `randi`.

Bit-identical on all of these builds: `RandomNumberGenerator.randi`, `randi_range`, `randf`, `randf_range`, `rand_weighted` and `state`; `+ - * /`, `sqrt`, `floor`, `fmod`, `lerp` and `snappedf`; integer arithmetic; Dictionary key order; `hash()`; and `JSON.stringify`. With seed 20261104 the first `randi` values were 437216612, 3904786994, 1372772354, 1922794527 and 809608769, and 1,000,000 draws hashed to the SHA-256 prefix `48185fb7ca681d2f`.

Different on every pair of builds: `sin`, `cos`, `tan`, `exp`, `pow` and `randfn`. `log` and `atan2` matched between the two native builds and differed on the web. Sampled over 20,000 inputs, `sin` differed in 3,623 results between arm64 and x86_64 and in 851 between arm64 and web, `exp` and `pow` in about 30 to 50, always by one unit in the last place. One such bit is enough to break a replay once it reaches a comparison. So transcendental functions are not portable even between two native builds of one engine version, and `randfn` inherits the problem through its Box-Muller transform.

Adding `1.0/60.0` 216,000 times gives 3600.000000018228, so accumulated float time drifts. `Vector3` holds single precision. A JSON `1` parses to `TYPE_FLOAT`. Integers wrap silently on overflow (`9223372036854775807 + 1` gives the minimum value), and division truncates toward zero. A `Pcg32` of about 20 lines written in typed GDScript reproduced the engine's `randi` stream exactly for 1,000,000 draws on all builds tested, at about 0.22 µs per draw on arm64 against 0.023 µs for the engine.

**Verified from documentation and source.** Godot's [RandomNumberGenerator page](https://docs.godotengine.org/en/stable/classes/class_randomnumbergenerator.html) says a given seed gives a reproducible sequence, that it "currently uses PCG32", and that the algorithm "is an implementation detail and should not be depended upon", so stability across an engine upgrade is not promised. The engine's [`random_pcg.h`](https://github.com/godotengine/godot/blob/master/core/math/random_pcg.h) confirms the algorithm and that `randfn` uses `cos`, `sqrt` and `log`. The [Dictionary page](https://docs.godotengine.org/en/stable/classes/class_dictionary.html) states that insertion order is preserved and that erasing while iterating is unsupported. The [WebAssembly nondeterminism notes](https://www.webassembly.org/docs/nondeterminism/) list a NaN's sign bit as nondeterministic, and WebAssembly has no `sin` or `exp` instruction, so those come from a library.

**Not tested.** Linux, the likely CI platform, Windows, Firefox, Safari and the native desktop export templates were not run; only the macOS editor binary was. The documentation does not promise that integer overflow wraps or that `hash()` is stable, so those rest on observation. **Inferred.** Arithmetic in the engine's C++ could still differ with compiler fused-multiply-add choices on other targets, although nothing here showed it, and the browser should not matter for math functions because the library is compiled into the WebAssembly module.

## Decision

The project adopts the following model. Confidence is high that integer rule values and tick-stamped commands are right, since the measurements force the direction, and medium on the specific numbers (one simulated minute per tick and ten ticks per second), which the vertical slice should test.

**Clock.** Simulation time is one monotonic integer, `tick`, for the whole run, and one tick is one simulated minute, so a week is 10,080 ticks and a 24-hour batch is 1,440 ticks. The simulation must not take a delta, read a clock or know the frame rate; presentation calls `step()`. At normal speed the incident layer runs ten ticks per wall-clock second, so that a 24-hour batch takes 144 seconds, and presentation interpolates between ticks. Pause and speed are presentation choices that alter only how often `step()` is called, must not be commands, and must not change results. This ADR amends the wording of [ADR-0005](0005-three-layer-split.md), which says a command is the only way presentation may affect the simulation, and of [ADR-0006](0006-deterministic-seeded-replay.md), which calls commands the only input: `step()` drives the clock and carries no player decision, and a replay is the seed, the tick-stamped commands and the final tick. Presentation must cap the steps it runs per frame, so a slow browser slows the game rather than falling behind. Strategic play consumes no ticks until the player ends the turn, when the simulation advances to the next week boundary by processing scheduled events in order, without stepping empty ticks. Delayed consequences are events scheduled at an absolute tick, which gives "damage surfaces turns later" one mechanism across both layers.

**Commands.** The simulation stamps each accepted command with the current `tick` and a run-wide `seq`, and presentation must not choose either. A command issued during a pause gets the paused tick. Within a step the order must be: commands by `seq`, then due events by `(tick, schedule seq)`, then craft in stable id order, then event emission. Two orders given at once for a "select TWO" incident are two commands on one tick. A replay file holds the seed, the commands, the final tick, and the simulation, content and engine versions, and a mismatch must be reported rather than ignored.

**Numbers.** Every value a rule reads or writes must be an `int`. Rates are integer basis points (10,000 is 100%), and rounding goes through one helper with one documented rule. `sim/` must not hold `float`, `Vector*` or other floating point types in state, and must not call `sin`, `cos`, `tan`, `exp`, `log`, `pow`, `atan2` or similar. Values must stay within ±2^40 so that a product with a rate cannot overflow, and debug builds must assert this. The content loader must convert JSON numbers to `int` and must reject a non-integral value where an integer is expected. Presentation may convert to float freely, and nothing may flow back except as a command.

**Randomness.** `sim/` must own a small `Pcg32` written in GDScript, seeded from the run seed, with integer-only bounded draws and weighted picks, and must not use `RandomNumberGenerator` or `randfn`. This answers the question [ADR-0006](0006-deterministic-seeded-replay.md) left open, keeps the algorithm under the project's control across engine upgrades, and honours the rule that `sim/` makes no engine calls.

**Digests.** Tests compare a canonical serialisation of state, with sorted keys, hashed outside `sim/`. `hash()` output must not be stored in saves or replays, and the replay check must include a native run and a web run of the same command list.

## Alternatives considered

**Frame-delta simulation.** Rejected in [ADR-0006](0006-deterministic-seeded-replay.md), and the 1/60 result above shows the drift directly.

**Godot's `_physics_process` as the clock.** Its fixed delta is convenient, but it would tie rules to an engine setting and to a node, and a headless balance run should step as fast as it can. Presentation may use it as a timer if that proves handy.

**Floats restricted to basic arithmetic.** All basic operations matched in the probe, so this is not ruled out by the bits, and it would make rates more natural to write. It lost because the boundary is hard to review (one `pow` in a balance formula breaks replay in roughly one result in several hundred, long after the change), and Linux and Windows are untested. The game's values are counts and percentages, which integers fit well.

**Keeping the engine's `RandomNumberGenerator` with a golden-value test.** It is ten times faster and needs no new code, and its integer methods matched on all builds, so this is the strongest alternative. It lost narrowly, because the documentation disclaims the algorithm and `CLAUDE.md` forbids engine calls in `sim/`. If that rule is read as permitting pure engine classes, and draws turn out to be a hot path, this choice is reasonable and the rest of the ADR is unaffected.

## Consequences

Replay can be tested on every change, including across builds, and numeric mistakes are found by grep rather than by a rare desync. Incident timing, the 24-hour batch and delayed consequences share one time unit.

The costs: rates and formulas are more awkward without float, and any curve must be a lookup table or integer formula. Overflow is silent in GDScript, so the bound depends on assertions. The GDScript generator is about ten times slower than the engine's, which is acceptable unless draws reach hundreds of thousands per second. The generator relies on wrapping multiplication that the documentation does not promise, so a golden-value test must guard it. Changing the tick length or the generator invalidates stored replays, and this ADR does not promise replay across versions. The mapping of one tick to one minute is also a design choice: a tool call that takes a minute of simulated time is a simplification that the owner accepted together with [ADR-0008](0008-simulation-fidelity.md) on 2026-11-04.

## Staying on track

| Check | Enforced by | State |
| --- | --- | --- |
| The same seed and commands give the same digest whatever the steps-per-frame pattern | Headless test | Pending (needs the runner, [ADR-0019](0019-test-framework.md), and `sim/` clock) |
| `Pcg32` matches its golden values, including the first `randi` values and hash above | Headless test | Pending (needs the runner and `Pcg32`) |
| No forbidden numeric or RNG use in `sim/` | CI grep step using the pattern below | Pending (needs CI, [ADR-0021](0021-ci-on-github-actions.md), and `sim/` code) |
| A recorded replay gives one digest on native Linux, native macOS and web | CI job using headless Chrome, the method used in this probe | Pending (needs a replay runner, a main scene and CI) |
| New simulation code keeps to the model, and step ordering is unchanged | `sim-reviewer` subagent by hand; its definition does not mention numerics yet | Manual |

**Drift signals.** `grep -rnE '\b(float|Vector[234]|RandomNumberGenerator)\b|\b(sin|cos|tan|exp|log|pow|atan2|randfn)\(' --include='*.gd' sim/` finds anything. A command carries a tick set by presentation. Pause, speed or frame rate changes a run's digest. A desync appears only on the web. A JSON field reaches a rule without passing through the loader's integer check. Balance tuning asks for a curve that nobody can express in integers.

**Revisit when.** A CI cross-platform digest disagrees, which would mean an assumption above is wrong. A profile shows that `Pcg32` or integer maths dominates a frame. The slice shows that ten ticks per second or one minute per tick feels wrong or teaches the wrong thing. A rule really needs a non-linear function that a table cannot carry. Godot is upgraded, which requires re-running the probe.
