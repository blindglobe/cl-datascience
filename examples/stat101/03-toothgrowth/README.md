# 03 ToothGrowth: vitamin C dose and delivery method

**Question.** How do dose and delivery method of vitamin C affect tooth
growth in guinea pigs?

**Data.** `datasets::ToothGrowth`: 60 animals, 10 for each combination of
supplement (`OJ` orange juice, `VC` ascorbic acid) and dose (0.5, 1, 2
mg/day); `len` = odontoblast length. Crampton (1947).

**The trap.** Dose was chosen by the investigator. A model with dose as the
response of tooth length fits well and is highly "significant", but it
reverses the design. This is the small version of Rossini's clinical-trial
story, where a causal-network method concluded that the outcome influenced
the randomized treatment.

## What R says (reference.out)

| Analysis | Result |
|---|---|
| two-way ANOVA, dose as factor | supp F 15.6 (p 2e-4), dose F 92.0 (p 4e-18), interaction F 4.1 (p 0.022) |
| dose as a straight line | lack of fit p = 0.00067: the response flattens between 1 and 2 mg for OJ |
| `lm(dose ~ len)` | slope 0.066, p = 1.2e-14, r = 0.80, with no complaint from R |

## What the wish version asks for (wish.lisp)

- Plain tibble: both models run, as in R.
- Declarations of origin (`:set-by-design`, `:observed`) and timing
  (`:assignment` before `:end-of-study`). The declaration is **partial**: how
  animals were assigned to groups is not documented, so it stays undeclared.
- The reversed model is flagged and returned for prediction only.
- `check-design-consistency` returns the violating edge `len -> dose`
  with the two rules it breaks.
- `compare` picks the two-way ANOVA with interaction and says that a causal
  reading relies on the undeclared assignment.

## What the planner says (plan.lisp, tests/stat101-tests.lisp)

| Known | Asked | Plan |
|---|---|---|
| nothing | dose explained by len | ols-fit dose len (as in R) |
| design declared | dose explained by len | **no plan** |
| design declared | predict dose from len | predictive-fit dose len |
| design declared | effects of supp and dose on len | two-way-anova |
| nothing | effects of supp and dose on len | no plan (no design known) |

The rule is a wouldwork **constraint** in `domain.lisp`, not a
precondition of one method: no state may explain a variable that was set
by design or randomized, or a variable by one measured after it. Every
present and future method is held to it. Prediction in the reversed
direction is a different question and stays allowed.

## Findings

| Hint needed | Belongs to | Note |
|---|---|---|
| origin per column | statframe | as planned |
| timing per column | statframe | stages are enough here; no timestamps |
| design-consistency rules | statproc | apply to formulas and to graphs alike |
| "what is still undeclared" in results | statproc | partial declarations must be visible, not silent |

Open: is `:set-by-design` plus balanced cells enough to choose ANOVA over
regression, or should dose-as-factor versus dose-as-number be asked?
