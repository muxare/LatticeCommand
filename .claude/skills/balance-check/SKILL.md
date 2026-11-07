---
name: balance-check
description: Runs seeded simulations of the game and reports resource curves, and checks that an incident's correct orders, and nothing else, resolve it at the causal layer. Use after changing simulation rules or incidents.
---

The seeded simulation runner has not been built yet. If the project commands in `CLAUDE.md` do not list one, say so and stop rather than estimating results. Report the check as not run, never as passed.

The solution is what the incident needs to resolve: one correct order, or one set of orders that work only together. An incident has exactly one solution and no alternatives (ADR-0023). If the incident does not state its solution plainly, ask the user rather than inferring it.

Play each affected incident under the same fixed seeds and horizon, with:

1. No order, as the control.
2. The solution, issuing all of a set's orders at once.
3. Each smaller part of the solution when it is a set, which for two orders means each order alone.
4. Each wrong order alone.
5. The solution, when it is a set, with one order swapped for each wrong order, which is the half-right answer to a "select TWO" question.

An early result proves nothing, because a fix at the wrong layer appears to work and then the incident recurs or the Concord exploits it. The horizon must pass the latest delayed consequence the incident declares and anything a play still has scheduled. If a play ends before that, or no horizon can be stated, the result is inconclusive.

A play resolves the incident only if a fix at the causal layer closes it and it has neither recurred nor been exploited by the end of the horizon. The check fails if, under any seed:

- the solution does not resolve the incident;
- any other play in the list resolves it;
- a wrong order's declared delayed consequence does not surface, or the incident log does not trace it back to that order.

Report the resource curves and, for each play and seed, its result and the ticks at which the incident appeared to close and at which it recurred or was exploited. Name the orders, seed and tick of every failure so that it can be replayed. The check passes only if nothing failed and nothing was inconclusive, and a pass is evidence for the human reviewer, not approval.
