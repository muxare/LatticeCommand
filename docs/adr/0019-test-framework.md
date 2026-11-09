# ADR-0019: Simulation tests run on a small in-repo runner under `godot --headless --script`, with no third-party framework yet

| | |
| --- | --- |
| **Status** | Accepted |
| **Date** | 2026-11-04 |
| **Deciders** | Mikael Axelsson |
| **Sources** | `lattice-command-gdd.md` ("Language: GDScript or C#", "Architecture: three layers", "Hooks", "CI with Claude Code"); `CLAUDE.md` ("Tools", "Code conventions", "Claude Code setup") |
| **Related** | [ADR-0003](0003-typed-gdscript.md), [ADR-0005](0005-three-layer-split.md), [ADR-0006](0006-deterministic-seeded-replay.md), [ADR-0017](0017-test-first-headless-verification.md), [ADR-0020](0020-fixed-step-clock-and-numerics.md), [ADR-0021](0021-ci-on-github-actions.md) |

## Context

The project writes the failing simulation test first, and the Stop hook and the CI test job both wait for a headless test command. The GDD named "GUT or gdUnit4" without choosing until this decision corrected it. The balance runner is a separate question: `CLAUDE.md` says that `balance-check` waits for the seeded simulation runner, which is a script over the simulation and needs no test framework.

What the tests must do shapes the choice. The simulation core consists of RefCounted classes with no nodes, so the rule tests need neither a scene tree nor input simulation. What they need above all is a trustworthy exit code, because an unattended agent reads "done" from it. GDScript has no exceptions, so a runtime error ends the failing function, returns the default value of its return type to the caller (`false` for a method typed `-> bool`, as `tests/run.gd` observed on Godot 4.7.2 on 2026-11-09; this sentence said null until then) and lets the process go on, and a test that errors can therefore look like a test that passed unless the runner guards against it.

