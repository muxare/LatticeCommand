# Lattice Command – Game Design Document

Nov 4, 2026 · Mikael Axelsson · Live version with diagrams: https://claude.ai/artifact/Fx6gfg3aWabrL4ujhWsyYt

## Vision

**Lattice Command is a 3D grand strategy game where you run an autonomous logistics network keeping a star cluster's colonies alive against a rival power. Players learn the Claude Certified Architect – Foundations (CCA-F) content without studying, because the game's rules are the certification's concepts.**

The model is Terra Invicta: players learn world geography because countries are the board. Here, agents, tools, hooks, context and delegation are the board.

Design pillars:

- **Real systems, real names.** The fiction is space logistics. The mechanics are called what they are called in Claude: subagent, tool\_choice, PreToolUse, CLAUDE.md, Message Batches.
- **Every exam distinction decides an outcome.** If the certification tests a difference (Grep vs Glob, project vs local scope), some mission fails when you get it wrong.
- **Late consequences, readable causes.** A misconfiguration surfaces later as an incident, at a simulation tick scheduled when the decision was made and often turns away, with a cause the player can trace.
- **Fun without the exam.** It must stand as a strategy game for people who never plan to certify.
- **Built the way it teaches.** The game is developed with Claude Code, eval-first, so the team practises the same skills the game teaches.

## Learning design

**Players learn because winning requires the content, not because a quiz interrupts them.** Six rules turn that into design constraints.

1. **The content is the rules.** Every certification concept is a game system the player operates, not a fact the player reads.
2. **Exact terms in the interface.** Fiction names sit on top ("Interlock"), but every tooltip, menu and log line carries the real term ("PreToolUse hook"). Transfer to the exam depends on the vocabulary.
3. **The simulation behaves like the real system.** A PostToolUse interlock can never stop an action. A subagent knows nothing of the parent conversation except its delegation message, and a fork is the exception because it inherits the whole conversation (corrected 2026-11-04). A batch can take up to 24 hours and expires if processing has not finished by then (corrected 2026-11-04). A wrong rule teaches a wrong answer.
4. **Distractors are tempting moves.** The exam's recurring wrong answers (stronger prompt, self-rated confidence, more retries, wider window) are offered as cheap, attractive options in the game. They work just often enough to tempt, and fail at the moments that matter.
5. **Delayed, traceable consequences.** Damage from a misconfiguration surfaces later, as an event scheduled at an absolute simulation tick, which on the strategic layer means several turns after the decision ([ADR-0020](docs/adr/0020-fixed-step-clock-and-numerics.md)). The incident log always shows the causal chain back to the decision.
6. **A thin bridge to the exam's format.** After-action reports are written as exam scenarios (situation, symptom, question, four options), so intuition from play becomes recall under exam conditions.

The exam's structure, distilled from two 60-question practice tests and the CCA-F question decoder in this project, sets the targets:

| Exam property | Design target |
| --- | --- |
| 5 domains: D1 Agentic architecture 27%, D2 Tools & MCP 18%, D3 Claude Code config 20%, D4 Prompts & structured output 20%, D5 Context & reliability 15% | Share of game systems and incidents per domain matches these weights |
| Questions sit inside 4–5 recurring scenarios | Each scenario becomes a colony type with its own recurring crises |
| The ask's superlative names the winning property ("most reliably" → deterministic mechanism; "most maintainable" → single source of truth) | Mission objectives use the same verbs and score the same property |
| About 10 recurring distractor patterns | The rival faction's sabotage doctrines (see The rival faction) |
| About 12% "select TWO" | Some crises need two concurrent orders to resolve |

## Setting and fiction

**The player is the Steward of the Lattice, the human command that configures and oversees a fleet of autonomous agent-craft keeping 40 colonies in the Verge cluster alive.** Human oversight of AI is the premise, not a lesson bolted on.

Each colony type is one of the exam's recurring scenarios, so the scenario stays the unit of play just as it is the unit of the exam:

| Colony type | Exam scenario | What the colony needs |
| --- | --- | --- |
| **Harbour** | Customer support resolution agent | Settlers file claims for rations, repairs and refunds. Agents verify, look up manifests, issue credits (irreversible) or escalate to a human magistrate. Target: 80% resolved at first contact. |
| **Survey Conclave** | Multi-agent research system | A coordinator sends probe, analyst, synthesis and archivist craft to produce cited survey reports that decide where to terraform. |
| **Shipyard** | Developer productivity agent | Agents with the built-in toolset (Read, Write, Edit, Bash, Grep, Glob) maintain decades-old ship systems and dock with third-party services over MCP ports. |
| **Admiralty** | Claude Code for team development | The doctrine archive (CLAUDE.md, rules, skills, settings, permission modes) that every captain's craft loads. |
| **Night Relay** | Claude Code in CI/CD | Unattended convoys that run nightly inspections and reviews with nobody awake to stop them. |
| **Assay Works** (optional) | Structured data extraction | Turns raw manifests into structured records. Add if the official exam guide lists this scenario. |

Three forces push against the player:

- **The Hollow Concord**, a rival power whose saboteurs exploit misconfigured agents. Their methods are the exam's distractor patterns.
- **The Drift**, an entropy field that degrades long-running craft: context that grows stale, attention that fades in long sessions.
- **Solar weather**: transient failures (timeouts, 503s, gateway errors) that punish swallowed errors and unbounded retries.

