---
paths:
  - "content/**"
---

# Content

Every technical claim lives in `content/facts.json` with `id`, `claim`, `source`, `verified`, `verifier`, `domains` and `terms`. `verifier` is the person who approved the entry, never a subagent, and `terms` lists the feature names the entry backs. Incidents, tooltips and after-action reports reference fact ids and never carry free text about features, and no feature name may appear without a fact entry.

Each incident holds the scenario, the colony type, the domain and task statement, the solution (one correct order, or one set of orders needed together, never alternatives), three or four wrong orders each tagged with its Concord doctrine, the delayed consequence of each wrong order, fact ids and the exam-format rewrite. Incidents are hand-authored and original, and they must not reproduce real exam items.
