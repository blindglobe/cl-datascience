# 00 One variable

**Question.** What do these values look like, and what comes next?

**Data.** A.J. Rossini's two datasets from `examples/1d-analysis.lisp`:
stanzas of a song (`A B A B C B`) and how far off pitch a guitar string
plays (`1.2 0.8 1.0 3.2 -2.9`).

**The trap.** Which questions make sense depends on how the values came
about. If the stanzas follow a known song structure, the next one is
known; "the chance of the next stanza" is then not a sensible question.
If they arise by chance, the most likely value and how wrong it could be
are the answer. The data alone cannot tell.

## What R says (reference.out)

| Variable | Description | Next value |
|---|---|---|
| stanza | levels A B C, counts 2 3 1 | B with share 0.50, 95% interval 0.12 .. 0.88 (if random) |
| pitch | mean 0.66, sd 2.21, median 1.0 | 95% prediction interval -6.06 .. 7.38 (if random, normal) |

With 6 and 5 values, both "next value" answers are very uncertain.

## What the planner says (plan.lisp, tests/stat101-tests.lisp)

| Known | Asked | Plan |
|---|---|---|
| nothing | describe stanza | describe-categorical |
| nothing | describe pitch | describe-continuous |
| nothing | next stanza | **assume-random-process**, estimate-category-probabilities |
| song structure known | next stanza | continue-pattern |
| song structure known | stanza probabilities | no plan |
| random process declared | next pitch | estimate-mean-and-spread |

## Findings

- The type of a variable (from its storage type) is enough to choose a
  description. It is not enough to answer "what comes next": that needs
  the data-generating process, which is a declaration.
- Without a declaration the plan states its assumption
  (`assume-random-process`) instead of hiding it.
- A declaration can make a question unanswerable ("chance" for a known
  pattern). The planner returns no plan, which is the correct answer.