Resources are the real costs of agent systems: **Credits** (tokens and spend), **Time** (latency), **Trust** (each colony's confidence, the equivalent of user trust and first-contact resolution) and **Reach** (how many concurrent operations the network can run).

## Core loop and game systems

**The loop is configure, deploy, watch, diagnose, refit: the same loop an architect runs on a production agent system.** It plays across three layers that zoom into each other, Terra Invicta style.

*Diagram (core loop · 6 steps, 1 decision): see the [live document](https://claude.ai/artifact/Fx6gfg3aWabrL4ujhWsyYt).*

A refit at the wrong layer sends the player back to watching the log; only a fix at the causal layer closes the incident.

### Strategic layer: the cluster (turn = one week)

- Allocate Credits across colonies, research and the fleet.
- Choose which colonies to support as crises compete for limited Reach.
- Research new capabilities (see Progression).
- Set fleet-wide doctrine in the Admiralty, which every craft loads.
- Read the weekly intelligence brief: Concord activity, Drift levels, incidents in progress.

### Operational layer: the fleet bay

The player designs agent-craft and the systems they run in.

- **Hull class** = model choice: Haiku couriers (fast, cheap, high volume), Sonnet frigates (balanced, strong at code), Opus flagships (deep multi-step reasoning, slow and costly).
- **Loadout** = the tools list. Anything not fitted cannot be used; a craft with no loadout declared inherits everything (corrected 2026-11-04).
- **Standing orders** = system prompt, with optional example missions wrapped in tags.
- **Interlocks** = hooks: PreToolUse (before an action, can deny), PostToolUse (after), Stop (blocks the craft from reporting done).
- **Fire control** = tool\_choice: auto, any, a named tool, none.
- **Cargo manifests** = structured output schemas, with strict mode, enums, nullable fields.
- **Formations** = workflow patterns: pipeline, parallel fan-out, router, evaluator-optimizer, or an open-ended agent.
- **Comms** = delegation messages. A subagent craft knows nothing of the parent's conversation except what its message carries; a fork is the exception and inherits the whole conversation (corrected 2026-11-04).

### Incident layer: real time with pause

Missions run as a visible simulation. Each craft's **ship's log** is its literal message history plus each response's stop\_reason, which is a field of the response and not part of the messages array: every tool\_use, tool\_result and stop\_reason, in order (corrected 2026-11-04). When something goes wrong:

1. An incident fires with a symptom ("37 credits issued without an eligibility check").
2. The player pauses and reads the logs and traces.
3. The player issues a refit order at a specific layer of the system: description, loadout, interlock, comms, doctrine, schema.
4. The simulation resumes. A fix at the causal layer ends the incident; a fix at the wrong layer appears to work, then the incident recurs or the Concord exploits it.

Some incidents need two orders at once, mirroring the exam's "select TWO" questions.

## Content mapping

**Every game system is a certification concept wearing a uniform; the table is the contract the content team builds against.** Domain weights set how much play time each domain gets: D1 is the backbone of the campaign, D5 runs underneath everything as the Drift.

### Domain 1: Agentic architecture and orchestration (27%)

| Game system | Certification concept | What the player learns by playing | Concord trap it trains against |
| --- | --- | --- | --- |
| Ship's log | The agentic loop: tool\_use → tool\_result → repeat while stop\_reason is tool\_use (corrected 2026-11-04) | A craft acts only on what its log holds; the log is resent every turn | Envoy: assuming the model remembers between calls |
| Mission complete signal | stop\_reason values, including end\_turn, tool\_use and max\_tokens. This is not the complete set; the documentation lists seven values, and which others the game teaches is undecided (corrected 2026-11-04) | Read the signal; don't parse prose for "done" | Hand: a mechanism with the wrong contract |
| Flagship and escorts | Coordinator + subagents | Escorts start with a fresh context and know nothing of the flagship's conversation except the comms message; a fork is the exception and inherits the whole conversation (corrected 2026-11-04) | Envoy: vague delegation |
| Parallel launch | Several Agent calls in one turn | Independent sorties launched together finish faster | Tower: structure that ignores the dependency graph |
| Formations | Pipeline, routing, parallelisation, orchestrator-workers, evaluator-optimizer | Pick the simplest formation that solves the mission | Tower: the impressive architecture |
| Checkpoint gates | Inter-step validation in multi-step pipelines | Validate between stages so errors don't compound | Latewatch: checking only the final output |
| Turn limit | --max-turns, iteration caps | Unattended craft need a hard stop in code | Plea: asking the agent to stop |
| Escalation beacon | Explicit escalation criteria and a handoff tool | Escalate on stated conditions, not the craft's own confidence | Mirror: self-reported confidence |

### Domain 2: Tool design and MCP integration (18%)

| Game system | Certification concept | What the player learns | Concord trap |
| --- | --- | --- | --- |
| Equipment manifests | Tool descriptions | Craft pick equipment by its manifest; vague manifests cause misfires | Brute: more examples instead of a clearer description |
| Doctrine override | System-prompt keywords steer tool choice above descriptions | A stray keyword in orders can route every call to the wrong tool | Tower: adding a router instead of fixing the keyword |
| Loadout | Tool allowlists, focused tool sets | Remove a tool the craft must never use | Plea: "never use this tool" in the prompt |
| Fire control | tool\_choice: auto, any, a named tool, none | Force the exact call when output must come through one tool | Hand: "any" when one tool is required |
| Ports | MCP servers; local, project and user scopes | Local scope shadows project; team config lives in .mcp.json | Scroll: right config, wrong place |
| Malfunction reports | isError tool results vs JSON-RPC protocol errors | A failed lookup is data the craft can reason about | Liar: returning empty success on failure |
| Return cargo | Tool results shaped for the model: trimmed, labelled | Send the fields the task needs, not the warehouse | Envoy: unstructured, unsourced handoffs |

### Domain 3: Claude Code configuration and workflows (20%)

| Game system | Certification concept | What the player learns | Concord trap |
| --- | --- | --- | --- |
| Admiralty codex | CLAUDE.md at user, project and directory levels; @imports | Which orders apply where, and who shares them | Scroll: personal preferences committed for the team |
| Sector regulations | .claude/rules with path globs | Rules that load only for matching files | Scroll: rules without paths |
| Field manuals | Skills in .claude/skills; context: fork | Reusable procedures on demand; fork keeps the main context clean | Scroll: rare procedures in CLAUDE.md |
| Interlocks | Hooks: PreToolUse deny, PostToolUse, Stop; absolute paths | Deterministic guarantees at the right moment | Plea; Latewatch (PostToolUse where Pre is needed) |
| Clearance levels | Permission modes, allow/deny lists, settings.json vs settings.local.json | Shared policy vs personal overrides | Scroll: local settings for team needs |
| Night Relay | Headless mode: claude -p, --output-format json, GitHub Actions prompt input | Unattended runs need explicit limits and parseable output | Hand: interactive flags in CI |
| Planning table | Plan mode, interview pattern, test-first iteration | Plan before large changes; tests define done | Brute: retry until it passes |
| Log rotation | /clear vs /compact; fresh session + summary after code changes | Stale context misleads; reset with a summary | Hand: /compact for unrelated work |

### Domain 4: Prompt engineering and structured output (20%)

| Game system | Certification concept | What the player learns | Concord trap |
| --- | --- | --- | --- |
| Cargo manifests | Structured output in three layers: invocation (tool\_choice), shape (schema + strict), truth (code check + specific-error retry) | Each layer fixes a different failure | Plea: "respond only in JSON" |
| Manifest fields | Enums, nullable fields, "other" + detail | Let the craft say "unknown" instead of inventing | Silencer: hiding gaps |
| Example missions | Few-shot examples at ambiguous boundaries | Examples fix judgement calls, not structural causes | Brute: more of the same examples |
| Explicit criteria | Concrete criteria over vague adjectives | "Flag if X or Y" beats "flag important ones" | Plea: stronger adjectives |
| Bulk freight | Message Batches API: up to 24h, then expiry if processing has not finished, though most finish within 1h; results can return in any order and are matched by custom\_id; about half the cost (corrected 2026-11-04) | Cheap for overnight work, wrong for anything blocking | Hand: Batch for a blocking step |
| Second opinion | Independent review instance | A fresh reviewer catches what the author can't | Mirror: self-review in the same context |

### Domain 5: Context management and reliability (15%)

| Game system | Certification concept | What the player learns | Concord trap |
| --- | --- | --- | --- |
| The Drift | Context degradation in long sessions; lost in the middle | Key facts belong at the edges and in persistent notes | Brute: a bigger context window |
| Case files | Persistent fact blocks, scratchpads, structured state | Carry decisions forward explicitly | Envoy: relying on the transcript |
| Courier summaries | Summaries passed between agents | Only what you write survives the handoff | Envoy: prose summaries without sources |
| Readiness gauges | Per-type error rates, calibration, stratified sampling | Aggregate accuracy hides a failing category | Mirror: trusting the system's own numbers |
| Provenance seals | Source attribution, claim-to-source mapping | Conflicting sources are kept, attributed and dated | Silencer: blending or dropping a source |
| Solar weather | Transient errors, targeted retries, graceful degradation | Retry the transient with what it needs; surface the permanent | Liar; Brute (resubmitting everything) |

### Supporting courses

| Game system | Concept | Source course |
| --- | --- | --- |
| Steward's choice in every crisis | The 4Ds: Delegation, Description, Discernment, Diligence | AI Fluency |
| Automation, augmentation, agency postures | Three modes of human-AI interaction | AI Fluency |
| Prompt cache docks | Prompt caching, stable prefixes | Building with the Claude API |
| Long-range scanners | Extended thinking, token budgets | Building with the Claude API |
| Archive retrieval | RAG: chunking, embeddings, contextual retrieval | Building with the Claude API |

## Rival faction: the Hollow Concord

**The Concord is the exam's wrong answers given a face: ten doctrines, each one a distractor pattern that recurs across the practice tests.** The Concord never attacks with fleets. It sends advisors, offers "quick fixes" in the refit menu, and runs its own colonies on its doctrines so the player can watch them fail at scale.

Each doctrine has a herald who appears as an advisor with a tempting suggestion. The temptation is emotional, not technical: the Concord wins when the player is anxious, tired or rushed.

| Doctrine | Herald's pitch | How it shows up in play | What beats it |
| --- | --- | --- | --- |
| The Pleading Voice (Plea) | "Make the order louder." | Adds IMPORTANT and capitals to orders when the requirement must hold every time | Enforce in code: interlocks, loadout, fire control, manifests, clearance |
| The Flattering Mirror (Mirror) | "Ask the craft how sure it is." | Self-reported confidence, self-review in the same context | Independent reviewer, calibration against labelled data, sampling |
| The Late Watchman (Latewatch) | "We'll catch it in the audit." | PostToolUse checks and after-the-fact reports when harm happens at execution | Intercept before the action: PreToolUse deny, a gate before the side effect |
| The Forgetful Envoy (Envoy) | "The escort will know what you meant." | Vague delegation; subagents expected to inherit context | Pass specific findings, structured, with sources |
| The Smiling Liar (Liar) | "Report all clear; keep the room calm." | Swallowed errors, empty success on failure | Structured errors: isError, type, retryable, partial results |
| The Tower Builder (Tower) | "Build a grander system." | Extra classifiers, dispatcher layers, parallel agents for dependent steps | The simplest structure that matches the dependency graph |
| The Brute (Brute) | "Push harder." | More retries, bigger windows, longer timeouts, resubmit everything | Change what the system receives; retry only what failed |
| The Misplaced Scroll (Scroll) | "The content is right; who cares where it lives." | Personal settings for team needs, wrong MCP scope, rules without paths | Ask who needs it and when; one source of truth |
| The Wrong Hand (Hand) | "Use the tool you know." | --continue for a named session, Batch for a blocking step, /compact for unrelated work | Know each mechanism's exact contract |
| The Silencer (Silencer) | "Pick one source and move on." | Conflicting sources blended or dropped, gaps hidden, stated wishes overridden | Keep conflicts with attribution and dates; flag the unknown |

### How the Concord escalates

- **Act I:** heralds offer one doctrine at a time, and the counter is usually obvious once you read the log.
- **Act II:** two doctrines arrive together, and one of them is the correct-looking half of a select-two crisis.
- **Act III:** the Concord mimics good practice. A herald proposes a PreToolUse hook that is attached to the wrong tool, or an independent reviewer that is given the author's context. The player must judge the detail, not the category.

### Concord dossier

The player's file on the Concord fills in as doctrines are named and defeated. Naming the doctrine in an after-action report earns Insight. The dossier tracks how often each doctrine has fooled the player, and the Concord adapts: it sends whichever herald has the best record.

## Progression and tech tree

**The tech tree is the curriculum: each unlock is a real feature, ordered so every new mechanism arrives just after the player has felt the problem it solves.** Research costs Credits and Time, and a node only opens once the player has survived an incident that needed it.

### Five research branches

| Branch | Domain | Early unlocks | Late unlocks |
| --- | --- | --- | --- |
| Command | D1 | Ship's log (agentic loop), stop signals | Orchestrator-workers, evaluator-optimizer, checkpoint gates |
| Engineering | D2 | Equipment manifests, loadouts | Fire control modes, MCP ports and scopes, structured malfunction reports |
| Admiralty | D3 | Codex (CLAUDE.md), clearance levels | Sector regulations, field manuals, interlocks, Night Relay |
| Logistics | D4 | Explicit criteria, example missions | Cargo manifests with strict schemas, truth checks, bulk freight |
| Intelligence | D5 | Case files, courier summaries | Provenance seals, readiness gauges with per-type calibration |

### Unlock order principles

1. **Pain before cure.** The player meets a duplicated-refund incident with only orders available; the interlock unlocks right after. They feel why a prompt isn't a guarantee.
2. **Cheap before strong.** Explicit criteria unlock before example missions, which unlock before a full evaluator formation. The tree mirrors the exam's preference for the simplest sufficient fix.
3. **Cross-branch prerequisites mirror real dependencies.** Night Relay (headless CI) requires both interlocks and turn limits, because an unattended run needs both.
4. **No dead ends.** Every unlock stays useful to the end of the campaign; later tech adds options, it never replaces earlier tech.

### Steward rank

Rank rises with colony health, incidents resolved at the causal layer, and doctrines named. Each rank grants one Doctrine slot: a fleet-wide standing policy, such as "all escorts receive structured briefs" or "every external action passes a pre-check". Doctrines are where good habits become automatic, which is exactly what the player should leave with.

### Advisors

Four advisors, one per AI Fluency competency, comment on every crisis: the Quartermaster (Delegation), the Signals Officer (Description), the Inspector (Discernment) and the Chaplain (Diligence). Their trust in the player rises when the player makes the call their competency would make. Each advisor has a personal arc that resolves in Act III.

## Bridge to the exam

**The game never quizzes, but it constantly writes the exam for the player: every resolved incident becomes a question in the real format.** The bridge is thin and optional so the game stays a game.

### After-action reports

When an incident closes, the Signals Officer files a one-screen report:

1. The scenario in exam phrasing ("A customer support agent issues refunds without verifying eligibility in 12% of cases…").
2. The four orders that were on the table, written as answer options, including the Concord's suggestions.
3. Which order the player chose, which one fixed the cause, and why the others fail.
4. The doctrine each distractor belongs to.

The player can skip reports. Reading them earns Insight, which buys faster research.

### Readiness gauges

A wing of the Steward's office shows first-attempt accuracy per domain, weighted like the exam, plus coverage (domains with at least five measured incidents). It reports per-type accuracy as well as the aggregate, teaching D5 calibration by example.

### The War College

An unlockable mode that runs a timed simulation at the real exam's length, with scenario questions drawn from incidents the player has already seen, reframed with fresh numbers and names. Select-two questions appear at the exam's rate. The result is a mock score and a list of doctrines that fooled the player.

### Spaced recurrence

Incidents the player resolved at the wrong layer return as **echoes**: the same failure in a different colony weeks later, with the scenario changed. An echo resolved correctly at the first attempt is retired. This is spaced repetition with a story reason.

### What the bridge must never do

- Interrupt a crisis with a quiz.
- Use exam vocabulary the game has not already taught through play.
- Reward speed over reading the log.

## Onboarding: the first two hours

**The first two hours teach the agentic loop, tool design and one interlock through three escalating crises, without a single tutorial popup.** The player learns the interface by needing it.

| Time | Beat | What the player does | Concept they absorb |
| --- | --- | --- | --- |
| 0:00 | Arrival at Harbour Seren | Watches one support craft handle a supply request; the ship's log scrolls beside it | The loop: request, tool call, result, reply |
| 0:10 | First misfire | A craft calls the wrong tool; the player opens the log and rewrites one equipment manifest | Tool descriptions drive tool choice |
| 0:25 | The refund leak | Credits drain from issued refunds. The Pleading Voice offers a louder order; it slows the leak but doesn't stop it | Prompts guide; they don't guarantee |
| 0:40 | First research | The interlock unlocks. The player fits a PreToolUse check on the refund tool; the leak stops | Deterministic enforcement before the action |
| 0:55 | Expansion | A second colony joins; the player must split Reach and Credits between them | Resource trade-offs; delegation |
| 1:10 | First escort | The player sends a subagent to investigate a shipment and gets back nonsense | Subagents start fresh; brief them |
| 1:30 | The rewrite | The player writes a structured brief; the escort returns a sourced finding | Explicit context passing |
| 1:45 | First after-action report | The game shows the refund crisis as an exam question, with the Concord's offers as the wrong options | The thin bridge |
| 2:00 | The Concord reveals itself | A herald appears at the Steward's table | The campaign opens |

### Rules for onboarding

- Every UI element appears the first time it is needed, never before.
- The game pauses automatically on the first incident of each kind.
- The player can't fail the first two crises; they can only fix them slowly or well.

## 3D presentation and art direction

**3D earns its place by making systems visible: the player should see delegation, data flow and failure as physical movement in space.** A grand strategy game lives or dies on readability, so every 3D choice serves legibility first.

### Three camera scales

| Scale | View | What 3D adds |
| --- | --- | --- |
| Cluster | A slowly rotating star map; colonies as lit stations, supply lanes as glowing arcs | Depth separates the colony types; Concord influence shows as quad or shader fog creeping along lanes, because volumetric fog is unavailable under the Compatibility renderer |
| Colony | A station in orbit with docked craft, cargo flows and port connections | The player sees which craft is calling which tool as a beam to a port; MCP servers are physical docking rings |
| Bridge | The Steward's command deck, where advisors stand and incidents are reviewed | Characters and emotion; the ship's log projected as a holographic timeline you can scrub |

### Making the invisible visible

- **Context** is a craft's cargo hold. As the Drift rises, older crates dim and slide toward the middle of the hold where they're hard to reach.
- **Delegation** is a courier pod launched from flagship to escort, carrying only the crates the player loaded.
- **Interlocks** are physical gates on the beam between craft and port. A PreToolUse deny visibly blocks the beam before it lands.
- **Errors** spark at the port. A swallowed error (the Liar) shows as a spark that a Concord drone quietly covers up.
- **Structured output** is cargo locking into a shaped cradle; a malformed result doesn't fit.

### Visual style

Stylized low-poly sci-fi with a strong rim light and a restrained palette per colony type: warm amber for Harbours, cool teal for Survey Conclaves, industrial orange for Shipyards. The Concord uses a desaturated violet. Stylized art keeps scope small, renders well on modest hardware and stays readable when zoomed out.

### UI layer

Most decisions happen in 2D panels over the 3D scene: the fleet bay, the log viewer and the refit menu. Craft configuration uses a node-graph editor (craft → tools → interlocks → ports), which doubles as an architecture diagram the player can screenshot. Exact feature names appear in tooltips so the player learns the real vocabulary.

### Audio

An ambient score that tightens as incidents stack up, distinct sound signatures for each tool call type, and a quiet chime when an interlock does its job. Silence when the Liar covers an error, so attentive players learn to hear the gap.

## Technology: engine, language and architecture

**Recommendation: Godot 4 with GDScript, and a simulation core that knows nothing about the engine.** Godot is the right fit for a small team building with Claude Code, and your colleague's experience removes most of the learning risk.

Architecture decisions are recorded in [docs/adr/README.md](docs/adr/README.md).

### Why Godot 4

- **Text all the way down.** Scenes (.tscn), resources (.tres), scripts (.gd) and project settings are plain text. Claude Code can read, diff and edit nearly everything, and every change shows up in a normal code review.
- **Headless mode.** `godot --headless` runs tests and exports in CI with no display, so Claude Code can verify its own work.
- **Real 3D at indie scale.** The game uses the Compatibility renderer (WebGL 2), the only one Godot 4.7 supports on the web; Forward+ and Mobile are not available there (corrected 2026-11-04). Whether it carries the stylized look still has to be proven in the vertical slice; we are not chasing photorealism.
- **Open source, no royalties.** Nothing to negotiate later. The web download is not small, though: a nearly empty test export on 2026-11-04 produced a 39.5 MB `index.wasm`, about 10.1 MB when gzipped ([ADR-0004](docs/adr/0004-compatibility-renderer-single-threaded-web.md)) (corrected 2026-11-04).
- **Strong 2D UI.** Control nodes, themes and containers suit a panel-heavy strategy game better than most 3D-first engines.

### Language: GDScript or C#

|  | GDScript | C# (.NET) |
| --- | --- | --- |
| Web export | Yes | No: Godot's documentation says that projects written in C# using Godot 4 "currently cannot be exported to the web" (corrected 2026-11-04) |
| Iteration speed | Fastest; hot reload in the editor | Compile step; still quick |
| Typing | Optional static typing; enforce it by convention | Full static typing, mature tooling |
| Claude Code fluency | Good, but models sometimes write Godot 3 syntax; a CLAUDE.md rule fixes this | Excellent; C# is heavily represented in training data |
| Testing | A small in-repo runner, headless ([ADR-0019](docs/adr/0019-test-framework.md)); GUT and gdUnit4 are deferred until a test needs a scene runner, input simulation or doubles | xUnit/NUnit for the sim core with no engine needed; gdUnit4 for scenes |
| Best when | A browser demo matters (itch.io, sharing with colleagues) | Desktop-only release and a team that already lives in .NET |

**Decision (2026-11-04): GDScript.** A playable web build matters for a learning game you want people to try with one click, and Godot's documentation says that C# projects "currently cannot be exported to the web" in Godot 4 (corrected 2026-11-04). C# would only have made sense for a desktop-only release with a team stronger in .NET.

### Architecture: three layers

1. **Simulation core.** Pure logic: colonies, craft, tool calls, incidents, resources, the Concord. Deterministic and seeded, so any run can be replayed exactly. Time advances in integer ticks, commands carry their tick and rule values are integers ([ADR-0020](docs/adr/0020-fixed-step-clock-and-numerics.md)). No nodes, no rendering. In GDScript these are RefCounted classes; in C# a plain class library.
2. **Content as data.** Incidents, doctrines, tech nodes and the fact sheet live in JSON files validated by a JSON Schema in CI. Designers and Claude Code add content without touching code.
3. **Presentation.** Godot scenes subscribe to simulation events and draw them. The presentation layer never changes simulation state directly; it sends commands.

*Diagram (architecture · 3 layers, 3 checks): see the [live document](https://claude.ai/artifact/Fx6gfg3aWabrL4ujhWsyYt).*

Each layer has its own automated check, so Claude Code can verify content, rules and visuals separately.

This split is the single most important technical decision. It lets Claude Code test every rule headlessly in milliseconds, keeps content authoring safe, and means a replay of any bug report is one seed and a command list.

### Alternatives considered

| Option | Strengths | Why not first choice |
| --- | --- | --- |
| Unity (C#) | Mature 3D, huge asset store, strong C# | Scene and prefab files are noisy YAML that Claude Code edits poorly; heavier editor; licensing history |
| Unreal Engine | Best-in-class 3D | Blueprints and assets are binary; C++ build times; far more engine than this game needs |
| Bevy (Rust) | Code-only ECS, ideal for Claude Code and determinism | No editor, young UI story, steeper learning curve for the team |
| Three.js or Babylon.js (TypeScript) | Runs everywhere in a browser; we already built The Quiet Oracle this way | You build every tool yourself: UI framework, scene editing, save system, input; a strategy game's UI load makes this costly |

The Quiet Oracle prototype stays useful either way: its content files and validator can be ported to the new JSON schema.

## Building it with Claude Code

**The project's Claude Code setup is itself a worked example of Domain 3: the team learns the certification by configuring the tool that builds the game.** Every mechanism below appears in the game's tech tree.

### Repository layout

```
lattice-command/
  CLAUDE.md                 # project memory: architecture, conventions, commands
  .claude/
    settings.json           # shared permissions and hooks (committed)
    settings.local.json     # personal overrides (gitignored)
    rules/
      sim.md                # paths: sim/**  — determinism, no engine calls
      content.md            # paths: content/**  — schema, fact-sheet citations
      scenes.md             # paths: scenes/**, ui/**  — Godot 4 syntax, signals
      art.md                # paths: art/**  — Blender scripts, glTF export rules
    skills/
      add-incident/SKILL.md # scaffold an incident from a scenario + answer key
      balance-check/SKILL.md# run seeded simulations, report resource curves
      fact-check/SKILL.md   # verify content against the fact sheet
    agents/
      content-writer.md     # writes incidents; tools: Read, Write, Grep
      sim-reviewer.md       # reviews sim changes; read-only tools
      fact-checker.md       # checks claims against docs; WebFetch, Read
  .mcp.json                 # shared MCP servers (Blender for live art sessions)
  sim/                      # simulation core, no engine dependencies
  content/                  # JSON incidents, doctrines, tech, fact sheet
  scenes/ ui/               # Godot presentation
  art/
    scripts/                # Blender Python, one script per asset
    models/                 # generated .glb files (committed, never hand-edited)
  tests/                    # headless sim tests + content validation
```

### CLAUDE.md essentials

- The three-layer architecture and the rule that presentation never mutates simulation state.
- Commands: run tests, validate content, run a seeded simulation, export a web build.
- "This is Godot 4. Use typed GDScript, `@export`, `signal` syntax and `Callable`; never Godot 3 APIs."
- Where content facts come from (the fact sheet) and that no feature name may appear in content without a fact-sheet entry.

### Hooks (in .claude/settings.json)

| Hook | Matcher and handler `if` | Purpose |
| --- | --- | --- |
| PreToolUse | Matcher `Edit\|Write` | Deny edits to generated files: `.godot/`, `*.import`, exported builds, `art/models/**` |
| PostToolUse | Matcher `Edit\|Write`; handler `if` `Edit(/content/**)` | Run the content validator and return errors to Claude immediately |
| Stop | (no matcher) | Block "done" until headless sim tests and content validation pass |

Hook commands use absolute paths via `$CLAUDE_PROJECT_DIR`, so they work from any subdirectory.

A matcher tests the tool name only, so a path condition goes in the handler's `if` field, which holds one permission rule. In permission rules `Edit(path)` applies to all built-in tools that edit files and `Write(path)` never matches; whether `Edit(/content/**)` also catches Write in a hook's `if` has not been tested and must be checked when this hook is added. Stop takes no matcher and no `if`, because a hook with `if` set never runs on Stop. A Stop hook should check `stop_hook_active` in its input, which is true when Claude Code is already continuing because of a stop hook, and Claude Code overrides a Stop hook after eight consecutive blocks with no tool call in between, a cap that `CLAUDE_CODE_STOP_HOOK_BLOCK_CAP` can raise. "Block" in the table above is therefore limited by that cap (corrected 2026-11-04).

### Subagents

- **content-writer** turns a scenario brief into an incident file. It gets a structured brief (domain, concept, trap, fact-sheet entries), not a vague request.
- **sim-reviewer** reviews simulation diffs in a fresh context and checks determinism and test coverage. It never sees the author's reasoning, so it can't be talked into agreement.
- **fact-checker** verifies each technical claim in new content against current documentation and flags anything unverifiable.

### Daily workflow

1. Start large features in plan mode; the plan cites the design doc section it implements.
2. Write the failing simulation test first, then the code.
3. Use the interview pattern for new incidents: Claude asks what the scenario, the correct fix and the tempting wrong fixes are before writing.
4. After a big refactor, start a fresh session with a short summary instead of carrying stale context.
5. Look at the result: run the game windowed, capture a screenshot and let Claude Code inspect it, since headless tests can't judge a UI.

### CI with Claude Code

- GitHub Actions runs Godot headless: sim tests, content validation, web export.
- The Claude Code GitHub Action reviews each pull request with a review prompt and a turn limit. The turn limit goes in the action's `claude_args` input as `--max-turns`.
- A nightly headless job (`claude -p` with `--max-turns` and JSON output) re-runs the fact-checker over all content. The job passes `--agents` and `--allowedTools` explicitly, because the documentation says that `--bare`, which skips auto-discovery of subagents, hooks, skills and CLAUDE.md, will become the default for `-p`. Bare mode offers only Bash, file read and file edit tools, `--allowedTools` only pre-approves tools, and bare mode needs an API key rather than a subscription login, so whether the fact-checker keeps WebFetch there has to be tested before the job is relied on. The fact-checker has only WebFetch and Read, so a job step parses the JSON output and runs `gh issue create` for any claim whose source changed. How a changed source is detected is not yet defined.

### Art pipeline: Blender driven by Claude Code

**Claude Code builds the game's hard-surface 3D assets in Blender, and every shipped asset comes from a script in the repo.** Blender's Python API lets Claude Code create, edit and export models without anyone touching the Blender UI.

| Mode | How it works | Use it for |
| --- | --- | --- |
| Scripted (headless) | Claude Code writes a Python script and runs `/Applications/Blender.app/Contents/MacOS/Blender --background --python art/scripts/<asset>.py` (corrected 2026-11-04). The script builds the model and exports a `.glb` to `art/models/`, which Godot imports natively. | Every shipped asset: stations, craft hulls, docking rings, port gates, modular parts. Reproducible and rebuildable. |
| Live (MCP) | Claude drives a running Blender through an MCP server, inspects the scene and takes viewport screenshots. | Exploring a look, tuning materials and lighting, before the result is frozen into a script. |

**Rule:** a live session ends with Claude writing the script that reproduces the result. Nothing ships from a hand-saved scene.

#### Setting up live mode (macOS)

The community server MCP for Blender (by Siddharth Ahuja, MIT licence) works with Blender 3.0 and newer and has a documented Claude Code setup:

1. Install uv: `brew install uv`
2. In the repo, add the server at project scope so the whole team shares it through `.mcp.json`: `claude mcp add --scope project blender -- uvx mcp-for-blender`
3. Install the Blender add-on: `uvx mcp-for-blender install-addon`
4. In Blender, open Edit → Preferences → Add-ons and enable "MCP for Blender".
5. In the 3D viewport, press `N`, open the MCP for Blender tab and click **Start MCP Server**.
6. Start `claude`, run `/mcp` and confirm `blender` is connected. Ask Claude to list the scene objects; the default cube, camera and light mean it works.

Each team member does steps 1 and 3 to 5 on their own machine; step 2 is done once and committed. Blender must stay open with the server running, or every tool call fails.

**Official alternative:** Blender Lab's own MCP server (Blender 5.1 or newer, GPL) is the one Claude's built-in Blender connector uses. Install it from blender.org/lab/mcp-server. Its documentation has no Claude Code command yet; switch to it when that changes, since it is maintained by Blender developers.

#### Conventions (in `.claude/rules/art.md`)

- Pin the Blender version and its path in CLAUDE.md, so scripts and CI use the same build.
- Export binary glTF (`.glb`) with transforms applied and metric scale.
- Name files by kind and variant, for example `hull_frigate_a.glb`; use Godot import suffixes such as `-col` for collision meshes.
- Name materials after the art direction palette (Harbour amber, Conclave teal, Shipyard orange, Concord violet) so Godot can swap them per colony.
- Commit the generated `.glb` files so the game builds without Blender; regenerate them whenever a script changes.
- Extend the PreToolUse hook to deny direct edits to `art/models/**`: models change only by changing their script.

#### Limits and safety

- Claude is strong at procedural hard-surface models and weak at organic ones. Advisor characters and any creatures are modelled by hand or bought.
- Both MCP servers run Python that Claude writes inside Blender; the official one does so with no guards. Run live mode on a machine without sensitive data, or in a virtual machine.
- Scripted mode runs in the same sandboxed container as the rest of CI.

### Dogfooding

Incidents in the game should come from real moments in this repo. When a hook saves the team from a bad edit, that becomes a Night Relay incident. The team that builds the game ends up having practised every Domain 3 concept on real work.

## Content pipeline and fact accuracy

**A learning game that teaches a wrong fact is worse than no game, so every technical claim traces to a dated source.** Claude features change often; the pipeline assumes they will.

### The fact sheet

One JSON file, `content/facts.json`, holds every technical claim the game makes. Each entry has:

- `id` (for example `hooks.pretooluse.deny`)
- `claim` in one plain sentence
- `source` URL in the official docs
- `verified` date and `verifier`
- `domains` it supports

Incidents, tooltips and after-action reports reference fact ids, never free text about features. The validator fails the build if content names a feature without a fact id.

### Incident schema

Each incident file holds: the scenario, the colony type, the domain and task statement, the correct order(s), three or four tempting wrong orders each tagged with its Concord doctrine, the delayed consequence of each wrong order, fact ids, and the exam-format rewrite for the after-action report.

### Pipeline

1. **Source.** A designer or the content-writer subagent drafts from a scenario brief.
2. **Validate.** The schema check runs automatically through the PostToolUse hook.
3. **Fact-check.** The fact-checker subagent compares each referenced claim against its source.
4. **Simulate.** The balance-check skill plays the incident with each order under fixed seeds and confirms that only the correct order resolves it at the causal layer.
5. **Human review.** A person who has studied for the certification approves the incident. AI drafts; humans sign off.

### Freshness

- A nightly job re-verifies facts older than 30 days and flags any whose source page changed.
- The game shows a content version and "last verified" date in the War College.
- When a feature changes, the fact entry changes once and every incident that references it is flagged for review.

### Coverage targets

At launch: at least 60 incidents, weighted by exam domain (about 16 for D1, 11 for D2, 12 each for D3 and D4, 9 for D5), with every Concord doctrine appearing at least four times and roughly one in eight incidents needing two orders.

## Scope and milestones

**Prove the teaching loop in a vertical slice before building the strategy layer around it.** The riskiest question is whether incidents are fun and teach; the cluster map is known territory.

*Diagram (roadmap · 5 phases, 1 gate): see the [live document](https://claude.ai/artifact/Fx6gfg3aWabrL4ujhWsyYt).*

Phases are drawn at equal width, not to scale; the table gives the real lengths.

| Milestone | Length | Contents | Exit test |
| --- | --- | --- | --- |
| 0. Paper prototype | 2 weeks | Ten incidents played as cards with a game master; sim rules in a spreadsheet | Testers name the right fix more often after playing than before |
| 1. Vertical slice | 8 weeks | One Harbour colony in 3D, ship's log, refit menu, interlocks, three Concord doctrines, the first two hours of onboarding | Five players finish onboarding unaided; they describe a PreToolUse hook in their own words |
| 2. Alpha | 12 weeks | Cluster map, four colony types, full tech tree skeleton, all ten doctrines, 30 incidents, after-action reports | A full campaign is playable; readiness gauges correlate with a practice test score |
| 3. Beta | 10 weeks | All six colony types, 60+ incidents, War College, echoes, advisors' arcs, audio, web build | Players who finish score higher on a fresh practice test than a study-guide control group |
| 4. Release | 4 weeks | Polish, accessibility, localization hooks, fact sheet re-verified | Content verified within 30 days of launch |

Total: about nine months for a team of two or three with Claude Code doing most implementation. The vertical slice is the go/no-go point.

### Out of scope for 1.0

- Multiplayer.
- Procedurally generated incidents (hand-authored only, for accuracy).
- Live calls to the Claude API during play. The simulation models Claude's behaviour; it doesn't call it, which keeps the game deterministic, offline and free to run.
- Content beyond the CCA-F and its supporting courses. The schema leaves room for future certifications as new campaigns.

## Risks and open questions

**The biggest risk is pedagogical, not technical: a game that is fun but teaches the metaphor instead of the concept.** The vertical slice exists to test that.

### Risks

| Risk | Likelihood | Impact | Mitigation |
| --- | --- | --- | --- |
| Players learn the metaphor ("interlocks") but not the term ("PreToolUse hook") | Medium | High | Real terms in every tooltip and after-action report; playtest with a term-recall check |
| Facts go stale as Claude features change | High | High | Fact sheet with dates, nightly re-verification, content version shown in game |
| The strategy layer distracts from incidents | Medium | Medium | Incidents drive the strategic economy; the cluster map is a frame, not a second game |
| GDScript code from Claude Code drifts to Godot 3 syntax | Medium | Low | Path-scoped rule, typed GDScript, CI parse check |
| Hand-authored content doesn't scale | Medium | Medium | Content-writer subagent drafts, humans approve; schema keeps quality uniform |
| Simulating Claude's behaviour feels fake to experts | Low | Medium | Base each incident's behaviour on a documented failure mode and cite it |

### Open questions

1. **Audience:** individual learners preparing for the exam, or teams using it for onboarding? This changes pacing and whether the War College is central.
2. **Language:** resolved on 2026-11-04 in favour of GDScript; see "Language: GDScript or C#".
3. **Platform:** Steam and itch.io, internal company distribution, or both?
4. **Licensing of exam-style content:** can after-action reports mirror the exam's format closely without reproducing real exam items? (They must be original; confirm the boundary.)
5. **Measuring learning:** which practice test serves as the before-and-after benchmark, and who owns that study?
6. **Your colleague's Godot project:** which parts (UI theme, camera, save system) can be reused to shorten the vertical slice?
