# ADR-0014: Every shipped asset comes from one Blender Python script, and its committed `.glb` is never edited by hand

| | |
| --- | --- |
| **Status** | Accepted |
| **Date** | 2026-11-04 |
| **Deciders** | Mikael Axelsson |
| **Sources** | `lattice-command-gdd.md` ("Art pipeline: Blender driven by Claude Code", including "Conventions" and "Limits and safety"; "Visual style"; "Repository layout"); `CLAUDE.md` ("Art pipeline", "Tools") |
| **Related** | [ADR-0015](0015-live-blender-mcp-exploration-only.md), [ADR-0016](0016-claude-code-config-as-worked-example.md), [ADR-0021](0021-ci-on-github-actions.md) |

## Context

The game needs stations, hulls, docking rings, port gates and modular parts from a small team in which Claude Code does most of the implementation. Blender's Python API lets Claude Code build and export those models without anyone opening the Blender UI, and the GDD judges Claude strong at procedural hard-surface work and weak at organic work. A model saved by hand from a scene cannot be reviewed as text or rebuilt when a convention changes, so nobody could say with confidence how it was made. At the same time, everyone who builds the game should not need Blender installed. The pipeline therefore has to give a reproducible source and a ready-to-use output, and it has to say which of the two may change directly.

## Decision

Each shipped asset has exactly one Python script in `art/scripts/`, and that script exports one binary glTF file to `art/models/`. Scripts run headlessly on the build pinned in `CLAUDE.md`, which is Blender 5.2.3 LTS at `/Applications/Blender.app/Contents/MacOS/Blender`, and the export must have transforms applied and metric scale. Nothing may ship from a hand-saved scene.

The generated `.glb` files must be committed so that the game builds without Blender. They must be regenerated whenever their script changes and must never be edited directly, because a model changes only by changing its script.

Files are named by kind and variant, such as `hull_frigate_a.glb`, and collision meshes use Godot import suffixes such as `-col`. Materials are named after the palette so that Godot can swap them per colony: Harbour amber, Conclave teal, Shipyard orange and Concord violet.

Advisor characters and creatures are outside scripted modelling, and they must be modelled by hand or bought.

**Open points.** The sources state both that every shipped asset comes from a script and that characters are modelled by hand or bought, and they do not say how a hand-made or bought asset is stored, named or reconciled with the first rule. The GDD's list of what "every shipped asset" means names only hard-surface parts, which suggests the rule was written with those in mind, but no source settles it. The palette names only three of the colony types listed under "Setting and fiction", so the material names for the Admiralty, the Night Relay and the optional Assay Works are undecided, as is the exact spelling of a material name inside a file. Finally, the GDD says that scripted mode runs in the same sandboxed container as CI, but its list of CI jobs has no regeneration step, and no source says whether Blender's output is byte-for-byte reproducible.

## Alternatives considered

The sources record the rule without listing rejected options, so these were considered while writing this ADR. **Hand-modelling every asset and saving scenes** would suit organic work, but it gives up the reproducibility the GDD asks for, and "nothing ships from a hand-saved scene" excludes it for hard-surface assets. **Generating the `.glb` files at build time and leaving them out of git** would keep binaries out of the repository, but it would require Blender for every build, which contradicts the stated reason for committing them. **Shipping results from live MCP sessions** is ruled out separately in [ADR-0015](0015-live-blender-mcp-exploration-only.md).

## Consequences

A style or scale change becomes a script change followed by a rebuild, and Claude Code can work on art with the same tools it uses for code. A checkout can build and export the game without Blender.

The costs are real. Every regenerated model adds a binary to git history, and the repository uses no Git LFS, only a `binary` attribute in `.gitattributes`, so the repository will grow. A binary diff cannot be read, so review has to rest on the script and on looking at the result. Script and output can fall out of step without anything noticing until CI exists. Scripted modelling also limits the look to what procedural hard-surface work can reach, and characters need a person's time or a purchase budget.

## Staying on track

| Check | Enforced by | State |
| --- | --- | --- |
| Edit and Write calls on `art/models/**` are denied | `.claude/hooks/deny-generated-edits.sh` through PreToolUse; sample JSON piped in on 2026-11-04 was denied for top-level and nested model paths and allowed for `art/scripts/`, with the worktree limit recorded in [ADR-0016](0016-claude-code-config-as-worked-example.md) | Active |
| `.glb` files are stored as binary and are not ignored | `.gitattributes` and `.gitignore`; confirmed with `git check-attr` and `git check-ignore` on 2026-11-04 | Active |
| Every `.glb` in `art/models/` has one script, and every script has one `.glb` | CI job from [ADR-0021](0021-ci-on-github-actions.md) | Pending (needs CI and the first asset script) |
| Rerunning a script on the pinned Blender reproduces the committed model | CI job from [ADR-0021](0021-ci-on-github-actions.md) | Pending (needs CI, and an answer on whether Blender's export is reproducible) |
| File names, import suffixes and material names follow the conventions | `.claude/rules/art.md` as guidance, then pull request review | Manual |
| Characters and creatures are not forced through scripted modelling, and no hard-surface asset arrives without a script | Pull request review | Manual |

**Drift signals.** A pull request changes a `.glb` without changing its script, or changes a script without changing its `.glb`. A `.blend` file appears in a commit, since `.gitignore` covers only `.blend1` backups. A shell step writes into `art/models/` by any route other than running Blender on a script. A material arrives named `Material.001` rather than after the palette. One script exports several models, or a file name such as `hull_frigate_a_final.glb` appears. A pull request that regenerates a model states a Blender version other than the pinned 5.2.3.

**Revisit when.** The vertical slice shows that scripted models cannot carry the intended look, the size of committed binaries makes cloning or CI noticeably slow, or hand-made and bought assets become common enough that the open point above needs its own decision.
