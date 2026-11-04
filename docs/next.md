# Next

Last updated 2026-11-04.

## Where the work stands

The ADRs, the design document corrections and this handoff file are merged into `main` at `3f6eddc`. The `docs/adr-baseline` branch still exists and can be deleted. The repository has no git remote, so nothing is pushed. No game code, content or test runner exists.

## Waiting on Mikael

1. Decide whether to add a GitHub remote, which CI needs ([ADR-0021](adr/0021-ci-on-github-actions.md)).
2. Decide D3 in [the findings register](adr/findings-2026-11-04.md): is the vertical slice widened, or is its onboarding trimmed or stubbed? It decides what the slice builds, so it comes first.
3. Decide the other open choices in that register: T2, T3's definition of a changed source, D1, D2 and D5 to D12.

## Next, in the suggested order

This order is a suggestion that nobody has confirmed yet.

1. Fix the `.claude/` issues T7, T8 and T9 from the findings register, so that the tooling is right before content goes through it.
2. Start Milestone 0, the paper prototype: ten incidents played as cards with a game master, and the simulation rules in a spreadsheet (GDD "Scope and milestones"). Writing incidents needs the first entries in `content/facts.json`, and a person who has studied for the certification must approve them.
3. Build `tests/run.gd` and the first failing simulation test ([ADR-0019](adr/0019-test-framework.md), [ADR-0017](adr/0017-test-first-headless-verification.md)), and then add the test command to `CLAUDE.md`.
4. Decide how the content validator is implemented, because Godot has no JSON Schema class ([ADR-0009](adr/0009-content-as-validated-json.md)), and then build the schemas and the validator. That also unblocks the PostToolUse and Stop hooks.
