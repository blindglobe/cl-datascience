# Statistics 101 examples

Examples first: before the DSL is designed, textbook analyses are written
the way they should read. Each is checked against R, and the choice of
methods is already run by a planner. The examples show which verbs,
components and hints the DSL needs (see `docs/VERBS.md`).

## Layout of one example

```
00-one-variable/
  README.md       question, data, the trap, R's answer, the planner's answer, findings
  reference.R     the analysis in R (base R), run with uvr
  reference.out   its output (generated)
  expected.json   the numbers a Lisp version must reproduce (generated)
  *.csv           the data (generated)
  plan.lisp       for the planner: objects, facts, states of knowledge, questions
  wish.lisp       how the analysis should read in the DSL (design sketch, does not load)
```

Shared: `domain.lisp` (the method actions for the planner),
`reference-lib.R`, `run-references.sh`, and the uvr project (`uvr.toml`,
`uvr.lock`).

## Running

Tests: the planner must find exactly the plans stated in
`tests/stat101-tests.lisp`. Run them with both supported setups:

```sh
scripts/test.sh            # SBCL + ~/quicklisp, then Roswell
scripts/test.sh sbcl
scripts/test.sh ros
```

In a REPL:

```lisp
(ql:quickload :cl-datascience)
(clds:example-plans "01-sleep" :plain :difference)
;; => (((:ASSUME-ROWS-INDEPENDENT :SLEEP) (:WELCH-T-TEST :EXTRA :GROUP)))
(clds:example-plans "01-sleep" :repeated :difference)
;; => (((:PAIRED-T-TEST :EXTRA :GROUP :ID)) ((:SIGNED-RANK-TEST :EXTRA :GROUP :ID)))
```

R references (R 4.6.1 via uvr):

```sh
examples/stat101/run-references.sh
```

## Catalogue

| Example | Trap | Planner shows |
|---|---|---|
| [00 one variable](00-one-variable/) (A.J. Rossini's datasets) | the data-generating process decides which questions make sense | next value needs a declared or assumed process; "chance" of a known pattern has no plan |
| [01 sleep](01-sleep/) | paired data analysed as two groups (p 0.079 vs 0.0028) | declaring the pairing replaces Welch by the paired tests |
| [02 cars](02-cars/) | spread grows with speed; matters for prediction, hardly for the slope | the purpose (trend, inference, prediction) decides which assumptions a plan needs |
| [03 ToothGrowth](03-toothgrowth/) | `lm(dose ~ len)` fits "significantly" but reverses the design | a constraint forbids explaining a design variable; prediction stays allowed |
| [04 UCBAdmissions](04-ucb-admissions/) | Simpson's paradox; data given as counts | counts must be declared or assumed; the estimand (total, direct) is the goal |
| [05 faithful](05-faithful/) | two modes; rows probably in time order | a check's result (two modes) or a declaration (time order) changes the plan |

Planned next tiers: basic bioinformatics (paired differential expression;
sequences to a tidy table), then LLM/AI (an LLM proposes an analysis plan
that the planner checks against the declared facts; leakage across a
declared grouping; two models compared on the same prompts).

## What the examples found

Kinds of hint and where they live:

| Kind | Examples | Lives in | In the planner |
|---|---|---|---|
| facts about the data (type, pairing, origin, timing, counts, row order) | all | the data or the plan | initial facts (`:facts`, `:knowledge`) |
| results of checks (spread, modes) | 02, 05 | the analysis record | facts added after the check, then plan again |
| the question, including purpose and estimand | 02, 04 | the verb call | the goal |
| what a method requires and delivers | all | the method library | action preconditions and effects |
| rules no analysis may break (design consistency) | 03 | the method library | wouldwork constraints |
| assumptions R makes silently | 00, 01, 02, 04, 05 | the plan | `assume-...` steps, only when needed |

Five observations:

1. **Requirements as data work.** Each method's precondition is the list
   of what it needs, as in Rossini's 2009 `ttest.lisp`, and the planner
   does the dispatch. No method is chosen by a hand-written `if`.
2. **Optional declarations come for free.** A plain dataset gets R's
   default method, with R's silent assumptions spelled out as plan steps.
3. **Declarations remove plans, never add surprises.** Every change in
   the tests is a declaration ruling out an assumption, or making a
   question answerable.
4. **The question belongs in the goal.** Purpose (02) and estimand (04)
   are not facts about the data.
5. **Checks are not planned.** Their outcome depends on the values, so
   they feed facts back for the next round of planning.

## Wouldwork notes

See AGENTS.md: the `product` header for several same-type parameters
(a wouldwork bug otherwise crashes small examples), `>` for directional
relations, staging side effects.
