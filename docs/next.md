# Next

Last updated 2026-11-09.

## Where the work stands

`main` holds the headless test runner with `sim/pcg32.gd` (ADR-0019, ADR-0020) and the Python content validator (ADR-0025), both merged on 2026-11-09 by rebasing and fast-forwarding. After the rebase the Godot suite ran 13 tests with none failing, the runner's self-test passed, and the validator and its tests passed. The commands for both are in `CLAUDE.md` and `AGENTS.md`. `.venv/` is set up in the main checkout. `main` was last pushed to `origin` on 2026-11-09 at `3588462`, and the commits after it are not pushed. Mikael pushes `main`, because his global hook blocks a push to `main` from a Claude session.

`main` also holds the PostToolUse hook on `content/` and the Stop hook (`5e29a8e`, merged on 2026-11-09), with `tests/hooks_test.sh`, whose 14 cases pass, and the ADR check states recounted to 150 checks: 33 Active, 52 Manual and 65 Pending. The hooks run through `bash` because the scripts are not executable, and Stop runs the Godot import step each time, about a second. They have been exercised only through the test script, so the first live session should confirm them. Prose outside the ADRs' check tables may still call the hooks pending.

`main` also holds the fourteen approved facts in `content/facts.json` and ADR-0026, which amends ADR-0023 on the after-action report's format and renames `CCA-F` to `CCAR-F`, fast-forwarded on 2026-11-09. The superseded branch `content/first-facts` and its worktree are deleted.

## Waiting on Mikael

1. ADR-0026 adds three wrong orders beside a set solution's orders, which the guide does not confirm. The guide calls its questions, options and scenarios confidential, and says its samples come from the practice test, so incidents and after-action reports must not quote or paraphrase them.

Work merges into `main` locally for now, and moves to pull requests later on Mikael's word.

## Next, in the suggested order

1. Draft the ten paper-prototype incidents through `content-writer`, citing the facts in `content/facts.json`. A person who has studied for the certification must approve them.
2. Choose the next simulation rule to build test-first on top of `Pcg32`, such as the tick clock and the event queue (ADR-0020).
3. Sweep the ADR prose outside the check tables for statements the runner, validator, fact sheet and hooks have made stale.
