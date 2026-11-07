# ADR-0002: Lattice Command is built on Godot 4, pinned at the 4.7.2 standard build

| | |
| --- | --- |
| **Status** | Accepted, amended by [ADR-0022](0022-claude-config-guards-worktrees-and-fails-closed.md) |
| **Date** | 2026-11-04 |
| **Deciders** | Mikael Axelsson |
| **Sources** | `lattice-command-gdd.md` ("Technology: engine, language and architecture", in particular "Why Godot 4" and "Alternatives considered"; "CI with Claude Code"; "Open questions"); `CLAUDE.md` ("Tools", "Code conventions") |
| **Related** | [ADR-0001](0001-record-architecture-decisions.md), [ADR-0003](0003-typed-gdscript.md), [ADR-0004](0004-compatibility-renderer-single-threaded-web.md), [ADR-0017](0017-test-first-headless-verification.md) (test-first and headless verification), [ADR-0018](0018-vertical-slice-gate-and-scope.md) (vertical slice gate), [ADR-0021](0021-ci-on-github-actions.md) (CI on GitHub Actions), [ADR-0022](0022-claude-config-guards-worktrees-and-fails-closed.md) |

## Context

Lattice Command is a 3D grand strategy game for a team of two or three, with Claude Code doing most of the implementation over about nine months. The engine therefore has to suit an agent as well as a person. An agent can only review and repair what it can read as text, and it can only trust its own work if it can run that work without a display. The game also carries a heavy load of panels, because most decisions happen in 2D over a 3D scene, and it needs enough real 3D to show delegation and data flow as movement in space.

Nearly every later choice rests on the engine, so changing it midway would discard most of the code. A version pin matters as well, because web export templates must match the engine version exactly and a routine `brew upgrade` can move the installed version without anyone deciding to.

## Decision

The game is built on Godot 4. The pinned build is 4.7.2, reported as `4.7.2.stable.official.ed1daf0bf`, in its standard form and not the .NET form, at `/Applications/Godot.app/Contents/MacOS/Godot`.

Scripts and CI must use the pinned build. A version change must update the pin in `CLAUDE.md`, CI and the export templates together, because templates that do not match the engine cannot be used.

Tests and exports must be runnable with `--headless`, so that work can be verified without a display.

**Open point.** The GDD leaves open which parts of a colleague's existing Godot project can be reused, and which storefronts the game ships on. Neither is decided here.

## Alternatives considered

**Unity (C#).** Unity has mature 3D, a huge asset store and strong C#. It lost because its scene and prefab files are noisy YAML that Claude Code edits poorly, its editor is heavier, and the GDD counts its licensing history against it.

**Unreal Engine.** Unreal has the best 3D of the options. It lost because Blueprints and assets are binary, so an agent cannot read or diff them, because C++ build times slow every iteration, and because it is far more engine than a stylized low-poly game needs.

**Bevy (Rust).** Bevy's code-only ECS is well suited to Claude Code and to determinism, and it came closest on those two forces. It lost because it has no editor, its UI story is young in a game that lives in panels, and the team would face a steeper learning curve.

**Three.js or Babylon.js (TypeScript).** These run everywhere in a browser, and The Quiet Oracle prototype was already built this way. They lost because the team would have to build its own UI framework, scene editing, save system and input handling, which is a costly burden given a strategy game's UI load.

## Consequences

Scenes, resources, scripts and project settings are plain text, so Claude Code can read and edit nearly everything and every change appears in a normal code review. Headless mode lets an agent run tests and exports itself. Control nodes, themes and containers suit the panel-heavy interface, the engine is open source and carries no royalties, and a colleague's Godot experience reduces the learning risk.

The costs are real. Godot's 3D is weaker than Unreal's or Unity's, and the web target narrows it further, as [ADR-0004](0004-compatibility-renderer-single-threaded-web.md) records. Whether it can carry the stylized look is still unproven and rests on the vertical slice. The asset ecosystem is smaller than Unity's. A pinned build also adds upkeep, because `brew` installs the engine on this machine and an upgrade can invalidate the pin and the installed web templates at once. Note that `project.godot` names only the feature version 4.7, so the patch-level pin lives in `CLAUDE.md` alone until CI repeats it.

The GDD's opening line for this section still reads "Recommendation", while `CLAUDE.md` calls Godot 4 a decision made on 2026-11-04. This ADR follows `CLAUDE.md` and treats the choice as made.

## Staying on track

| Check | Enforced by | State |
| --- | --- | --- |
| Agents cannot Edit or Write engine-generated files under `.godot/`, `build/` or `*.import` | PreToolUse hook `.claude/hooks/deny-generated-edits.sh`, which does not cover Bash or, as [ADR-0016](0016-claude-code-config-as-worked-example.md) records, paths inside a worktree. [ADR-0022](0022-claude-config-guards-worktrees-and-fails-closed.md) amends this, because the hook now judges each path from the root of the checkout holding it, so paths inside a worktree are denied too. | Active |
| The installed engine reports the pinned version before a version-sensitive change | `godot --version` compared with `CLAUDE.md` by the person making the change | Manual |
| CI runs the Godot version string that `CLAUDE.md` pins | GitHub Actions workflow | Pending (needs CI, [ADR-0021](0021-ci-on-github-actions.md)) |
| Simulation tests run headlessly on the pinned build | Headless test command | Pending (needs the test runner, [ADR-0019](0019-test-framework.md), and game code) |
| The web export succeeds on the pinned build in CI | GitHub Actions workflow | Pending (needs CI, [ADR-0021](0021-ci-on-github-actions.md)) |

**Drift signals.** A diff changes the pin in `CLAUDE.md` without changing CI, or the reverse. `godot --version` prints something other than the pinned string. A binary `.scn` or `.res` file appears in a diff where a text `.tscn` or `.tres` would do, which erodes the reason Godot won. A `.csproj` or `.sln` appears, which would mean the .NET build has crept in. A feature ships with no way to verify it headlessly and no windowed screenshot check.

**Revisit when.** The vertical slice shows that Godot cannot deliver a legible 3D presentation at acceptable performance, or a Godot upgrade removes a capability the project depends on, such as the web export or headless mode. A new patch or minor version alone does not reopen this decision; it only moves the pin.
