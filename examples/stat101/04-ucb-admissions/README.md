# 04 UCBAdmissions: graduate admissions at Berkeley, 1973

**Question.** Were women less likely to be admitted than men?

**Data.** `datasets::UCBAdmissions`: the six largest departments, given as
counts (Admit x Gender x Dept, 24 cells, 4526 applicants). Bickel, Hammel
and O'Connell (1975).

**The trap.** Simpson's paradox. Pooled, men are admitted more often.
Within departments the difference disappears or reverses, because women
applied mostly to departments that admit few applicants.

## What R says (reference.out)

| Analysis | Result |
|---|---|
| pooled admission rate | men 44.5%, women 30.4%; OR (men vs women) 1.84, p 1e-21 |
| within departments | women admitted more often in 4 of 6 |
| Mantel-Haenszel, stratified by dept | OR 0.905, p 0.23 |
| gender x dept interaction | p = 0.0011 (dept A: women 2.9 times the odds) |
| applicant mix | dept A 12% women and 64% admitted; dept C 65% women and 35% admitted |

## What the wish version asks for (wish.lisp)

- The counts must be declared (`:weights :freq` or role
  `:frequency-weight`), otherwise 24 rows are analysed.
- Timing places dept between gender and admission. That gives "the effect
  of gender" two meanings, so the user states which with `:estimand`.
  `:total` gives the pooled answer; `:direct` stratifies by dept.
- The stratified answer warns that one common odds ratio fits poorly
  (interaction), and notes that "direct" only means "within department",
  because qualifications are not in the data.
- With checks on and no estimand, the reversal is reported instead of
  silently picking one answer.

## What the planner says (plan.lisp, tests/stat101-tests.lisp)

| Known | Asked | Plans |
|---|---|---|
| nothing | total effect | **assume-one-row-per-case**, pooled-odds-ratio |
| counts declared | total effect | pooled-odds-ratio |
| counts declared | direct effect | no plan: nothing is known to lie between gender and admission |
| counts and order of events | direct effect | assume-common-odds-ratio, mantel-haenszel; or logistic-by-stratum |
| counts and order of events | total effect | pooled-odds-ratio |

The estimand is the goal, so it is the user's question that decides
between 1.84 (total) and 0.905 (direct), never the planner. The two direct
plans differ in one assumption, which the interaction test (p = 0.0011)
speaks against: a check's result would enter as a fact and remove the
Mantel-Haenszel plan.

## Findings

| Hint needed | Belongs to | Note |
|---|---|---|
| frequency-weight role | statframe | new; R's `as.data.frame(table)` shape is common |
| timing to place a covariate | statframe | same mechanism as example 03 |
| estimand (`:total`, `:direct`) | statproc | new; this is a property of the *question*, not the data |
| reversal and heterogeneity checks | statproc | |

Open: estimand is a third kind of hint, beside data facts (statframe) and
purpose (models). Where does it live: argument only, or also in the
analysis record?
