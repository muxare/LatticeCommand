# Next

Last updated 2026-11-09.

## Where the work stands

`main` holds the headless test runner with `sim/pcg32.gd` (ADR-0019, ADR-0020) and the Python content validator (ADR-0025), both merged on 2026-11-09 by rebasing and fast-forwarding. After the rebase the Godot suite ran 13 tests with none failing, the runner's self-test passed, and the validator and its tests passed. The commands for both are in `CLAUDE.md` and `AGENTS.md`. `.venv/` is set up in the main checkout. `main` was pushed to `origin` on 2026-11-09 at `3588462`, and Mikael pushes `main`, because his global hook blocks a push to `main` from a Claude session.

The branch `feat/content-and-stop-hooks` (`b07997c`) adds the PostToolUse hook on `content/` and the Stop hook, with `tests/hooks_test.sh` (14 cases, passing), and corrects `CLAUDE.md`, `AGENTS.md`, the GDD and the ADR check states, whose tally is now 150 checks: 33 Active, 52 Manual and 65 Pending. The hooks' behaviour was checked against the hooks reference on 2026-11-09. The running session that wrote them was not restarted, so they have been exercised only through the test script. Prose outside the ADRs' check tables, such as the Consequences sections of ADR-0009, ADR-0019 and ADR-0025, may still call the hooks pending.

`main` also holds the fourteen approved facts in `content/facts.json` and ADR-0026, which amends ADR-0023 on the after-action report's format and renames `CCA-F` to `CCAR-F`, fast-forwarded on 2026-11-09. The superseded branch `content/first-facts` and its worktree are deleted.

## Waiting on Mikael

1. Review `feat/content-and-stop-hooks`. The new hooks are run through `bash`, because making them executable was denied in the session, and Stop runs the Godot import step each time, which takes about a second.
2. ADR-0026 adds three wrong orders beside a set solution's orders, which the guide does not confirm. The guide calls its questions, options and scenarios confidential, and says its samples come from the practice test, so incidents and after-action reports must not quote or paraphrase them.

Work merges into `main` locally for now, and moves to pull requests later on Mikael's word.

## Next, in the suggested order

1. Draft the ten paper-prototype incidents through `content-writer`, citing the facts in `content/facts.json`. A person who has studied for the certification must approve them.
2. Choose the next simulation rule to build test-first on top of `Pcg32`, such as the tick clock and the event queue (ADR-0020).
3. Sweep the ADR prose outside the check tables for statements the runner, validator, fact sheet and hooks have made stale.