**Verified from primary sources on 2026-11-04.** [GUT's README](https://github.com/bitwes/Gut) maps version 9.7.1 to Godot 4.7.x on a separate `godot_4_7` branch, and its main branch stays on 4.6. GUT 9.7.1 was released on 2026-07-10, before Godot 4.7.2 was published on [2026-08-18](https://github.com/godotengine/godot-builds/releases/tag/4.7.2-stable), and [9.7.0's notes](https://github.com/bitwes/Gut/releases/tag/v9.7.0) list a breaking change to doubles caused by Godot 4.7's stricter return types. GUT's [command-line page](https://gut.readthedocs.io/en/latest/Command-Line.html) documents exit code 0 when all tests pass and 1 when any fail. [gdUnit4's README](https://github.com/godot-gdunit-labs/gdUnit4), whose repository has moved to the `godot-gdunit-labs` organisation, lists its 6.2.x line for Godot 4.5 to 4.7.1 and does not list 4.7.2, although 6.2.3 was released on 2026-11-01, after 4.7.2. It also offers a GitHub Action and JUnit XML output. Its source for 6.2.3 refuses to run headless unless given `--ignoreHeadlessMode`, because input events do not work there, and `assert_int(current: Variant)` shows a typed API over Variant, while GUT's `assert_eq(got, expected, text="")` is untyped. Both frameworks hook the engine's `Logger` to catch script errors. GUT's addon is 86 scripts and 19,699 lines, and gdUnit4's is 236 scripts and 27,535 lines. Both are MIT licensed.

**Tested on Godot 4.7.2 on 2026-11-04.** A prototype runner of about 40 lines in a scratch project, invoked as `godot --headless --path . --script res://tests/run.gd`, took about 0.27 seconds per run on an arm64 Mac with one small test file. It exited 0 when the test passed and 1 for each of these: a failed check, a runtime error (a missing Dictionary key), a parse error in a test file, a parse error in a simulation class, and an untyped member under `untyped_declaration` set to error. On a fresh checkout without `.godot/`, a test using a `class_name` failed with `Could not find type "Ledger"` and exit 1 until `godot --headless --path . --import` had run. That last point applies to anything run this way, and the failure was loud rather than silent.

**Not tested.** Neither GUT nor gdUnit4 was executed on 4.7.2. The command that would have run them in a scratch project was denied by the permission system during drafting and was not retried, so everything above about them comes from their documentation and from reading their source. Their exit codes under a runtime or parse error are unknown. **Inferred.** The speed and maintenance comparisons below are judgement, and only the prototype's timing was measured.

## Decision

The project starts with a minimal in-repo runner at `tests/run.gd` and adopts no third-party framework until a test needs something the runner cannot do. The decision was made with medium confidence, about 70%. Confidence is high that the simulation core does not need a framework's mocks or scene tools, and lower on how long a home-grown runner stays small and whether a real trial of the frameworks would change the picture.

The test command must be `godot --headless --path . --script res://tests/run.gd`, preceded by `godot --headless --path . --import` on any fresh checkout. The runner must exit non-zero on a failed check, a test script that does not load, a test that does not run to its end, and a run that executes zero tests. Every test method must signal that it ran to completion, as the prototype did with a `true` return value, so that a runtime error is counted as a failure. The runner and its helpers must be typed GDScript and must have no dependency on `addons/`. Its check helpers should stay thin, such as `check` and `check_eq`, so that moving to a framework later is a mechanical rewrite. The runner must be tested against deliberately broken fixtures, because a runner that wrongly reports success is the worst failure this decision can produce. The GDD's "GUT or gdUnit4" row was corrected in the same change on 2026-11-04, as [ADR-0001](0001-record-architecture-decisions.md) requires.

The trigger for adopting a framework is the first test that needs a scene runner, input simulation or doubles. gdUnit4 would be the first candidate to trial for that, because of its typed assertions, scene runner, CI action and JUnit output, but that choice is not made here and would need its own trial on the pinned engine.

## Alternatives considered

**gdUnit4 now.** It is the richest option, and it has the most active recent release history and a ready-made GitHub Action. It lost for now because its main strengths serve scene and UI tests that the rule tests do not need, it adds about 27,000 lines of third-party code to a repository that Claude Code reads, and its compatibility table does not yet name the pinned engine. It also tells us that headless is its unsupported mode, while headless is the only mode this project's core tests use.

**GUT now.** It is mature and documents its exit codes clearly. It lost for the same size reason, and because its untyped assertions fit the typed GDScript rule less well. Its version-per-engine branches and the 4.7 doubles break show a framework closely tied to engine internals, a cost that a project with a strict engine pin pays at every upgrade.

**A plain `assert()` in a script.** This is the smallest possible option. It lost because the [GDScript reference](https://docs.godotengine.org/en/stable/classes/class_@gdscript.html) says a failed `assert` generates an error and makes the method return a default value, and that it runs only in debug builds, so it gives no count of failures and no exit code by itself.

## Consequences

Tests start at once with no dependency and no upgrade exposure beyond GDScript itself, and the runner's behaviour on 4.7.2 is measured rather than promised. The Stop hook can call it cheaply, translating a failure to exit code 2, which the [hooks reference](https://code.claude.com/docs/en/hooks) says makes Claude keep working on a Stop event.

The costs are real. The project owns a small piece of test infrastructure and its fixtures, and there is no JUnit report, parameterised test support, orphan detection or mocking until somebody adds them. The rule that tests signal completion is unusual and has to be learned, though forgetting it fails loudly. **Added on 2026-11-09, when the runner was built.** Returning `true` catches an error only in the test method's own body, because an error in a function it calls returns a default value and the test goes on, so `tests/run.gd` also installs an engine `Logger` through `OS.add_logger` and fails a test on any engine error logged while it runs. A test that means to provoke an error declares it first with `expect_error(text)`, and an undeclared error or a declared one that never arrives fails the test. The runner's exit code starts at 1 and becomes 0 only on its explicit success path. For the same reason, `sim/` reports invalid input with `push_error` and a defined return instead of `assert`, which vanishes in release builds and would make debug and release consume random draws differently. A second cost is that `export_presets.cfg` as of 2026-11-04 exports all resources with an empty exclude filter, so `tests/` would ship in the web build unless it is excluded, and that would apply to a framework's addon as well.

## Staying on track

| Check | Enforced by | State |
| --- | --- | --- |
| The runner exits non-zero on failed check, runtime error, parse error and zero tests | Broken-fixture self-test run in CI | Pending (needs `tests/run.gd`, its fixtures and CI, [ADR-0021](0021-ci-on-github-actions.md)) |
| Simulation tests pass headlessly on a fresh checkout | CI job that runs `--import` and then the test command | Pending (needs the runner, first tests and CI) |
| Claude cannot report done with failing tests | Stop hook | Pending (needs the test command and, as the GDD specifies, the content validator) |
| The test command is listed in `CLAUDE.md` and `tests/` is excluded from exports | Pull request review of the change adding the runner | Manual |
| Rule tests use no scene tree and no addon | `sim-reviewer` subagent, invoked by hand | Manual |

**Drift signals.** `tests/run.gd` grows past a few hundred lines, or starts reimplementing mocks, scene running or report formats. A test file works around the runner with `await` or a scene. A run reports success with `ran=0`. A CI job passes while its log contains `SCRIPT ERROR`. `addons/` appears in the repository with no superseding ADR.

**Revisit when.** The first test needs a scene runner, input or doubles, a reviewer or teammate needs JUnit or HTML reports, the runner has needed repeated bug fixes, or someone runs the two frameworks on 4.7.2 and finds that they catch failures the runner misses.
