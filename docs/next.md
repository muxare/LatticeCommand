# Next

Last updated 2026-11-07.

## Where the work stands

`main` is at `069f822`. Findings T7, T8 and T9 are corrected and committed on the branch `fix/claude-config-t7-t9`, which is not merged. That commit also holds [ADR-0022](adr/0022-claude-config-guards-worktrees-and-fails-closed.md), which Mikael accepted on 2026-11-07 and which amends ADR-0002, 0003, 0008, 0011, 0012, 0014 and 0016. The generated-file hook now guards worktrees and fails closed, including through `"onFailure": "block"`, and it passed a 74-case piped table and live denials on 2026-11-04 and 2026-11-07. The rewritten skills and `sim-reviewer` have not been run, because `content/facts.json` and the simulation runner do not exist. The `docs/adr-baseline` branch still exists and can be deleted. The repository has no git remote, so nothing is pushed. No game code, content or test runner exists.

## Waiting on Mikael

1. Say whether to merge `fix/claude-config-t7-t9` into `main`.
2. Decide D3 in [the findings register](adr/findings-2026-11-04.md): is the vertical slice widened, or is its onboarding trimmed or stubbed? It decides what the slice builds, so it comes first.
3. Decide whether to add a GitHub remote, which CI needs ([ADR-0021](adr/0021-ci-on-github-actions.md)).
4. Decide the other open choices in that register: T2, T3's definition of a changed source, D1, D2 and D5 to D12.
5. Decide the points ADR-0022 leaves open: how the incident schema records orders needed together, whether alternative correct orders exist at all, how a person's approval of a fact entry is recorded and what goes in `verifier`, and whether `tests/**` gets a path-scoped rule.

## Next, in the suggested order

This order is a suggestion that nobody has confirmed yet.

1. Start Milestone 0, the paper prototype: ten incidents played as cards with a game master, and the simulation rules in a spreadsheet (GDD "Scope and milestones"). Writing incidents needs the first entries in `content/facts.json`, which the main session drafts from the official documentation, `fact-checker` verifies and a person approves (ADR-0022), and a person who has studied for the certification must approve the incidents.
2. Build `tests/run.gd` and the first failing simulation test ([ADR-0019](adr/0019-test-framework.md), [ADR-0017](adr/0017-test-first-headless-verification.md)), and then add the test command to `CLAUDE.md`.
3. Decide how the content validator is implemented, because Godot has no JSON Schema class ([ADR-0009](adr/0009-content-as-validated-json.md)), and then build the schemas and the validator. That also unblocks the PostToolUse and Stop hooks.
