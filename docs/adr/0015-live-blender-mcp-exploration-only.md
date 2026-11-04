# ADR-0015: Live Blender sessions over MCP only explore a look, and each must end with the script that reproduces it

| | |
| --- | --- |
| **Status** | Accepted |
| **Date** | 2026-11-04 |
| **Deciders** | Mikael Axelsson |
| **Sources** | `lattice-command-gdd.md` ("Art pipeline: Blender driven by Claude Code", "Setting up live mode (macOS)", "Limits and safety"); `CLAUDE.md` ("Art pipeline", "Claude Code setup") |
| **Related** | [ADR-0014](0014-scripted-blender-art-pipeline.md), [ADR-0016](0016-claude-code-config-as-worked-example.md) |

## Context

Materials and lighting are hard to judge blind. Driving a running Blender through an MCP server lets Claude inspect the scene and take viewport screenshots, which makes it useful for finding a look. That same freedom creates two problems. A scene reached through a live conversation cannot be rebuilt, which would undo the scripted pipeline in [ADR-0014](0014-scripted-blender-art-pipeline.md). And both candidate servers run Python that Claude writes inside Blender, the official one with no guards, so a live session can touch whatever the machine can reach.

## Decision

Live mode must be used only to explore a look, such as tuning materials and lighting, before the result is frozen. A live session must end with Claude writing the script that reproduces the result, and that script and its generated model are what the project keeps. Nothing may ship from a live session's scene.

Live mode must run only on a machine without sensitive data or in a virtual machine.

The server is chosen as the GDD describes. The community server MCP for Blender, by Siddharth Ahuja, is the one to set up because it has a documented Claude Code setup. Blender Lab's own server is the official alternative, and the project switches to it once its documentation has a Claude Code command, because Blender developers maintain it. On 2026-11-04 the Blender Lab page still listed no Claude Code command, so the condition has not been met. That page does confirm the requirement of Blender 5.1 or newer, which the pinned 5.2.3 build satisfies, and it recommends a virtual machine because the server has no guards.

`.mcp.json` does not exist yet, because live mode has not been set up. When it is, one person adds the server once at project scope with the GDD's command and commits the file, and each team member installs `uv` and the add-on and starts the server on their own machine.

**Open points.** The sources do not say who judges that a machine has no sensitive data, whether an ordinary development machine with Claude Code credentials and this repository qualifies, or how a virtual machine should be set up. They do not say how anyone records that a session ended with its script. The GDD's command, `uvx mcp-for-blender`, names no version, and whether to pin one is undecided.

## Alternatives considered

The sources compare the two servers but state no other rejected options, so the rest were considered while writing this ADR. **Starting on the official server now** has the advantage of who maintains it, but it lost on the GDD's stated ground that its documentation has no Claude Code command. **Having no live mode** would remove the risk altogether, but it would give up viewport feedback at exactly the stage where the GDD wants it. **Letting a good live result ship directly** would save a step, but it would break the rule that every shipped asset can be rebuilt from a script. **Using live mode freely on a normal machine** fails because both servers run Python that Claude writes inside Blender, the official one with no guards.

## Consequences

A look can be explored quickly and then kept in a form the pipeline accepts, so exploring costs no reproducibility. The team does not depend on any server for shipped work, and a session that goes wrong loses only exploration.

The cost is friction: a separate machine or VM, a running Blender with its server started, and the extra step of writing a script that may not capture every manual change on the first attempt. The rules are also mostly unenforceable. The PreToolUse hook matches only the Edit and Write tools, so Python running inside Blender through an MCP tool can write to `art/models/` without being stopped. Committing `.mcp.json` has a further effect: the MCP documentation says interactive sessions prompt for approval of project-scoped servers, but `claude -p` runs load them without asking, so any later headless job in this repository would need to take that into account.

## Staying on track

| Check | Enforced by | State |
| --- | --- | --- |
| A live session that produced something kept ends with its script, and no asset is justified by a scene alone | `.claude/rules/art.md` as guidance, then pull request review | Manual |
| Live mode runs only on a machine without sensitive data or in a VM | The person starting the session; nothing technical verifies it | Manual |
| The Blender Lab documentation is rechecked for a Claude Code command | The person setting up live mode or next working on it | Manual |
| `.mcp.json` holds the Blender server at project scope, using the agreed package | Pull request review of the file | Pending (needs `.mcp.json`, which needs live mode to be set up) |
| Every committed model can be rebuilt from its script, which is what would expose a model that came from a live session | CI job from [ADR-0014](0014-scripted-blender-art-pipeline.md) and [ADR-0021](0021-ci-on-github-actions.md) | Pending (needs CI and the first asset script) |

No check in this ADR is Active as of 2026-11-04, because live mode has not been set up.

**Drift signals.** A `.glb` arrives in a commit whose script does not reproduce it, or the pull request mentions a live session and has no script. A `.blend` scene is committed to preserve a look. A committed permission rule auto-approves `mcp__blender__*` tools. A headless or CI job starts depending on the Blender server. `.mcp.json` changes server without this ADR's condition having been met. A pull request or session note records a live session run on a machine that holds production credentials.

**Revisit when.** The Blender Lab documentation gains a Claude Code command, which triggers the switch already decided here and an update to the setup steps. Also revisit if either server gains or loses protections, the community server stops being maintained, or it becomes clear that scripts regularly fail to reproduce what a live session found.
