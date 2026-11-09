# ADR-0008: The simulation behaves like the real system, the ship's log is the literal message history plus each response's stop_reason, and only a fix at the causal layer closes an incident

| | |
| --- | --- |
| **Status** | Accepted, amended by [ADR-0022](0022-claude-config-guards-worktrees-and-fails-closed.md) |
| **Date** | 2026-11-04 |
| **Deciders** | Mikael Axelsson |
| **Sources** | `lattice-command-gdd.md` ("Learning design" rules 3 and 5, "Core loop and game systems", "Content mapping" for Domain 1); `CLAUDE.md` ("Teaching rules that constrain the code"). Checked on 2026-11-04 against [Hooks reference](https://code.claude.com/docs/en/hooks), [Subagents](https://code.claude.com/docs/en/sub-agents), [Batch processing](https://platform.claude.com/docs/en/build-with-claude/batch-processing), [How tool use works](https://platform.claude.com/docs/en/agents-and-tools/tool-use/how-tool-use-works) and [Stop reasons](https://platform.claude.com/docs/en/api/handling-stop-reasons) |
| **Related** | [ADR-0005](0005-three-layer-split.md), [ADR-0006](0006-deterministic-seeded-replay.md), [ADR-0007](0007-no-live-claude-api-in-play.md), [ADR-0010](0010-fact-sheet-single-source.md), [ADR-0011](0011-hand-authored-incidents-human-signoff.md), [ADR-0013](0013-teach-through-play.md), [ADR-0017](0017-test-first-headless-verification.md), [ADR-0019](0019-test-framework.md), [ADR-0020](0020-fixed-step-clock-and-numerics.md), [ADR-0021](0021-ci-on-github-actions.md), [ADR-0022](0022-claude-config-guards-worktrees-and-fails-closed.md) |

## Context

Players learn the certification through the game's rules, without studying. They will trust what they saw work, so a rule that differs from the real system does not merely reduce realism: it teaches a wrong exam answer, and teaches it well. Because the game does not call Claude ([ADR-0007](0007-no-live-claude-api-in-play.md)), nothing corrects such a rule during play. A slightly wrong rule is also often more fun or easier to balance, so game development pushes the other way.

## Decision

Every rule that models a Claude feature must behave as the official documentation says that feature behaves. A rule that does not is a product defect, not a balance question or a matter of polish, and it must not be bent for balance. Rules must be written from the current documentation and not from memory, and the claims behind them must reach the fact sheet ([ADR-0010](0010-fact-sheet-single-source.md)), which does not exist yet.

A PostToolUse interlock must never stop the action it follows. The documentation says the hook runs after a tool completes, and that "the tool has already run by the time the hook fires, so any files written, commands executed, or network requests sent have already taken effect". The simulation must therefore apply the action's side effects first and without exception. It must also not understate the hook: exit code 2 shows a message to Claude, `decision: "block"` adds a reason next to the tool result, `updatedToolOutput` replaces what Claude sees, and `continue: false` stops Claude from processing further. It can affect what happens next, but it never takes back what already happened. By contrast, PreToolUse can deny a call before it runs, and Stop can prevent Claude from stopping.

A subagent must not know anything from its parent's conversation except what the delegation message carries. The documentation confirms that each subagent "starts with a fresh, isolated context window" and "doesn't see your conversation history". The GDD and `CLAUDE.md` word the rule the same way: a subagent knows nothing of the parent conversation except its delegation message. A subagent also receives its own system prompt with environment details, the CLAUDE.md hierarchy, a git status snapshot and any preloaded skills, with some variation by agent type. Forks are a documented exception that inherits the entire conversation.

A batch must be able to take up to 24 hours. The documentation says "Batches might take up to 24 hours for processing", that most complete within an hour, and that batches expire if processing does not complete within 24 hours. The simulation must therefore treat 24 hours as a limit and not a fixed duration, must allow requests to end as `expired`, and must not promise that results arrive in request order, because the documentation says order is not guaranteed and results are matched by `custom_id`.

A craft's ship's log must be its literal message history, not a narrative derived from it. It must show every `tool_use`, `tool_result` and `stop_reason` in order, and a craft must act only on what its log holds. The documented loop continues while `stop_reason` is `tool_use`, with the prior messages, the assistant's response and a user message of `tool_result` blocks sent on each new request, one result per `tool_use` block. `stop_reason` is a field of the response and not part of the `messages` array, so the log must present it attached to the response it came from. The documentation says the client loop exits on any stop reason other than `tool_use` and that `pause_turn` needs a resend, the GDD's Domain 1 table says the loop repeats while `stop_reason` is `tool_use`, and a simulated loop must follow the documentation.

Only a fix at the causal layer may close an incident. A refit at the wrong layer may appear to work, but the incident must then recur or the Concord must be able to exploit it, and the incident log must show the causal chain back to the decision. Where an incident needs two orders, both are required.

The owner accepted this ADR's narrower wording of the fidelity rule and its three examples on 2026-11-04, and the GDD and `CLAUDE.md` were corrected in the same change, as [ADR-0001](0001-record-architecture-decisions.md) requires.

How 24 hours maps onto game time is settled by [ADR-0020](0020-fixed-step-clock-and-numerics.md), in which a 24-hour batch is 1,440 ticks. Several points are open. It is undecided whether the game models forks at all, what a subagent craft's standing context looks like, which stop reasons the game includes beyond `tool_use` and `end_turn`, and the log's data structure.

## Alternatives considered

**A simplified model that favours fun over accuracy.** It would be easier to build and balance, and it is the usual choice in a game. It lost because the accuracy of the simulation is the product: a simplification that changes behaviour teaches a wrong answer.

**A summarised, readable log in place of the real message history.** It would be friendlier, especially early on. It lost because the exam tests the actual loop, and diagnosing from the real messages is the skill being taught.

## Consequences

The game's lessons transfer to the exam and to real systems, and a player who reads the log is reading what an architect reads. The `Latewatch` and `Envoy` doctrines work as traps because the rules behind them are real.

The cost is that the game is tied to a moving target. A Claude change can turn a correct rule into a defect with no code change, so facts need to be re-verified and rules updated, and some rules will be less fun than a loose version would be. Exposing the raw log makes early play harder to read, which onboarding has to absorb.

## Staying on track

| Check | Enforced by | State |
| --- | --- | --- |
| Rules in a `sim/` diff match the Claude behaviour they model | `sim-reviewer` subagent, invoked by hand; it has only Read, Grep and Glob, so its brief must carry the documented behaviour. [ADR-0022](0022-claude-config-guards-worktrees-and-fails-closed.md) amends this, because `sim-reviewer` now accepts a modelled behaviour only when a fact id in `content/facts.json` backs it, never on its brief, and reports any other as unverified. | Manual |
| Sessions touching `sim/` are told rules must match the real system; this informs and does not verify | `.claude/rules/sim.md` | Active |
| PostToolUse never prevents a side effect, a subagent sees only its delegation from the parent, and batches respect the 24-hour limit | Headless rule tests | Pending (needs those rules in `sim/`; the test runner exists) |
| The ship's log holds every `tool_use`, `tool_result` and `stop_reason`, in order | Headless rule tests | Pending (needs those rules in `sim/`; the test runner exists) |
| No wrong order closes an incident at the causal layer | `balance-check` skill, which stops by design until its runner exists | Pending (needs seeded simulation runner) |
| Every claim behind a rule matches its official source | `fact-checker` subagent, invoked by hand | Manual |
| Claims are re-verified nightly | Scheduled headless run | Pending (needs CI, [ADR-0021](0021-ci-on-github-actions.md)) |

**Drift signals.** A PostToolUse handler in `sim/` returns early before applying a side effect or sets a flag such as `cancelled`. A subagent craft reads a field of its parent's history. A batch has a constant duration or always succeeds. Log lines are composed for display from something other than the message record, or a `stop_reason` is missing from one. A simulated loop tests only for `end_turn`. A playtester reports that strengthening a prompt fixed an incident permanently. An incident closes after a fix at a layer other than its causal one. A rule's pull request justifies itself with "feels better" or cites no source.

**Revisit when.** Official documentation changes the behaviour of a modelled feature, in which case the rule changes and this decision stands. The decision itself should be reopened only if playtests show that exact fidelity prevents learning, for example if players cannot get through the raw log even with onboarding, and any answer then should change presentation before it changes rules.
