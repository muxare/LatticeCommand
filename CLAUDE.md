# Lattice Command

Lattice Command is a 3D grand strategy game in which the player runs an autonomous logistics network that keeps a star cluster's colonies alive against a rival power. Players learn the Claude Certified Architect – Foundations (CCA-F) content without studying, because the game's rules are the certification's concepts.

The design source of truth is `lattice-command-gdd.md`, and this file only distils what is needed on every task. Read the relevant GDD section before implementing a feature, and cite it in the plan. If the GDD turns out to be wrong during implementation, record the correction there instead of quietly building something else.

Architecture decisions are recorded in `docs/adr/`, with an index and the state of their checks in its `README.md`. A plan for a large feature cites the ADRs it touches, and a change that conflicts with an Accepted ADR must come with a superseding one.

## Picking up where we left off

`docs/next.md` is the handoff between sessions, so that a cleared context loses nothing. Update it every time you stop, before writing your final message, unless nothing in it has changed. It must say where the work stands (branch, what is committed, what is not), what is next in order, and what is waiting on a person. Keep it to the current state and remove what is finished, because git history and the ADRs hold the past. It is imported below, so start from it when a session opens.

@docs/next.md

## Project status

The project structure and Claude Code setup are in place, but there is no game code, content or test runner yet. The first milestones are a two-week paper prototype and then an eight-week vertical slice (one Harbour colony in 3D, ship's log, refit menu, interlocks, three Concord doctrines, and the onboarding trimmed to that one colony). The slice is the go/no-go point, so do not build the strategy layer ahead of it.

## Tools

**Blender 5.2.3 LTS** is pinned at this path, and scripts and CI should use the same build:

```
/Applications/Blender.app/Contents/MacOS/Blender
```

Build an asset headlessly, with no Blender UI, by running its script:

```
/Applications/Blender.app/Contents/MacOS/Blender --background --python art/scripts/<asset>.py
```

**Godot 4.7.2** (`4.7.2.stable.official.ed1daf0bf`, the standard build rather than the .NET one) is the engine, pinned at this path. It was installed with `brew install --cask godot`, which also links it as `godot` on the PATH, and a later `brew upgrade` can change the version, so update this pin and CI together if that happens:

```
/Applications/Godot.app/Contents/MacOS/Godot
```

Use `--headless` for tests and exports so that work can be verified without a display:

```
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script <script>.gd
```

The web export templates are installed in `~/Library/Application Support/Godot/export_templates/4.7.2.stable/`, taken from the official `Godot_v4.7.2-stable_export_templates.tpz` and limited to the `web_*` files. Templates must match the engine version exactly, so a Godot upgrade needs a new set, and exporting to another platform means installing that platform's files from the same archive.

Export the web build with the command below. The `build/web/` directory must exist first, and the exported build cannot run until the project has a main scene:

```
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --export-release Web build/web/index.html
```

Commands for running tests, validating content and running a seeded simulation should be added here as soon as they exist.

## Architecture

The split into three layers is the most important technical decision in the project, because it lets every rule be tested headlessly and makes any bug report replayable from one seed and a command list.

1. **Simulation core (`sim/`).** Pure logic for colonies, craft, tool calls, incidents, resources and the Concord. It is deterministic and seeded, and it has no nodes, rendering or engine calls. In GDScript these are RefCounted classes.
2. **Content as data (`content/`).** Incidents, doctrines, tech nodes and the fact sheet are JSON files validated by a JSON Schema in CI, so content can be added without touching code.
3. **Presentation (`scenes/`, `ui/`).** Godot scenes subscribe to simulation events and draw them. Presentation never changes simulation state directly; it sends commands.

The game does not call the Claude API during play. The simulation models Claude's behaviour, which keeps the game deterministic, offline and free to run. Multiplayer and procedurally generated incidents are also out of scope for 1.0.

## Code conventions

This is Godot 4 with GDScript, a decision made on 2026-11-04 because a playable web build matters and Godot's documentation says that C# projects "currently cannot be exported to the web" in Godot 4. Use typed GDScript, `@export`, `signal` syntax and `Callable`, and never Godot 3 APIs.

The project uses the Compatibility renderer because it is the only one Godot supports on the web. The web preset exports single-threaded, which Godot's documentation prefers because it needs no special server headers.

Write the failing simulation test first and then the code. Start large features in plan mode. Headless tests cannot judge a UI, so for visual work run the game windowed, capture a screenshot and inspect it.

## Teaching rules that constrain the code

The accuracy of the simulation is the product, because a wrong rule teaches a wrong exam answer.

- **The simulation behaves like the real system.** A PostToolUse interlock can never stop an action, a subagent knows nothing of the parent conversation except its delegation message (a fork is the exception and inherits the whole conversation), and a batch can take up to 24 hours and expires if processing has not finished by then.
- **Real terms stay visible.** Fiction names sit on top, but every tooltip, menu and log line carries the real term, for example "Interlock" with "PreToolUse hook".
- **A craft's ship's log is its literal message history plus each response's stop_reason.** It shows every tool_use, tool_result and stop_reason, in order.
- **Consequences are delayed and traceable.** Damage surfaces later, as an event scheduled at an absolute tick, which on the strategic layer means several turns after the decision ([ADR-0020](docs/adr/0020-fixed-step-clock-and-numerics.md)), and the incident log always shows the causal chain back to the decision. Only a fix at the causal layer closes an incident; a fix at the wrong layer appears to work and then recurs.
- **Distractors are tempting moves.** The exam's recurring wrong answers are cheap, attractive options that work just often enough to tempt and fail when it matters. The ten Hollow Concord doctrines are Plea, Mirror, Latewatch, Envoy, Liar, Tower, Brute, Scroll, Hand and Silencer.
- **The game never quizzes during play.** Nothing interrupts a crisis, the exam bridge uses no vocabulary that play has not already taught, and speed is never rewarded over reading the log.

The GDD's content mapping tables are the contract between game systems and certification concepts, and the share of incidents per domain follows the exam weights: D1 Agentic architecture 27%, D2 Tools and MCP 18%, D3 Claude Code configuration 20%, D4 Prompts and structured output 20%, D5 Context and reliability 15%.

## Content and fact accuracy

Every technical claim lives in `content/facts.json`, with an `id`, a one-sentence `claim`, an official-docs `source` URL, a `verified` date and a `verifier`, which record when a person approved the entry and who, the `domains` it supports and the feature-name `terms` it backs. A subagent never counts as the `verifier`. Incidents, tooltips and after-action reports reference fact ids and never carry free text about features, and no feature name may appear in content without a fact-sheet entry. Do not write a claim about a Claude feature from memory; check it against the current documentation. The main session drafts each entry from the current official documentation, the `fact-checker` subagent verifies it, and a person approves it, so no agent writes an entry from memory.

Each incident file holds the scenario, the colony type, the domain and task statement, the solution (one correct order, or one set of orders needed together, never alternatives), three or four tempting wrong orders each tagged with its doctrine, the delayed consequence of each wrong order, fact ids and the exam-format rewrite for the after-action report. Incidents are hand-authored and original, must not reproduce real exam items, and need approval from a person who has studied for the certification. AI drafts; humans sign off.

## Art pipeline

Every shipped hard-surface asset comes from a script in the repo, and nothing ships from a hand-saved scene. Hand-made and bought assets, such as advisor characters, are listed in `art/third-party.md` with their author or vendor, source, licence and the storage location of their source file. Those source files stay in private storage outside this public repository, which holds only exports whose licence permits public redistribution (ADR-0024). Each asset has one Blender Python script in `art/scripts/` that exports a `.glb` to `art/models/`.

- **Exports.** Use binary glTF (`.glb`) with transforms applied and metric scale.
- **Names.** Name files by kind and variant, such as `hull_frigate_a.glb`, and use Godot import suffixes such as `-col` for collision meshes.
- **Materials.** Name materials after the palette so Godot can swap them per colony: Harbour amber, Conclave teal, Shipyard orange, Concord violet.
- **Generated files.** Commit the `.glb` files so the game builds without Blender, regenerate them whenever a script changes, and never edit them directly.
- **Style.** The look is stylized low-poly sci-fi with a strong rim light, and legibility comes first. Scripted modelling suits hard-surface assets such as stations, hulls, docking rings and port gates; advisor characters and creatures are modelled by hand or bought.

Live Blender sessions over MCP are for exploring a look before freezing it, and a live session must end with the script that reproduces the result. MCP servers run Claude-written Python inside Blender, so use live mode only on a machine without sensitive data or in a virtual machine. Setup steps are in the GDD under "Setting up live mode (macOS)".

## Claude Code setup

The project's Claude Code configuration is itself a worked example of Domain 3, and the GDD's "Building it with Claude Code" section specifies it. Verify frontmatter fields, hook event names and settings keys against the current documentation when changing them.

- **Hooks.** PreToolUse denies Edit and Write on `.godot/`, `build/`, `*.import` and `art/models/**`. It judges each path from the root of the checkout holding the file, so worktrees are covered, and it denies when it cannot judge a path or when `jq` or `realpath` is missing. Its handler sets `"onFailure": "block"`, so a hook that cannot start, crashes or times out also denies, which needs Claude Code v2.1.295 or later. It does not cover Bash, which is how generated files get regenerated. Two hooks wait for tooling that does not exist yet: PostToolUse on `content/**` needs the content validator, and Stop needs the headless test command and the content validator. Add each one with its tool, using absolute paths through `$CLAUDE_PROJECT_DIR`.
- **Path-scoped rules in `.claude/rules/`.** `sim.md`, `content.md`, `scenes.md` and `art.md`.
- **Skills in `.claude/skills/`.** `add-incident`, `balance-check` and `fact-check`. `balance-check` cannot run until the seeded simulation runner exists.
- **Subagents in `.claude/agents/`.** `content-writer`, `sim-reviewer` and `fact-checker`.
- **Codex mirrors.** `AGENTS.md` mirrors this file, `.agents/skills/` mirrors the skills and `.codex/agents/` mirrors the subagents, with the same names and instructions. This file is the source, and a change to it or to a skill or subagent is made in its mirror in the same commit.
- **MCP.** `.mcp.json` does not exist yet, because live Blender mode has not been set up.
