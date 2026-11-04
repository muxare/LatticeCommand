# ADR-0021: CI runs on GitHub Actions, with headless Godot jobs, a Claude Code pull request review and a nightly fact-check

| | |
| --- | --- |
| **Status** | Accepted |
| **Date** | 2026-11-04 |
| **Deciders** | Mikael Axelsson |
| **Sources** | `lattice-command-gdd.md` ("CI with Claude Code", "Freshness", "Why Godot 4", "Subagents"); `CLAUDE.md` ("Tools", "Claude Code setup") |
| **Related** | [ADR-0001](0001-record-architecture-decisions.md), [ADR-0004](0004-compatibility-renderer-single-threaded-web.md), [ADR-0009](0009-content-as-validated-json.md), [ADR-0010](0010-fact-sheet-single-source.md), [ADR-0016](0016-claude-code-config-as-worked-example.md), [ADR-0017](0017-test-first-headless-verification.md), [ADR-0019](0019-test-framework.md), [ADR-0020](0020-fixed-step-clock-and-numerics.md) |

## Context

The project relies on automated checks because most implementation is done by agents and a wrong rule or stale fact teaches a wrong exam answer. Many other ADRs have checks that wait for CI. Under [ADR-0001](0001-record-architecture-decisions.md), an agent-drafted ADR may be Accepted when it records what a person has already written down, and this one rests on the three lines of the GDD's "CI with Claude Code" section (lines 438 to 440), and on the engine pins in `CLAUDE.md` (lines 25 to 37); line numbers in this ADR refer to the files as committed in `6055b25`. Anything beyond those is listed below as an open point, not decided here.

**Verified against the repository on 2026-11-04.** Nothing described here exists yet. `git remote -v` prints nothing, so the repository has no GitHub remote or any other remote, and there is no `.github/` directory. There are no tests, no content validator and no main scene in `project.godot`.

