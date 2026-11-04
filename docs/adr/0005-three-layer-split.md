# ADR-0005: The game is split into a simulation core, content as data and presentation, and presentation only sends commands and subscribes to events

| | |
| --- | --- |
| **Status** | Accepted, amended by [ADR-0020](0020-fixed-step-clock-and-numerics.md) |
| **Date** | 2026-11-04 |
| **Deciders** | Mikael Axelsson |
| **Sources** | `lattice-command-gdd.md` ("Architecture: three layers", "Learning design", "Repository layout", "CLAUDE.md essentials"); `CLAUDE.md` ("Architecture", "Teaching rules that constrain the code") |
| **Related** | [ADR-0006](0006-deterministic-seeded-replay.md), [ADR-0007](0007-no-live-claude-api-in-play.md), [ADR-0008](0008-simulation-fidelity.md), [ADR-0009](0009-content-as-validated-json.md), [ADR-0017](0017-test-first-headless-verification.md), [ADR-0019](0019-test-framework.md), [ADR-0020](0020-fixed-step-clock-and-numerics.md), [ADR-0021](0021-ci-on-github-actions.md) |

## Context

Lattice Command teaches a certification through its rules, so the rules are the product. A wrong rule teaches a wrong exam answer, and the project needs to find such a rule cheaply, repeatedly and without a person watching a 3D scene. Most of the implementation will also be done by Claude Code across many separate sessions, and those sessions can only verify their own work through checks that run without a display.

Godot pulls in the opposite direction. Its ordinary style places game logic in nodes, in `_process` callbacks and in scripts attached to scenes, which is convenient and quick to start with. Logic written that way needs a scene tree and frames to run, it mixes rule changes with drawing changes in one diff, and it lets a UI script change game state from anywhere. Once that has happened, no rule can be tested on its own, no bug can be replayed from a short description, and a change to an incident risks a change to the code.

The GDD calls this split "the single most important technical decision", because the claims that matter most about the project depend on it: that every rule is testable headlessly in milliseconds, that content authoring is safe, and that a bug report is one seed and a command list. Nearly every later ADR assumes it, so it would be very expensive to recover once the vertical slice has been built on something else.

## Decision

The game has three layers, and each has its own directories.

The **simulation core** lives in `sim/` and is pure logic for colonies, craft, tool calls, incidents, resources and the Concord. Its classes must extend RefCounted. They must not touch nodes, the scene tree, rendering, input or any engine singleton, and they must run headlessly with no scene tree. "No engine dependencies" has that specific meaning here: the code still runs on the Godot runtime in GDScript, and RefCounted is itself an engine class, so the rule is a boundary against the scene and runtime services and not a promise of portability to another engine.

**Content as data** lives in `content/`. Incidents, doctrines, tech nodes and the fact sheet are JSON files validated by a JSON Schema, so content can be added without touching code. The details belong to [ADR-0009](0009-content-as-validated-json.md).

**Presentation** lives in `scenes/` and `ui/`. Godot scenes subscribe to simulation events and draw them. Presentation must not change simulation state directly, and the only way it may affect the simulation is by sending a command. [ADR-0020](0020-fixed-step-clock-and-numerics.md) amends this wording and the single-input wording below, because presentation also calls `step()` to drive the clock, and `step()` carries no player decision. The simulation must report back through events and must not hold a reference to a node or know that anything is drawing it.

Commands are therefore the single input to the simulation and events its output. That is the boundary a reviewer checks a change against, and it is what makes [ADR-0006](0006-deterministic-seeded-replay.md) possible.

Several things are deliberately not decided here, because the sources do not decide them. The concrete shape of the command and event types is open, and so is how events are delivered, for example as Godot signals on a RefCounted object or as a queue that presentation drains. It is open whether presentation may read simulation state directly through a read-only view: the GDD forbids only changing it, while `.claude/rules/sim.md` says the simulation reports back "only through events". It is open which layer reads content files from disk, and whether non-singleton engine classes such as `JSON` or `FileAccess` count as permitted in `sim/`; [ADR-0020](0020-fixed-step-clock-and-numerics.md) settles the case of `RandomNumberGenerator`, which `sim/` must not use. The save format is open as well. The first plan that needs any of these must settle it and record the result.

