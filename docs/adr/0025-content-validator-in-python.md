# ADR-0025: The content validator is Python with a pinned `jsonschema`, its schemas live in `tools/schemas/`, and fact sources come from an allowlist of official hosts

| | |
| --- | --- |
| **Status** | Accepted |
| **Date** | 2026-11-09 |
| **Deciders** | Mikael Axelsson |
| **Sources** | `lattice-command-gdd.md` ("Content pipeline and fact accuracy", "Repository layout", "CI with Claude Code"); `CLAUDE.md` ("Content and fact accuracy", "Claude Code setup") |
| **Related** | [ADR-0009](0009-content-as-validated-json.md), [ADR-0010](0010-fact-sheet-single-source.md), [ADR-0020](0020-fixed-step-clock-and-numerics.md), [ADR-0021](0021-ci-on-github-actions.md), [ADR-0023](0023-owner-decisions-on-the-open-register.md) |

## Context

[ADR-0023](0023-owner-decisions-on-the-open-register.md) settled that content is checked by a standard JSON Schema validator outside Godot plus a project script, and left the runtime to be chosen when the validator was built. On 2026-11-07 the machine had the system Python 3.9.6 without `jsonschema` and Node from Homebrew, so either choice adds a dependency to the hooks and CI. [ADR-0009](0009-content-as-validated-json.md) also left the location of the schema files unstated. The validator was built on 2026-11-09, and the first fact entries showed that the official source of the exam's format is not on a documentation host at all.

## Decision

The validator is `tools/validate_content.py`, run with Python 3.9 or later and the `jsonschema` package, with every dependency pinned in `tools/requirements.txt` and installed into a gitignored `.venv/` at the repository root. Mikael chose Python on 2026-11-09, on the session's recommendation that it is the smaller dependency for CI. The validator must exit non-zero on any error, print each error as `file: JSON pointer: message`, and pass on an empty `content/`.

The schemas live in `tools/schemas/`, outside `content/`, so that every file under `content/` is game data that must validate. A file under `content/` that no schema covers must fail, so a new kind of content arrives with its schema. `tools/.gdignore` keeps the tools, schemas and broken fixtures out of the Godot project and its exports.

A fact's `source` must be an `https` URL on one of `code.claude.com`, `platform.claude.com`, `docs.claude.com`, `docs.anthropic.com`, `support.claude.com` or `anthropic-partners.skilljar.com`. The last host is Anthropic's Partner Academy, which hosts the certification pages and their FAQ (`clau.de/CCAF` redirects there), and it is allowed because it is the only official source found for the exam's format. Adding a host needs a superseding ADR or an amendment that names the official content it serves.

*Amended on 2026-11-09.* The Claude Certified Architect – Foundations exam guide (version 1.0, effective July 2026, exam code `CCAR-F`) is a PDF served from `everpath-course-content.s3-accelerate.amazonaws.com`, the storage host behind Partner Academy. It is public with no login, and Mikael's copy matched the download byte for byte. That host is shared by every Partner Academy customer, so it is allowed only under the path prefix `/instructor%2F6nizmqk8tpzpfjvt6qmmav7rh%2F`, the folder that holds the guide, and any other folder on it fails. Mikael approved allowing it on 2026-11-09. The guide is the only official source found for the exam's item count, item format, scenarios and domain weights.

Where the GDD left a field's shape open, the validator's choices stand until an incident proves one wrong. They are listed in the commit that added the schemas, and the material ones are these: `facts.json` is an array; an incident lists all its orders once, the solution is one list of order ids, and each order is either in the solution or a wrong order; a wrong order's consequence carries `delay_ticks`, an integer from 1 to 2^40 relative to the order; no content number may be written with a fraction or exponent; and the glossary check is case-insensitive on whole words and fails closed.

## Alternatives considered

**Node with Ajv.** Node was already installed, and Ajv is a fast, widely used validator. It lost because Python is the default on macOS and on GitHub's Ubuntu runners, so CI needs only `pip install`, and the cross-file checks read more plainly in Python.

**Schemas in `content/schemas/`.** Keeping schemas beside content is common. It lost because the validator would then have to exempt part of `content/`, and the rule that every file under `content/` validates would no longer be simple.

## Consequences

The PostToolUse and Stop hooks and the CI content job can now be built, and authors get the same errors locally as in CI. The costs: every checkout needs the `.venv` set up once, hooks that call the validator fail on a machine without it, and the pinned packages need occasional upgrades. The strict glossary check will flag common words that are also terms until the fact id is added, which is intended but may be noisy. The `exam_rewrite` field holds only the stem, and nothing yet records which three of four wrong orders are the most tempting; that needs a field or a rule before after-action reports are built at Alpha.

## Staying on track

| Check | Enforced by | State |
| --- | --- | --- |
| The validator passes valid fixtures and fails each invalid fixture with exactly its expected errors | `python -m unittest` under `tools/tests/` | Active (run by hand; CI pending [ADR-0021](0021-ci-on-github-actions.md)) |
| Every file in `content/` validates | `tools/validate_content.py` | Active (PostToolUse hook `.claude/hooks/validate-content.sh`, Stop hook `.claude/hooks/stop-checks.sh` and by hand); the CI job is Pending |
| A fact source outside the allowlist fails | Facts schema | Active |

**Drift signals.** A file appears under `content/` with no schema and the validator is changed to skip it. A host is added to the allowlist without an ADR. `requirements.txt` gains an unpinned package. Content edits pass locally because `.venv` is missing and the hook's failure was ignored.

**Revisit when.** CI cannot install the pinned packages, the validator's run time makes the PostToolUse hook slow, or an official source for a fact lives on a host not listed here.
