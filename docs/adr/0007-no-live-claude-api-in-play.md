# ADR-0007: The game models Claude and never calls it during play

| | |
| --- | --- |
| **Status** | Accepted |
| **Date** | 2026-11-04 |
| **Deciders** | Mikael Axelsson |
| **Sources** | `lattice-command-gdd.md` ("Out of scope for 1.0", "Risks and open questions", "CI with Claude Code"); `CLAUDE.md` ("Architecture") |
| **Related** | [ADR-0005](0005-three-layer-split.md), [ADR-0006](0006-deterministic-seeded-replay.md), [ADR-0008](0008-simulation-fidelity.md), [ADR-0011](0011-hand-authored-incidents-human-signoff.md), [ADR-0018](0018-vertical-slice-gate-and-scope.md), [ADR-0021](0021-ci-on-github-actions.md) |

## Context

A game about operating Claude invites the obvious idea of having Claude run the craft. It would look authentic, and it would spare the project from writing a model of Claude's behaviour. It would also make every playthrough depend on a network connection, an API key and a running cost, none of which fit a learning game meant to be tried with one click, and it would make outcomes vary from one run to the next. Exact replay ([ADR-0006](0006-deterministic-seeded-replay.md)) and the teaching guarantee that only the causal fix closes an incident ([ADR-0008](0008-simulation-fidelity.md)) both need outcomes that the project controls.

## Decision

The game must not call the Claude API during play. The simulation models Claude's behaviour, which keeps the game deterministic, offline and free to run. Shipped code in `sim/`, `scenes/` and `ui/` must not contain an API client, an API key, a request to a Claude endpoint, or a setting that asks a player for a key.

Hull classes, tool choices and every other Claude behaviour in the game are rules in the simulation, whose results come from the seed and commands and not from inference. Incidents are hand-authored ([ADR-0011](0011-hand-authored-incidents-human-signoff.md)) and are not generated at runtime.

This decision covers play. Claude Code building the game, the planned review action and the planned nightly fact-checker run are development activities that use Claude outside the shipped game, so they are unaffected.

The sources state this as out of scope for 1.0, so it does not bind any version after that. They also leave some edges open. "Offline" clearly means that play needs no Claude and no API, but a web build must still be downloaded, and whether it must work with no connection after loading is undecided. So is whether the game may make other network calls, such as telemetry. How a player's standing orders are expressed is also open: nothing can evaluate free text during play, so whatever form they take has to be something the simulation can score.

## Alternatives considered

**Live calls during play.** This is the option the GDD names and rules out for 1.0. It would give real model behaviour and spare the project the modelling work, and it lost on all three stated grounds: it breaks determinism, requires a connection, and costs money for every player.

The sources do not record any other alternative, such as a mode that is optional or that replays recorded model output.

## Consequences

The game can be played for free by anyone, a run can be replayed, and tests need no key or network, which keeps verification fast in CI and in Claude Code sessions. There is no per-player cost and no dependence on an API's availability or on a model version changing under a shipped lesson.

The price is that every behaviour the game shows must be authored and kept correct by hand. A modelled Claude can go stale when the real one changes, and nothing in play will reveal that, which is why [ADR-0008](0008-simulation-fidelity.md) and the fact sheet carry so much weight. The GDD also lists as a risk that simulated behaviour feels fake to experts, and it mitigates that by basing each incident's behaviour on a documented failure mode and citing it. Players never see a real model's variability, and they cannot try an idea the authors did not anticipate.

## Staying on track

| Check | Enforced by | State |
| --- | --- | --- |
| No network or API use enters `sim/` in a diff | `sim-reviewer` subagent, whose engine-call check catches network classes there; invoked by hand | Manual |
| No API client, key or Claude endpoint enters `scenes/` or `ui/` | Pull request review by a person; `sim-reviewer` does not cover these directories | Manual |
| The network and API pattern below finds nothing in shipped code | A CI grep step | Pending (needs CI, [ADR-0021](0021-ci-on-github-actions.md)) |
| A web build plays through with the network cut after loading | Manual playtest or scripted run | Pending (needs a main scene and the vertical slice, [ADR-0018](0018-vertical-slice-gate-and-scope.md); the requirement itself is open, see Decision) |

**Drift signals.** `grep -rnE 'HTTPRequest|HTTPClient|WebSocketPeer|StreamPeerTCP|JavaScriptBridge|api\.anthropic\.com|ANTHROPIC_API_KEY' --include='*.gd' sim/ scenes/ ui/` finds anything. An options screen gains a field for an API key. `project.godot` or `export_presets.cfg` gains a key or an endpoint. A plan proposes "just one" live feature, such as a hint or an advisor line written by Claude. The same seed and commands give different text in a log.

**Revisit when.** Planning begins for a version after 1.0, or playtests show that the modelled behaviour fails to teach or is rejected by experts as fake despite cited failure modes. A change must still answer how it would preserve replay, cost and offline play, or say plainly which of them it gives up.