## Alternatives considered

The sources give the reasons for the split but do not record a comparison, so the options below are the ones the split excludes, judged by the reasons the GDD gives.

**Game logic in nodes and scenes, the ordinary Godot style.** It is the fastest way to get something on screen and needs no command or event vocabulary. It lost because rules would then need a scene tree and frames to run, which rules out testing every rule headlessly in milliseconds, and a replay would have to reproduce rendering and input as well as rules.

**A shared state object that both layers read and write.** This keeps the separation of files while dropping the separation of authority, and it spares the cost of defining commands. It lost because a state change made by a UI script never passes through anything that can be recorded, so a seed and a command list would no longer describe a run.

**A simulation in a separate C# class library.** The GDD notes this as the natural form of the same split in C#, and it would have enforced the boundary at compile time. It lost with the language decision, because C# has no official web export in Godot 4. The boundary must therefore be held by convention and checks instead of by the compiler.

## Consequences

Every rule can be tested without a display, which is what allows Claude Code to verify its own work. Rule diffs, content diffs and visual diffs land in different directories and can be reviewed separately. Authors can add an incident without touching code. Replay, the balance-check skill and the regression tests all follow from having one input and one output.

The costs are real. Every player action needs a command and every visible result an event, so a change that would be one line in a node script now touches two layers and a vocabulary. Presentation cannot take shortcuts when it wants something quickly, including during the vertical slice, when the temptation will be strongest. GDScript offers no module boundary or compile-time guard for any of this, so until the planned checks exist the boundary rests on path-scoped rules and on review. Duplicated knowledge is also a risk, because presentation will want to predict outcomes in order to animate them, and any rule it copies can drift from the real one.

## Staying on track

| Check | Enforced by | State |
| --- | --- | --- |
| Sessions touching `sim/`, `scenes/` or `ui/` are told the boundary; this informs and does not verify | `.claude/rules/sim.md`, `.claude/rules/scenes.md` | Active |
| No engine calls enter `sim/` in a diff | `sim-reviewer` subagent, which is invoked by hand and has no hook | Manual |
| Presentation changes state only through commands | Pull request review by a person; `sim-reviewer` covers only the simulation core | Manual |
| The engine-call and state-assignment patterns below find nothing | A CI grep step | Pending (needs CI, [ADR-0021](0021-ci-on-github-actions.md)) |
| Every rule test runs headlessly with no scene tree | Headless test run | Pending (needs the test runner, [ADR-0019](0019-test-framework.md), and `sim/` code) |
| Content validates against its schema | Content validator, PostToolUse hook and CI | Pending (needs validator and schema, [ADR-0009](0009-content-as-validated-json.md)) |

**Drift signals.** In `sim/`, this pattern finds anything: `grep -rnE '\bextends +(Node|Control|Resource|CanvasItem)|\b(get_tree|get_node|add_child)\(|\b(Input|Engine|OS|Time|DisplayServer|RenderingServer)\.|\$[A-Za-z_"]' --include='*.gd' sim/`. A presentation script assigns to a simulation field, which `grep -rnE '\bsim\.[A-Za-z_.]+ *([-+*/]?=)[^=]' --include='*.gd' scenes/ ui/` finds as long as the reference is called `sim`; that name is illustrative until the command API exists. A rule lands in a scene script, or a scene script computes an outcome the simulation should have decided. A simulation test needs a scene, an autoload or a frame to pass. A new incident requires a code change. A bug report cannot be reproduced from its seed and command list.

**Revisit when.** The vertical slice shows that command and event traffic cannot support the incident layer's real-time presentation at acceptable effort, or the web build's performance cannot carry the separation. Either should reopen this decision with a superseding ADR, not lead to exceptions on the quiet.
