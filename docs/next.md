# Next

Last updated 2026-11-09.

## Where the work stands

`main` holds the headless test runner with `sim/pcg32.gd` (ADR-0019, ADR-0020) and the Python content validator (ADR-0025), both merged on 2026-11-09 by rebasing and fast-forwarding. After the rebase the Godot suite ran 13 tests with none failing, the runner's self-test passed, and the validator and its tests passed. The commands for both are in `CLAUDE.md` and `AGENTS.md`. `.venv/` is set up in the main checkout. `origin/main` is at `9cc7106`, so the merges and the handoff commits after it are not pushed, and Mikael pushes `main`, because his global hook blocks a push to `main` from a Claude session.

`CLAUDE.md` and `AGENTS.md` are now partly stale. "Project status" still says there is no test runner, and the hooks bullet still says the PostToolUse and Stop hooks wait for tooling that does not exist. Both are corrected with the hooks below.

The branch `content/approved-facts`, from `main`, holds two commits for Mikael to review before it fast-forwards into `main`. The first adds the fourteen facts Mikael approved on 2026-11-09 to `content/facts.json`, with him as `verifier`. The second adds ADR-0026, which amends ADR-0023 so that a report for a set solution is a multiple-response item listing each order separately and stating how many to select, while single-order reports keep four options, and which renames `CCA-F` to `CCAR-F` in the GDD, `CLAUDE.md`, `AGENTS.md` and four ADRs. The validator passes on the branch. The branch `content/first-facts` and its worktree `.claude/worktrees/first-facts` are superseded by it and can be deleted.

## Waiting on Mikael

1. Review `content/approved-facts`, in particular ADR-0026's choice of three wrong orders beside a set solution's orders, which the guide does not confirm. The guide calls its questions, options and scenarios confidential, and says its samples come from the practice test, so incidents and after-action reports must not quote or paraphrase them.

Work merges into `main` locally for now, and moves to pull requests later on Mikael's word.

## Next, in the suggested order

1. Add the PostToolUse hook on `content/**` and the Stop hook, checked against the hooks reference, on a branch. The validator report proposes `"$CLAUDE_PROJECT_DIR"/.venv/bin/python "$CLAUDE_PROJECT_DIR"/tools/validate_content.py 1>&2 || exit 2`, and the Stop hook also runs the test command and guards on `stop_hook_active`. Correct the stale `CLAUDE.md` and `AGENTS.md` lines in the same change, and recount the "Are we on track?" tally in `docs/adr/README.md`, since the merges and `content/facts.json` moved checks from Pending and ADR-0026 adds three.
2. Draft the ten paper-prototype incidents through `content-writer`, citing the facts in `content/facts.json`. A person who has studied for the certification must approve them.
3. Choose the next simulation rule to build test-first on top of `Pcg32`, such as the tick clock and the event queue (ADR-0020).
