# ADR-0009: Incidents, doctrines, tech nodes and the fact sheet are JSON files validated by JSON Schema in CI, so content is added without touching code

| | |
| --- | --- |
| **Status** | Accepted, amended by [ADR-0023](0023-owner-decisions-on-the-open-register.md) |
| **Date** | 2026-11-04 |
| **Deciders** | Mikael Axelsson |
| **Sources** | `lattice-command-gdd.md` ("Content pipeline and fact accuracy", "Repository layout", "Hooks", "CI with Claude Code", "Out of scope for 1.0", "Risks"); `CLAUDE.md` ("Architecture", "Content and fact accuracy", "Claude Code setup") |
| **Related** | [ADR-0001](0001-record-architecture-decisions.md), [ADR-0005](0005-three-layer-split.md), [ADR-0010](0010-fact-sheet-single-source.md), [ADR-0011](0011-hand-authored-incidents-human-signoff.md), [ADR-0012](0012-content-mapping-is-the-contract.md), [ADR-0019](0019-test-framework.md), [ADR-0021](0021-ci-on-github-actions.md) |

## Context

The game needs at least 60 incidents at launch, each with the same long list of required parts: a scenario, a colony type, a domain and task statement, the correct order or orders, three or four tempting wrong orders tagged with their doctrines, the delayed consequence of each wrong order, fact ids and an exam-format rewrite. Designers and the content-writer subagent both produce this material, and the GDD names a schema as the mitigation for the risk that hand-authored content does not scale evenly. If content lived in code, each new incident would be a code change, and a missing wrong-order consequence would surface only when somebody played that incident.

## Decision

Incidents, doctrines, tech nodes and the fact sheet live in `content/` as JSON. Each kind of file must validate against a JSON Schema, and CI must fail the build when a file does not validate. The incident schema must require every part listed in the GDD's "Incident schema" section. Adding an incident that uses existing simulation rules must not require a change in `sim/`, `scenes/` or `ui/`, and incident text must not be hard-coded in those directories.

Authors get the same check earlier: a PostToolUse hook on `content/**` runs the validator and returns its errors immediately, as the GDD's "Hooks" table specifies. The hook is added together with the validator, as `CLAUDE.md` requires.

The 1.0 content covers the CCAR-F and its supporting courses only. The GDD says the schema "leaves room for future certifications as new campaigns", so the schema must not make a second campaign impossible. The sources do not say how it leaves that room, and this ADR adds no campaign field or other mechanism on their behalf. Nothing beyond the CCAR-F is built for 1.0.

Two points stay open. JSON Schema validates the shape of a document, while the GDD also expects "the validator" to fail the build when content names a feature without a fact id, which needs cross-file and text checks that a schema cannot express. The project therefore needs a validator that does more than run schemas, although `CLAUDE.md` describes only the schema. The implementation is also undecided. The GDD has Godot headless run content validation in CI, but the API dump of the pinned Godot 4.7.2 build lists `JSON` and `JSONRPC` and no JSON Schema class, so the work needs either a validator written for the project or a separate tool in CI. Neither [ADR-0019](0019-test-framework.md) nor [ADR-0021](0021-ci-on-github-actions.md) settles that choice, so it needs a decision before the validator is built; the location of the schema files is likewise unstated. [ADR-0023](0023-owner-decisions-on-the-open-register.md) settles the implementation as a standard JSON Schema validator outside Godot plus a project script, with feature names recognised through the fact sheet's `terms`, and leaves the schema location unstated.

## Alternatives considered

**Content as GDScript constants or classes**, considered while writing this ADR. It would give the parser's checks for free and would need no separate validator, but every incident would become a code change, which is the outcome the stated reason for this decision is meant to avoid.

**Content as Godot Resource files (`.tres`)**, considered while writing this ADR. These offer editor support and typed fields, but a JSON Schema cannot validate them, so the CI check the sources specify would not apply, and the content format would become an engine type in a project whose simulation layer avoids engine calls.

## Consequences

An incident can be drafted, validated and reviewed as data, and the content-writer subagent has a precise target. Structural errors surface when a file is written rather than when somebody plays it.

The promise has a limit: content is free of code only while it uses mechanics the simulation already has. An incident that needs a new rule still needs simulation work and a test. The project also takes on a validator it must build and maintain, schema changes that must migrate every existing file, and long prose inside JSON strings, which is awkward to write and to diff. Whether the web export packs the JSON files is untested, because the preset uses `export_filter="all_resources"` with an empty include filter and there is no content or main scene to try it with.

## Staying on track

| Check | Enforced by | State |
| --- | --- | --- |
| Every file in `content/` validates against its schema, and a failure fails the build | Content validator in a CI job | Pending (needs the CI workflow from [ADR-0021](0021-ci-on-github-actions.md)) |
| Validation errors return to the author after each edit under `content/**` | PostToolUse hook `.claude/hooks/validate-content.sh`, wired in `.claude/settings.json` on 2026-11-09 | Active |
| Sessions working in `content/**` are told what an incident must hold | Path-scoped rule `.claude/rules/content.md`, which instructs but does not enforce | Active |
| Adding an incident changes nothing outside `content/` unless it needs a new rule | Pull request review | Manual |
| The JSON content is present and loads in the exported web build | A check on the web export | Pending (needs a main scene, first content and the CI workflow) |

**Drift signals.** A `.gd` file under `sim/`, `scenes/` or `ui/` contains scenario text, or branches on a specific incident id. A schema field becomes optional in the same pull request that adds a file lacking it. An incident carries fields that the schema does not describe. The validator lands and the PostToolUse hook does not. A domain list hard-wired across the validator and the simulation makes the CCAR-F's five domains impossible to replace.

**Revisit when.** A required rule cannot be expressed by the schema and validator together, authors routinely need code changes to add ordinary incidents, the release's localization hooks need text to leave these files, or a second certification campaign is actually planned.
