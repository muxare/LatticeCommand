# ADR-0003: All game code is written in typed GDScript for Godot 4, never C# and never Godot 3 APIs

| | |
| --- | --- |
| **Status** | Accepted, amended by [ADR-0022](0022-claude-config-guards-worktrees-and-fails-closed.md) |
| **Date** | 2026-11-04 |
| **Deciders** | Mikael Axelsson |
| **Sources** | `lattice-command-gdd.md` ("Language: GDScript or C#", "CLAUDE.md essentials", "Risks"); `CLAUDE.md` ("Code conventions"); Godot 4.7 documentation, [C#/.NET](https://docs.godotengine.org/en/stable/tutorials/scripting/c_sharp/index.html), [Exporting for the Web](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html) and [Static typing in GDScript](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/static_typing.html), read 2026-11-04 |
| **Related** | [ADR-0001](0001-record-architecture-decisions.md), [ADR-0002](0002-godot-4-as-engine.md), [ADR-0004](0004-compatibility-renderer-single-threaded-web.md), [ADR-0005](0005-three-layer-split.md) (three-layer split), [ADR-0019](0019-test-framework.md) (test runner), [ADR-0021](0021-ci-on-github-actions.md) (CI on GitHub Actions), [ADR-0022](0022-claude-config-guards-worktrees-and-fails-closed.md) |

## Context

Godot 4 offers two mainstream languages, and the choice is expensive to reverse because the simulation core, the presentation layer and the tests would all be written in it. C# has the stronger tooling and the better representation in training data, so on agent fluency alone it would win. What decides the matter is distribution. This is a learning game that people should be able to try with one click, which makes a playable web build important, and the official Godot 4.7 documentation states that projects written in C# cannot be exported to the web.

Choosing GDScript brings a specific hazard of its own. Models sometimes write Godot 3 syntax, and much of that code looks plausible on a first read. Static typing is also optional in GDScript, and the engine's warnings about untyped code are off by default, so without a rule the code would slowly lose its types.

## Decision

Game code is written in GDScript. This was decided on 2026-11-04, because a playable web build matters and C# has no official web export in Godot 4.

Code must use typed GDScript and Godot 4 constructs, namely `@export`, `signal` syntax and `Callable`. Code must not use Godot 3 APIs or syntax. C# files must not be added, and the project must stay on the standard Godot build, which the documentation confirms has no C# support built in.

Simulation classes are RefCounted classes in GDScript, as `CLAUDE.md` states; the boundary itself belongs to [ADR-0005](0005-three-layer-split.md).

**Open point.** The sources require "typed GDScript" and the GDD says typing is enforced "by convention", but neither says how strict that is. It is undecided whether every declaration needs an explicit type or whether inference with `:=` is acceptable, and whether the `UNTYPED_DECLARATION` warning should be switched on in `project.godot`. It is not switched on as of 2026-11-04. The choice between GUT and gdUnit4 is not open: [ADR-0019](0019-test-framework.md) settles it with a small in-repo test runner and no third-party framework yet.

## Alternatives considered

**C# on the .NET build of Godot.** C# offers full static typing, mature tooling, excellent model fluency, and a simulation core that could be a plain class library tested with xUnit or NUnit with no engine at all. It lost because of the web export alone. The GDD records that C# would only have made sense for a desktop-only release with a team stronger in .NET. The documentation's own suggestion for C# on the web is to use Godot 3, which the project rules out.

## Consequences

The web build stays possible with an official toolchain, iteration needs no compile step, and the standard engine build is enough for development, CI and export.

The costs follow directly from what C# would have given. Typing rests on convention and review rather than on the compiler, and tooling is less mature. Simulation tests need the Godot executable, even though the simulation has no nodes, because its classes are GDScript and RefCounted. Agents need a standing rule to keep them out of Godot 3 syntax, and the GDD rates that drift as a medium likelihood with low impact. A parse check will catch only what the 4.7 parser rejects, so it will not catch every outdated pattern or a missing type, and review remains necessary.

## Staying on track

| Check | Enforced by | State |
| --- | --- | --- |
| Every Claude Code session is told to use typed GDScript and never Godot 3 APIs | `CLAUDE.md`, "Code conventions"; this instructs and does not block | Active |
| Sessions touching `scenes/**` or `ui/**` get the same rule again | `.claude/rules/scenes.md`; `.claude/rules/sim.md` does not repeat it, so `sim/**` and `tests/**` rely on `CLAUDE.md` alone. [ADR-0022](0022-claude-config-guards-worktrees-and-fails-closed.md) amends this, because `sim.md` now repeats the rule, so only `tests/**` relies on `CLAUDE.md` alone. | Active |
| Declarations are typed and no Godot 3 pattern gets through | Pull request review | Manual |
| No C# source or .NET project file enters the repository | Pull request review | Manual |
| All GDScript parses on the pinned engine | The CI parse check named in the GDD's risk table | Pending (needs CI, [ADR-0021](0021-ci-on-github-actions.md)) |
| The engine reports untyped declarations | `UNTYPED_DECLARATION` warning in `project.godot` | Pending (needs the open point above decided, and game code) |

**Drift signals.** A diff contains `yield(`, `export var`, `onready var`, `setget`, `connect("signal_name", self, "method")` or `KinematicBody`. A `.cs`, `.csproj` or `.sln` file appears, or `project.godot` gains a `[dotnet]` section. New functions or variables lack type annotations, or a change disables a typing warning. CI moves to the .NET build of Godot. A plan proposes a C# simulation library as a fresh idea without a superseding ADR.

**Revisit when.** The official Godot documentation states that C# projects can be exported to the web, or the project gives up the web build. The second could follow from the GDD's open question about platform. In either case the reason C# lost has gone, and the decision should be reopened rather than left standing by inertia. A mature codebase may still make staying the right answer.