**Verified against current documentation on 2026-11-04.** The named flags exist. The [CLI reference](https://code.claude.com/docs/en/cli-reference) lists `-p`/`--print`, `--max-turns` ("print mode only", "No limit by default") and `--output-format` with `text`, `json` and `stream-json`. The [`claude-code-action` inputs](https://github.com/anthropics/claude-code-action/blob/main/action.yml) include `prompt`, as the GDD's line 141 says. Three details shape the workflows. The action has no turn-limit input, as the GDD records: `max_turns` was a beta input, and [v1 takes `--max-turns` inside `claude_args`](https://code.claude.com/docs/en/github-actions). With a `prompt`, [results go to the workflow log by default](https://code.claude.com/docs/en/github-actions), so a review reaches the pull request only if the prompt directs it and a posting tool is allowed. And the [headless documentation](https://code.claude.com/docs/en/headless) recommends `--bare` in CI and says it will become the default for `-p`, while `--bare` skips `.claude/agents/`, the home of the `fact-checker` subagent, so the GDD has the job pass `--agents` and `--allowedTools` explicitly, and whether the fact-checker keeps WebFetch in that mode still has to be tested. The same page says that recent `-p` runs start in Manual permission mode, in which a call needing approval is denied unless something approves it. Scheduled workflows [run only from the default branch, and public repositories have them disabled after 60 days without activity](https://code.claude.com/docs/en/github-actions). The action needs the Claude GitHub App, or a custom app, and a secret, and `/install-github-app` works only with github.com repositories.

**Tested on 2026-11-04 with Godot 4.7.2 on macOS.** A fresh checkout without `.godot/`, which `.gitignore` excludes, cannot resolve `class_name` types until `godot --headless --path . --import` has run. The official Linux x86_64 binary and export templates for 4.7.2 [are published](https://github.com/godotengine/godot-builds/releases/tag/4.7.2-stable). The Linux build itself was not run.

## Decision

The project's CI must run on GitHub Actions, as the GDD states, and the GDD specifies three parts.

A workflow must run Godot headless for simulation tests, content validation and the web export. A second workflow must use the Claude Code GitHub Action to review each pull request, with a review prompt and a turn limit. A nightly headless job must run `claude -p` with `--max-turns` and JSON output, re-run the fact-checker over content, and open an issue for any claim whose source changed.

The pins in `CLAUDE.md` apply. CI must use Godot 4.7.2, the standard build rather than .NET, with export templates that match the engine version exactly, and a Godot upgrade must update the `CLAUDE.md` pin, CI and the templates together. On a runner, the pin means the version, because the path in `CLAUDE.md` is specific to macOS.

**Open points, not decided here.** Other ADRs name CI checks beyond those three parts: grep checks ([ADR-0005](0005-three-layer-split.md), [ADR-0006](0006-deterministic-seeded-replay.md), [ADR-0007](0007-no-live-claude-api-in-play.md)), a parse check ([ADR-0003](0003-typed-gdscript.md), [ADR-0017](0017-test-first-headless-verification.md), from the GDD's risk table) and script-to-model checks ([ADR-0014](0014-scripted-blender-art-pipeline.md), [ADR-0015](0015-live-blender-mcp-exploration-only.md)). No source adds them to CI, so they stay Pending until a workflow adopts them. The repository needs a GitHub remote before any of this can run, and pushing is the owner's call. Whether it is public or private affects the 60-day schedule rule, fork pull requests and Actions minutes. The GDD gives the nightly job two scopes: "all content" under "CI with Claude Code", and "facts older than 30 days" under "Freshness". [ADR-0010](0010-fact-sheet-single-source.md) notes this too, along with the fact-checker's lack of any way to detect a changed page. The `fact-checker` subagent has only `WebFetch` and `Read`, so a job step parses the JSON output and runs `gh issue create`, as the GDD specifies. Authentication (API key or OAuth token), how Godot is installed on the runner (the third-party `chickensoft-games/setup-godot` action or a direct download), whether the action and the `claude` version are pinned beyond the floating `@v1` tag (the action published v1.0.268 on 2026-11-04), the runner operating system, and whether the review uses the action's `code-review` plugin or a plain prompt are also open.

## Alternatives considered

The GDD records no alternatives to GitHub Actions and none was seriously held, so this ADR lists none rather than inventing them. If the repository ends up elsewhere, that would need a superseding ADR, and the [documentation's GitLab path](https://code.claude.com/docs/en/gitlab-ci-cd) would be the starting point.

## Consequences

The checks that many ADRs mark as Pending get one home, and an agent's pull request gets the same verification whoever wrote it. The review and the nightly job dogfood the certification's headless and CI content, which the GDD teaches as the Night Relay.

The costs are Actions minutes and API usage on every pull request and every night, a credential to manage, and false alarms from reworded documentation. The GitHub App's permission set is broader than the action uses, and GitHub does not allow accepting a subset. CI on Linux, if that is the runner chosen, would also run a different engine binary from the developer's Mac, and the probe in [ADR-0020](0020-fixed-step-clock-and-numerics.md) shows that floating point functions can differ between builds, so a test that passes on the Mac may not pass in CI if it touches them. Finally, `--bare` becoming the default for `-p` could silently remove subagents and `CLAUDE.md` from the nightly job, so that job must state what it loads.

## Staying on track

| Check | Enforced by | State |
| --- | --- | --- |
| The repository has a GitHub remote and the workflows run on pull requests | Repository settings and `.github/workflows/` | Pending (needs a remote and the workflow files) |
| Simulation tests run headlessly after `--import` | CI job | Pending (needs a remote, the test command that [ADR-0019](0019-test-framework.md) settles, and tests) |
| Content validates against its schemas | CI job | Pending (needs the validator and schemas from [ADR-0009](0009-content-as-validated-json.md)) |
| The web build exports on Godot 4.7.2 with matching templates, and `build/web/` is created first | CI job | Pending (needs the workflow, and a main scene before the exported build can run) |
| The workflow's Godot version equals the `CLAUDE.md` pin | CI step comparing `godot --version` with the pin | Pending (needs the workflow) |
| Pull requests are reviewed with a prompt and `--max-turns` in `claude_args` | Claude Code GitHub Action | Pending (needs a remote, the Claude GitHub App or custom app, and a secret) |
| Nightly fact-check runs and opens issues | Scheduled workflow | Pending (needs `content/facts.json`, a resolved scope and the items above) |
| Flags and action inputs still match the docs when the workflows change | Pull request review, per [ADR-0016](0016-claude-code-config-as-worked-example.md) | Manual |

**Drift signals.** A workflow installs "latest" Godot or templates of another version. `godot --version` in a CI log is not `4.7.2.stable.official.ed1daf0bf`. A workflow passes `max_turns` or `direct_prompt`, which are beta inputs. A review run finishes with no comment on the pull request. A nightly job reports success with no subagent loaded, or hits its turn limit night after night. The schedule stops after 60 quiet days. Tests pass locally and fail in CI on a float. Interactive-only flags appear in a workflow, the very mistake the game's Hand doctrine teaches against.

**Revisit when.** The repository is hosted somewhere other than GitHub, the action's major version changes, `--bare` becomes the default for `-p`, the cost of the review or the nightly job exceeds its value, or the built-in [Code Review](https://code.claude.com/docs/en/code-review) product replaces the need for a review workflow.
