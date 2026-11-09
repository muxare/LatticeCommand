# Architecture decision records

These records hold the structural decisions behind Lattice Command, the options they were chosen over, and how anyone can tell whether the project still follows them. The GDD says what the game is; an ADR says which structural choice was made and how adherence is checked. [ADR-0001](0001-record-architecture-decisions.md) sets the rules, and [`0000-template.md`](0000-template.md) is the format.

Before starting a large feature, find the ADRs it touches below and cite them in the plan beside the GDD section. If the plan conflicts with an Accepted ADR, change the plan or write a superseding ADR. Do not edit an Accepted ADR's substance.

## Index

Accepted means a person has made the decision, either by writing it down in the GDD or `CLAUDE.md`, which the ADR then records, or by accepting the ADR itself. "Accepted, amended by ADR-NNNN" means a later ADR replaced part of it and the rest stays in force. Proposed means a person still has to decide, and on 2026-11-09 no ADR has that status.

| ADR | Decision | Status |
| --- | --- | --- |
| [0001](0001-record-architecture-decisions.md) | Decisions are numbered, immutable ADRs that carry their own checks | Accepted |
| [0002](0002-godot-4-as-engine.md) | Godot 4, pinned at the 4.7.2 standard build | Accepted, amended by [ADR-0022](0022-claude-config-guards-worktrees-and-fails-closed.md) |
| [0003](0003-typed-gdscript.md) | Typed GDScript, never C# or Godot 3 APIs | Accepted, amended by [ADR-0022](0022-claude-config-guards-worktrees-and-fails-closed.md) |
| [0004](0004-compatibility-renderer-single-threaded-web.md) | Compatibility renderer and single-threaded web export | Accepted, amended by [ADR-0023](0023-owner-decisions-on-the-open-register.md) |
| [0005](0005-three-layer-split.md) | Simulation, content and presentation are separate, joined only by commands and events | Accepted, amended by [ADR-0020](0020-fixed-step-clock-and-numerics.md) |
| [0006](0006-deterministic-seeded-replay.md) | A run replays exactly from one seed and a command list | Accepted, amended by [ADR-0020](0020-fixed-step-clock-and-numerics.md) |
| [0007](0007-no-live-claude-api-in-play.md) | The game models Claude and never calls it during play | Accepted |
| [0008](0008-simulation-fidelity.md) | The simulation behaves like the real system, the log is the literal history plus each response's stop_reason, and only a causal fix closes an incident | Accepted, amended by [ADR-0022](0022-claude-config-guards-worktrees-and-fails-closed.md) |
| [0009](0009-content-as-validated-json.md) | Content is JSON validated by JSON Schema in CI | Accepted, amended by [ADR-0023](0023-owner-decisions-on-the-open-register.md) |
| [0010](0010-fact-sheet-single-source.md) | Every technical claim lives in `content/facts.json` and content references fact ids | Accepted, amended by [ADR-0023](0023-owner-decisions-on-the-open-register.md) |
| [0011](0011-hand-authored-incidents-human-signoff.md) | Incidents are hand-authored and original, pass five steps, and a person signs off | Accepted, amended by [ADR-0022](0022-claude-config-guards-worktrees-and-fails-closed.md) |
| [0012](0012-content-mapping-is-the-contract.md) | The content mapping tables and exam weights are the contract | Accepted, amended by [ADR-0022](0022-claude-config-guards-worktrees-and-fails-closed.md) and [ADR-0023](0023-owner-decisions-on-the-open-register.md) |
| [0013](0013-teach-through-play.md) | No quizzes in play, visible real terms, delayed traceable consequences, a thin optional bridge | Accepted |
| [0014](0014-scripted-blender-art-pipeline.md) | Each shipped asset comes from one Blender script, and its committed `.glb` is never hand-edited | Accepted, amended by [ADR-0022](0022-claude-config-guards-worktrees-and-fails-closed.md) and [ADR-0023](0023-owner-decisions-on-the-open-register.md) |
| [0015](0015-live-blender-mcp-exploration-only.md) | Live Blender over MCP only explores a look and must end in a script | Accepted |
| [0016](0016-claude-code-config-as-worked-example.md) | The Claude Code configuration follows the GDD as a worked example of Domain 3 | Accepted, amended by [ADR-0022](0022-claude-config-guards-worktrees-and-fails-closed.md) |
| [0017](0017-test-first-headless-verification.md) | Rules are test-first and headless; visual work is judged from a windowed screenshot | Accepted |
| [0018](0018-vertical-slice-gate-and-scope.md) | Paper prototype first, vertical slice as the go/no-go gate, no strategy layer ahead of it | Accepted, amended by [ADR-0023](0023-owner-decisions-on-the-open-register.md) |
| [0019](0019-test-framework.md) | A small in-repo test runner, with no third-party framework yet | Accepted |
| [0020](0020-fixed-step-clock-and-numerics.md) | Integer ticks, tick-stamped commands, integer rule values and an own generator | Accepted |
| [0021](0021-ci-on-github-actions.md) | CI on GitHub Actions with headless jobs, a pull request review and a nightly fact-check | Accepted, amended by [ADR-0023](0023-owner-decisions-on-the-open-register.md) |
| [0022](0022-claude-config-guards-worktrees-and-fails-closed.md) | The generated-file hook guards every checkout and fails closed, and the incident and review tooling is corrected ahead of its tools | Accepted, amended by [ADR-0023](0023-owner-decisions-on-the-open-register.md) |
| [0023](0023-owner-decisions-on-the-open-register.md) | The slice trims its onboarding to one colony, exam weights apply to incidents, and the open content, fact-sheet and CI choices are settled | Accepted, amended by [ADR-0024](0024-fun-measure-asset-storage-and-re-approval-issue.md) |
| [0024](0024-fun-measure-asset-storage-and-re-approval-issue.md) | The slice measures fun by voluntary play, bought asset sources stay out of the public repository, and the nightly job keeps one issue for facts due for re-approval | Accepted |

