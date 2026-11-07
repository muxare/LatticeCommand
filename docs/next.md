# Next

Last updated 2026-11-07.

## Where the work stands

Mikael's decisions of 2026-11-07 on every remaining choice in [the findings register](adr/findings-2026-11-04.md) and on ADR-0022's open points are committed and merged into `main` from the branch `docs/owner-decisions-2026-11-07`. [ADR-0023](adr/0023-owner-decisions-on-the-open-register.md) records them and amends ADR-0004, 0009, 0010, 0012, 0014, 0018, 0021 and 0022, and the same commit corrects the GDD, `CLAUDE.md`, `.claude/rules/content.md` and the `add-incident` and `balance-check` skills. In short, the slice's onboarding is trimmed to one colony and gains a learning measure and a browser smoke test, exam weights apply to incidents only, `verifier` is the approving person and fact entries gain `terms`, the validator runs outside Godot, the nightly fact-check covers facts older than 30 days, an incident has exactly one solution, and the repository stays public.

The repository's remote is `github.com/muxare/LatticeCommand`, and `main` is ahead of `origin/main` by this merge, which has not been pushed. The branches `fix/claude-config-t7-t9`, `docs/adr-baseline` and `docs/owner-decisions-2026-11-07` are merged and can be deleted. No game code, content or test runner exists.

## Waiting on Mikael

1. Say whether to push `main`.
2. The points ADR-0023 leaves open: what measures fun in the slice, where hand-made and bought assets are stored, and whether the nightly job also opens an issue when an entry is due for re-approval. The palette colours for the other three colony types and the practice tests are deferred to Alpha.

## Next, in the suggested order

This order is a suggestion that nobody has confirmed yet.

1. Start Milestone 0, the paper prototype: ten incidents played as cards with a game master, and the simulation rules in a spreadsheet (GDD "Scope and milestones"). The first entries in `content/facts.json` are now unblocked: the main session drafts each from the official documentation, `fact-checker` verifies it, and a person approves it and is named as `verifier` (ADR-0022, ADR-0023). A person who has studied for the certification must approve the incidents. One of the entries should be the exam's question format, which the four-option after-action report rests on.
2. Build `tests/run.gd` and the first failing simulation test ([ADR-0019](adr/0019-test-framework.md), [ADR-0017](adr/0017-test-first-headless-verification.md)), and then add the test command to `CLAUDE.md`.
3. Choose the validator's runtime (Python with `jsonschema` or Node, both outside Godot, per ADR-0023), then build the schemas and the validator. That also unblocks the PostToolUse and Stop hooks.
