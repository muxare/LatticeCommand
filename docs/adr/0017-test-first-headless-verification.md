# ADR-0017: Simulation rules are written test-first and verified headlessly, and visual work is judged from a windowed screenshot

| | |
| --- | --- |
| **Status** | Accepted |
| **Date** | 2026-11-04 |
| **Deciders** | Mikael Axelsson |
| **Sources** | `lattice-command-gdd.md` ("Daily workflow", "Architecture: three layers", "CI with Claude Code", "Domain 3: Claude Code configuration and workflows"); `CLAUDE.md` ("Code conventions", "Tools", "Project status") |
| **Related** | [ADR-0005](0005-three-layer-split.md), [ADR-0006](0006-deterministic-seeded-replay.md), [ADR-0008](0008-simulation-fidelity.md), [ADR-0016](0016-claude-code-config-as-worked-example.md), [ADR-0019](0019-test-framework.md), [ADR-0021](0021-ci-on-github-actions.md) |

## Context

In this project a wrong simulation rule teaches a wrong exam answer, and Claude Code writes most of the code, so the project needs evidence that does not depend on the author's confidence. The three-layer split makes that affordable: the simulation is pure logic, and the GDD expects every rule to be testable headlessly in milliseconds. Tests of that kind say nothing about whether a screen is legible, though, and legibility is what the game's 3D presentation exists for. A single standard of "tests pass" would therefore be too weak for presentation and could never be applied to it. There is no test runner, test or game code yet, so this decision sets the working method before the first rule is written.

## Decision

A change to simulation rules must begin with a failing test, and the code follows. Simulation rules must be verifiable with Godot's `--headless` mode, which means their tests must not need a display or a scene tree.

Large features must start in plan mode. The plan cites the GDD section it implements and, under [ADR-0001](0001-record-architecture-decisions.md), the ADRs it touches.

Visual work must be judged by running the game windowed, capturing a screenshot and inspecting it, because headless tests cannot judge a UI. A presentation change must not be reported as verified on the strength of headless tests alone.

This ADR does not choose how tests are run. [ADR-0019](0019-test-framework.md), which the owner accepted on 2026-11-04, settles that with a small in-repo test runner, and the test command is added to `CLAUDE.md` when it exists.

**Open points.** The sources do not define how large a feature must be to count as "large", so that remains a judgement. They do not say how the screenshot is captured, where it is kept, or whether a person must look at it as well; the GDD has Claude Code inspect it, and `CLAUDE.md` does not say who does. They state the test-first rule only for simulation work, so its reach over content tooling and presentation scripts is undecided. Finally, the GDD says that each layer has its own automated check, covering content, rules and visuals, which sits uneasily with the statement that visuals are judged from a screenshot and not by headless tests.

## Alternatives considered

The sources state no rejected alternatives, so these were considered while writing this ADR. **Writing tests after the code** is quicker in the moment, but such a test can only confirm what the code already does, and it cannot show that it would catch a wrong rule. The GDD names "retry until it passes" as the Brute trap and says that tests define done. **Testing rules through running scenes** would exercise more of the game, but it would tie rule tests to the engine and give up the speed and display independence that the three-layer split exists to provide. **Treating headless runs as enough for visual work** would be simple to automate, but the sources state plainly that they cannot judge a UI.

## Consequences

Rules gain an executable record of what they mean, and agents can check their own work without a display, including in CI. A failing test also makes a good, unambiguous brief for a fresh session.

The costs are that writing tests first slows the first draft of every rule, and that a test can encode a misunderstanding of Claude's behaviour as easily as code can, so tests do not replace checking the fact sheet. Plan mode adds a step before large work. Visual verification stays slow and depends on judgement, and it needs a display, so it cannot run on an ordinary headless CI runner. Until the test runner, the main scene and CI exist, this whole decision rests on review alone.

## Staying on track

| Check | Enforced by | State |
| --- | --- | --- |
| A simulation change has a test, and the author shows that it failed first | `.claude/rules/sim.md` as guidance, then pull request review; `sim-reviewer` checks coverage but cannot see commit order from the code alone | Manual |
| Large features start from a plan citing the GDD section and ADRs | The person approving the plan | Manual |
| Simulation tests pass headlessly in CI | CI job from [ADR-0021](0021-ci-on-github-actions.md) | Pending (needs the test runner from [ADR-0019](0019-test-framework.md), the first tests, and CI) |
| Claude cannot finish a turn with failing tests, within the documented continuation cap | Stop hook described in [ADR-0016](0016-claude-code-config-as-worked-example.md) | Pending (needs the headless test command and the content validator that the GDD also names for this hook) |
| GDScript parses on the pinned engine, which catches some Godot 3 syntax but not all of it | CI parse check named in the GDD's risk table | Pending (needs game code and CI) |
| Visual changes come with a windowed screenshot that has been inspected | Pull request review | Pending (needs a main scene, since `project.godot` has none, and a capture method) |

**Drift signals.** A commit adds or changes a rule under `sim/` with no change under `tests/`. A test is deleted, skipped or loosened in the same change that makes it pass. A test needs a display, a scene tree or a `Node`. A pull request for `scenes/` or `ui/` claims success with no screenshot. A long feature appears with no plan that cites its GDD section. The test runner lands and `CLAUDE.md` still has no test command.

**Revisit when.** [ADR-0019](0019-test-framework.md) is superseded in a way that changes how rules can be run headlessly, simulation tests stop being fast enough to run on every change, test-first proves unworkable for numeric tuning, or visual defects repeatedly get past screenshot inspection.