## Are we on track?

As of 2026-11-09 the ADRs define 144 checks: 15 Active, 46 Manual and 83 Pending. So little runs because almost nothing has been built, and that is accurate for a project with no game code. The table shows what each piece of tooling would switch on, which also shows where it pays to build first. When tooling lands, the same change updates the State column in the ADRs and this table.

| To build | Switches on checks in |
| --- | --- |
| CI workflows (the remote exists since 2026-11-07) | 0002, 0003, 0004, 0005, 0006, 0007, 0008, 0009, 0010, 0014, 0015, 0017, 0019, 0020, 0021, 0023, 0024 |
| Test runner and first simulation code | 0002, 0005, 0006, 0008, 0013, 0017, 0019, 0020, 0021 |
| Content schemas and validator | 0005, 0009, 0010, 0011, 0012, 0013, 0016, 0017, 0019, 0021, 0022, 0023 |
| `content/facts.json` | 0008, 0010, 0011, 0021, 0022, 0023 |
| Seeded simulation runner | 0006, 0008, 0011, 0013, 0016, 0022, 0023 |
| Main scene and first scene | 0004, 0007, 0009, 0017, 0020, 0021 |
| First asset script | 0014, 0015 |
| Live Blender setup and `.mcp.json` | 0015, 0016 |
| Vertical slice and playtests | 0004, 0007, 0013, 0018, 0023, 0024 |
| UI code and scoring rules | 0013 |
| A tool that flags incidents when a fact changes | 0010 |

Beyond the checks, the signals to watch are the "Drift signals" paragraph in each ADR. Disagreements found between the GDD, `CLAUDE.md`, `.claude/` and official documentation while these were written are tracked in [`findings-2026-11-04.md`](findings-2026-11-04.md).
