# Next

Last updated 2026-11-09.

## Where the work stands

Mikael's decisions of 2026-11-09 on the three points ADR-0023 left open are committed and merged into `main` as `c1bd451` from the branch `docs/owner-decisions-2026-11-09`, which is deleted. [ADR-0024](adr/0024-fun-measure-asset-storage-and-re-approval-issue.md) records them and amends ADR-0023, and the same change corrects the GDD, `CLAUDE.md` and the ADR index. In short, the slice's exit test measures fun by voluntary play among testers who do not plan to certify, source files of hand-made and bought assets stay in private storage outside the public repository, and the nightly job keeps one rolling issue for facts due for re-approval.

`main` is pushed to `origin/main` up to `24fd962`, and `main` is the only branch. A push to `main` from a Claude session is blocked by Mikael's global hook `~/.claude/hooks/block-dangerous-git.sh`, so Mikael pushes `main`, or the work goes through a pull request. No game code, content or test runner exists.

## Waiting on Mikael

1. Nothing is open before Alpha. The palette colours for the other three colony types and the practice tests are deferred to Alpha, and the validator's runtime is chosen when it is built.

Work merges into `main` locally for now, and moves to pull requests later on Mikael's word.

## Next, in the suggested order

This order is a suggestion that nobody has confirmed yet.

1. Start Milestone 0, the paper prototype: ten incidents played as cards with a game master, and the simulation rules in a spreadsheet (GDD "Scope and milestones"). The first entries in `content/facts.json` are now unblocked: the main session drafts each from the official documentation, `fact-checker` verifies it, and a person approves it and is named as `verifier` (ADR-0022, ADR-0023). A person who has studied for the certification must approve the incidents. One of the entries should be the exam's question format, which the four-option after-action report rests on.
2. Build `tests/run.gd` and the first failing simulation test ([ADR-0019](adr/0019-test-framework.md), [ADR-0017](adr/0017-test-first-headless-verification.md)), and then add the test command to `CLAUDE.md`.
3. Choose the validator's runtime (Python with `jsonschema` or Node, both outside Godot, per ADR-0023), then build the schemas and the validator. That also unblocks the PostToolUse and Stop hooks.
