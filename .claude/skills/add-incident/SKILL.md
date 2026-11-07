---
name: add-incident
description: Scaffolds a game incident from a scenario and answer key. Use when adding a new incident to content/.
---

Interview the user before writing anything. Ask for:

1. The scenario and colony type.
2. The domain and task statement.
3. The concept and the Concord trap it trains against, from the content mapping tables in `lattice-command-gdd.md`.
4. The solution: one correct order, or one set of orders needed together. An incident has exactly one solution, and alternative correct orders are not allowed (ADR-0023).
5. Three or four tempting wrong orders, each with its Concord doctrine and delayed consequence.
6. The fact ids for every feature the incident names.

Look each fact id up in `content/facts.json`. If the file does not exist or an id or claim has no entry, stop and report what is missing, because the content-writer subagent stops without fact ids and no claim may be written from memory.

Then delegate the draft to the content-writer subagent with those answers as a structured brief, which is all it sees of this conversation. Run the remaining steps of the GDD's pipeline on the result, in order, and report each one as passed, failed or not run, with the reason. Stop at a failed step. A step whose tool does not exist yet is not run, which is neither a pass nor a reason to leave it out.

1. **Validate.** Use the schema check from the PostToolUse hook or the content validator listed in `CLAUDE.md`. If neither exists, report "not run: no content validator".
2. **Fact-check.** Run the fact-check skill, naming the new incident file.
3. **Simulate.** Run the balance-check skill on the incident. If it stops because there is no seeded simulation runner, report "not run: no seeded simulation runner".

Report the incident as a draft awaiting approval by a person who has studied for the certification, because AI drafts and humans sign off. Repeat its solution, and list every step not run as still owed, because the incident cannot ship until it has passed.
