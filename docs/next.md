# Next

Last updated 2026-11-09.

## Where the work stands

`main` holds the headless test runner with `sim/pcg32.gd` (ADR-0019, ADR-0020) and the Python content validator (ADR-0025), both merged on 2026-11-09 by rebasing and fast-forwarding. After the rebase the Godot suite ran 13 tests with none failing, the runner's self-test passed, and the validator and its tests passed. The commands for both are in `CLAUDE.md` and `AGENTS.md`. `.venv/` is set up in the main checkout. `origin/main` is at `9cc7106`, so the merges and the handoff commits after it are not pushed, and Mikael pushes `main`, because his global hook blocks a push to `main` from a Claude session.

`CLAUDE.md` and `AGENTS.md` are now partly stale. "Project status" still says there is no test runner, and the hooks bullet still says the PostToolUse and Stop hooks wait for tooling that does not exist. Both are corrected with the hooks below.

The branch `content/first-facts`, in the worktree `.claude/worktrees/first-facts`, holds the fourteen checked fact drafts in `docs/fact-drafts/facts.json`. It branches from `63bc926`, before the merges.

## Waiting on Mikael

1. Approve, correct or drop the fourteen draft fact entries on `content/first-facts`. Each was drafted from the official page and checked by `fact-checker`, and approval makes Mikael the `verifier` with the date of approval, after which the entry moves to `content/facts.json`. All fourteen pass the validator. `exam-question-format`, from the certification FAQ, overlaps `exam-item-format` but stays until it is clearly redundant (Mikael, 2026-11-09).
2. Four of the drafts come from the exam guide (`CCAR-F`, version 1.0, effective July 2026). Mikael's copy is `~/source/repos/courses/CCAR-F/CCA-F-ExamGuide.pdf`, identical by SHA-256 to the public URL, and the validator accepts only the guide's folder on its S3 host (ADR-0025 amendment, approved by Mikael on 2026-11-09). Two decisions still wait on Mikael:
   - ADR-0023's four-option report is backed for single-answer items only by example, since all twelve sample questions have four options and one answer. The guide gives no option count and no presentation for multiple-response items beyond "each item states how many responses to select", so ADR-0023 needs a note, and its revisit condition stands.
   - The guide names the exam code `CCAR-F`, while the project writes `CCA-F` throughout.

   The guide calls its questions, options and scenarios confidential, and says its samples come from the practice test, so incidents and after-action reports must not quote or paraphrase them.

Work merges into `main` locally for now, and moves to pull requests later on Mikael's word.

## Next, in the suggested order

1. Add the PostToolUse hook on `content/**` and the Stop hook, checked against the hooks reference, on a branch. The validator report proposes `"$CLAUDE_PROJECT_DIR"/.venv/bin/python "$CLAUDE_PROJECT_DIR"/tools/validate_content.py 1>&2 || exit 2`, and the Stop hook also runs the test command and guards on `stop_hook_active`. Correct the stale `CLAUDE.md` and `AGENTS.md` lines in the same change, and recount the "Are we on track?" tally in `docs/adr/README.md`, since the merges moved checks from Pending.
2. Write the approved facts to `content/facts.json`, then draft the ten paper-prototype incidents through `content-writer`. A person who has studied for the certification must approve them.
3. Choose the next simulation rule to build test-first on top of `Pcg32`, such as the tick clock and the event queue (ADR-0020).
