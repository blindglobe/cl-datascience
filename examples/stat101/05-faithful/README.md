# 05 faithful: Old Faithful geyser

**Question.** How long is a typical eruption, and does a long eruption
mean a long wait for the next one?

**Data.** `datasets::faithful`: 272 eruptions, `eruptions` (duration,
minutes) and `waiting` (minutes to the next eruption). Haerdle (1991).

**The trap.** The distribution has two modes, so the mean is not typical.
The strong correlation is mostly the gap between two clusters. And the
documentation does not say whether rows are in time order. They probably
are, which would make them dependent.

## What R says (reference.out)

| Output | Value |
|---|---|
| mean, sd of eruptions | 3.49, 1.14 min |
| eruptions within 0.5 min of the mean | 13.6% |
| density modes | 1.98 and 4.37 min (36% short, 64% long) |
| Shapiro-Wilk | p = 9e-16 |
| correlation, all / within short / within long | 0.90 / 0.29 / 0.37 |
| lag-1 autocorrelation of eruptions | -0.55 |

## What the wish version asks for (wish.lisp)

- Plain `describe`: the usual summary.
- With checks: a bimodality warning and a suggested split.
- `compare` reports between- versus within-cluster correlation.
- Row order is declared as `:unknown`. The check then reports what the
  autocorrelation suggests and asks for `:time` or `:arbitrary`.
- Random clustering (k-means) carries its seed and versions.

## What the planner says (plan.lisp, tests/stat101-tests.lisp)

| Known | Asked | Plans |
|---|---|---|
| nothing | describe eruptions | describe-continuous |
| two modes (after a check) | describe eruptions | describe-by-modes |
| nothing | waiting explained by eruptions, with inference | assume-rows-independent, ols-fit, robust-se; or with assume-constant-spread, classical-se |
| rows in time order (declared) | same | ols-fit, hac-se |

Declaring the row order removes every plan that needs independent rows;
the time-series standard error (Newey-West) is what remains.

## Findings

| Hint needed | Belongs to | Note |
|---|---|---|
| shape checks in descriptive statistics | stats | checks are not only for models |
| between/within decomposition | statproc | same idea as Simpson in example 04, for continuous data |
| row order (`:time`, `:arbitrary`, `:unknown`) | statframe | new; "unknown" must be declarable |
| reproduction record for random methods | stats | seed, RNG, versions |

Open: the autocorrelation check works without any declaration. Should
checks that need no hints run by default when checks are on? (Proposal:
yes, they cost nothing and change no results.)
