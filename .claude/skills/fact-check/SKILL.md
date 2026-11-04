---
name: fact-check
description: Verifies game content against the fact sheet and its official sources. Use after adding or changing content, or when a Claude feature changes.
context: fork
agent: fact-checker
---

Verify the content named here: $ARGUMENTS

If nothing is named, check every entry in `content/facts.json`. Confirm that each feature named in the content has a fact id, then compare each referenced claim with its source and list the results.
