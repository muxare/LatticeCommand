# ADR-0026: After-action reports follow the exam guide's item format, and the project uses the guide's exam code CCAR-F

| | |
| --- | --- |
| **Status** | Accepted |
| **Date** | 2026-11-09 |
| **Deciders** | Mikael Axelsson |
| **Sources** | The Claude Certified Architect – Foundations exam guide (version 1.0, effective July 2026), through the fact entries `exam-item-format` and `exam-sample-questions-four-options`; GDD "Design pillars" and "After-action reports"; `CLAUDE.md` opening paragraph |
| **Related** | Amends [ADR-0023](0023-owner-decisions-on-the-open-register.md); touches [ADR-0009](0009-content-as-validated-json.md), [ADR-0012](0012-content-mapping-is-the-contract.md), [ADR-0013](0013-teach-through-play.md) and [ADR-0018](0018-vertical-slice-gate-and-scope.md) |

## Context

ADR-0023 decided that an after-action report shows four options, the correct answer and the three most tempting wrong orders, and that an incident whose solution is a set of orders shows that set as one option. It rested this on the GDD's statement that the exam uses four options, which came from practice tests rather than a documented source, and it required the claim to be checked against the exam's documented format, including how "select TWO" questions are presented, before reports are built at Alpha. It also said the choice is revisited if the exam shows such questions differently.

On 2026-11-09 Mikael Axelsson approved the first fact entries, among them two from the exam guide. `exam-item-format` says the exam has 60 multiple-choice and multiple-response items and that each item states how many responses to select. `exam-sample-questions-four-options` says each of the guide's twelve sample questions has four options, A to D, with one correct answer. The guide gives no option count for the exam as a whole and shows no multiple-response item. So a single-answer item with four options is backed by example, and a multiple-response item is one where the player selects several responses after being told how many, which is not what ADR-0023's "the set as one option" shows. That meets ADR-0023's revisit condition.

The same guide names the exam code `CCAR-F`, while the project had written `CCA-F` throughout. Mikael chose on 2026-11-09 to follow the guide on both points.

## Decision

**A report for a single-order incident is a single-answer item with four options**: the correct order and the three most tempting wrong orders, as ADR-0023 decided and as the guide's samples show.

**A report for an incident whose solution is a set of orders is a multiple-response item.** It must list each order of the solution as its own option, state how many responses to select, and add the three most tempting wrong orders, so a two-order solution gives five options. Showing the set as one combined option, as ADR-0023 decided, is replaced. The number of wrong orders stays at three because the guide states no option count for multiple-response items, and keeping ADR-0023's selection rule changes only the presentation.

**The project names the exam by the guide's code, `CCAR-F`.** The full name, Claude Certified Architect – Foundations, is unchanged. File names outside the repository, such as Mikael's local copy of the guide, are not renamed.

## Alternatives considered

**Keeping the set as one option.** It keeps every report at four options, but the guide says each item states how many responses to select, which only makes sense when the responses are separate, so a combined option teaches a format the exam does not use.

**Four options in total for a multiple-response item.** It keeps a constant option count, but with a two-order solution only two wrong orders remain, so the report drops one of the tempting wrong orders that the incident was written around, and the guide does not ask for it.

**Keeping `CCA-F`.** It is the shorter form and was used throughout, but the official guide is the only documented source for the code, and the fact sheet already cites it.

## Consequences

Reports now follow the only documented source of the exam's format, and the select-two incidents the GDD plans, about 12% of them, rehearse selecting the stated number of responses. The cost is that reports vary in length, the report layout must handle five or more options, and the option count for multiple-response items is a project choice the guide does not confirm, so it can still turn out to differ from the live exam.

The incident schema is unaffected, because the solution is already one list of order ids and the options are taken from the orders.

**On acceptance.** In the same change, the GDD's "Design pillars" and "After-action reports" were corrected, ADR-0023 took the status "Accepted, amended by ADR-0024 and ADR-0026" with a pointer beside the passage this ADR replaces, `CCA-F` was replaced by `CCAR-F` in the GDD, `CLAUDE.md`, `AGENTS.md` and ADR-0009, ADR-0012, ADR-0013 and ADR-0018, and the ADR index was updated.

## Staying on track

| Check | Enforced by | State |
| --- | --- | --- |
| A single-order incident's report shows four options, and a set solution's report lists each order separately, states how many to select and adds three wrong orders | Review of the report's design and code at Alpha | Pending (needs after-action reports) |
| The report's design cites `exam-item-format` and `exam-sample-questions-four-options` | Review of the report's design | Pending (needs after-action reports) |
| Repository text names the exam `CCAR-F` | Pull request review | Manual |

**Drift signals.** A report shows a two-order solution as one option, or omits how many responses to select. A report trims the wrong orders to keep four options. `CCA-F` reappears in a new document.

**Revisit when.** A later version of the exam guide, or another official source, states an option count or shows a multiple-response item, or the exam code changes.
