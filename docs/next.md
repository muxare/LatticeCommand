# Next

Last updated 2026-11-09.

## Where the work stands

`main` is at `2a7bf7c`, which adds the Codex mirrors (`AGENTS.md`, `.agents/skills/`, `.codex/agents/`). Their drafts came from a blind Claude-to-Codex replacement that renamed the certification, the API and the `.claude/` paths, and those were restored before the commit. `origin/main` is at `24fd962`, so `f4c839d` and `2a7bf7c` are not pushed. A push to `main` from a Claude session is blocked by Mikael's global hook, so Mikael pushes `main`.

Two branches are committed, tested and waiting for Mikael's review. Neither is merged or pushed.

- `feat/test-runner-and-pcg32`, in the worktree `.claude/worktrees/agent-a12af0226113a6bb3`, holds `tests/run.gd` with its broken-fixture self-test (12 fixtures) and `sim/pcg32.gd` pinned to ADR-0020's golden values, with 13 tests passing. `sim-reviewer` found two ways the runner could report a false pass and that `assert` behaves differently in release builds. All were fixed test-first, and ADR-0019 and ADR-0020 record what building it corrected.
- `feat/content-validator`, in the worktree `.claude/worktrees/agent-ade9beb9211486546`, holds `tools/validate_content.py` with schemas in `tools/schemas/` and 38 invalid fixtures, with its tests passing. [ADR-0025](adr/0025-content-validator-in-python.md) records the Python choice, the schema location and the fact-source host allowlist, which includes `anthropic-partners.skilljar.com` for the exam FAQ.

Both branches replace the same sentence in `CLAUDE.md` and `AGENTS.md` (the commands list), so the second to merge needs that hunk combined by hand.

## Waiting on Mikael

1. Review and approve the two branches above for merging.
2. Approve or correct the ten draft fact entries, which are not yet in the repository. Each was drafted from the official page and checked by `fact-checker`, and approval makes Mikael the `verifier` with the date of approval. The draft passes the validator on `feat/content-validator`. The drafts were at `/private/tmp/claude-501/-Users-mikaelaxelsson-source-repos-AnthropicEducation-LatticeCommand/ae8e10e9-2c83-4819-abfe-6765ecc993f9/scratchpad/facts-draft.json` on 2026-11-09, which is temporary; if it is gone, redraft from the fact-check notes in the session.
3. The exam's four-option format, on which the after-action report rests (ADR-0023), has no official source. The certification FAQ says only "multiple choice and scenario-based multiple response questions". The option count and the way select-two questions are shown are probably in the CCA-F exam guide on the Partner Academy certification page, which may need a login.

Work merges into `main` locally for now, and moves to pull requests later on Mikael's word.

## Next, in the suggested order

1. After the merges, add the PostToolUse hook on `content/**` and the Stop hook, checked against the hooks reference. The validator report proposes `"$CLAUDE_PROJECT_DIR"/.venv/bin/python "$CLAUDE_PROJECT_DIR"/tools/validate_content.py 1>&2 || exit 2`, and the Stop hook also runs the test command and guards on `stop_hook_active`. Then recount the "Are we on track?" tally in `docs/adr/README.md`, since both branches move checks from Pending.
2. Write the approved facts to `content/facts.json`, then draft the ten paper-prototype incidents through `content-writer`. A person who has studied for the certification must approve them.
3. Choose the next simulation rule to build test-first on top of `Pcg32`, such as the tick clock and the event queue (ADR-0020).
