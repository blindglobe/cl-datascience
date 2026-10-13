# Verbs

Which verbs should the DSL have, and where does each belong? The working
answer from the Statistics 101 examples: **three layers of verbs**. Users
work with the first two. The third is chosen by a planner (wouldwork), from
what is known about the data and what is asked.

```
project verbs    plan -> acquire -> validate -> analyze -> report -> publish
                                                  |
question verbs   declare  describe  compare  relate  predict  check  ...
                     |        \________ each question is a goal ________/
                     | facts                       |
                     v                             v
method actions   welch-t-test  paired-t-test  ols-fit  robust-se  ...
                 (requirements = preconditions, results = effects; planned)
```

Users never have to name a method ("t-test"). They say what they want to
know. Methods stay available to anyone who wants to call one directly.

## 1. Project verbs: the data science activity

From A.J. Rossini's `examples/1d-analysis.lisp`, which sketches two styles:

| Step | Functional sketch | Side-effect sketch |
|---|---|---|
| approve the activity | | `acknowledge/approve-activity` |
| plan: question, data-generating process, design | `plan`, `plan-as-code`, `create-plan-metadata` | `plan-activity` |
| acquire data | `data-source` | `collect` |
| validate data against the plan | `data-validated` | `quality-check` |
| analyze | `execute-analysis` | `execute-activity`, `analyse-data` |
| keep the record | (in the report) | `store-analysis` |
| report | `report` | `report-analysis` |
| publish to targets (PDF, Quarto, Word, CMS) | `publish` | (`:report-target`) |

The plan comes first; the data are validated against it. In the examples the
plan's content is the `:knowledge` of each `plan.lisp`: what is declared
about the data before any method runs.

## 2. Question verbs: what the user asks

Each question verb is a **goal** for the planner. In the examples:

| Verb | Question | Goal (wouldwork relation) | Examples |
|---|---|---|---|
| `declare` | what do we know about the data? | adds facts, no goal | all |
| `describe` | what does a variable look like? | `(described v)` | 00, 05 |
| `predict-next` | what comes next? | `(predicted-next v)`, `(estimated-probabilities v)` | 00 |
| `compare` | do groups differ, by how much? | `(estimated-difference> y g)` | 01 |
| `compare` with a design | what are the effects of the design factors? | `(explained-by-design> y a)` | 03 |
| `compare` with an estimand | total or direct effect? | `(estimated-total-effect> y x)`, `(estimated-direct-effect> y x)` | 04 |
| `relate` | how does y change with x? | `(estimated-trend> y x)` | 02, 03 |
| `relate` for inference | how sure are we about the trend? | `(inferred-trend> y x)` | 02, 05 |
| `predict` | what y for a new x? | `(prediction-interval> y x)`, `(predicted-from> y x)` | 02, 03 |
| `check` | do the assumptions hold? | runs a check; its result becomes a fact, then the question is planned again | 02, 05 |
| `simulate` | what data would this model produce? | not yet in an example | |
| `conclude` | what do we decide, on which scale? | not yet in an example | |

The purpose of a result (trend, inference, prediction) and the estimand
(total, direct) are part of the question, so they are part of the goal.

## 3. Method actions: chosen by the planner

`examples/stat101/domain.lisp` defines 25 actions in wouldwork syntax:

- describe: `describe-categorical`, `describe-continuous`, `describe-by-modes`
- next value: `continue-pattern`, `estimate-category-probabilities`, `estimate-mean-and-spread`
- two groups: `welch-t-test`, `paired-t-test`, `signed-rank-test`
- designed experiments: `two-way-anova`
- binary outcome: `pooled-odds-ratio`, `mantel-haenszel`, `logistic-by-stratum`
- regression: `ols-fit`, `classical-se`, `robust-se`, `hac-se`,
  `normal-prediction-interval`, `spread-model-prediction-interval`, `predictive-fit`
- assumptions: `assume-random-process`, `assume-rows-independent`,
  `assume-constant-spread`, `assume-common-odds-ratio`, `assume-one-row-per-case`

An action's **precondition** is what the method requires and its **effect**
is what it delivers. This is A.J. Rossini's 2009 design in
common-lisp-stat (`procedures/ttest.lisp`: a procedure lists the variables
it requires and checks the data with `proc-consistent-data-p`), written so
that a planner can search over it.

Design-consistency rules are wouldwork **constraints** rather than
preconditions, so every method, present or future, is held to them.
Example 03: nothing may explain a variable set by design, or a variable by
one measured after it.

## How optional declarations work

- With **nothing declared** the planner still finds a plan: R's default
  method, with the assumption R makes silently as an explicit step
  (`assume-rows-independent`, `assume-one-row-per-case`, ...).
- A **declaration** that contradicts an assumption removes every plan that
  needs it (01: pairing removes Welch; 05: time order removes independence).
- A declaration can make a question **unanswerable** (00: "chance" for a
  known pattern) or **answerable** (04: a direct effect needs the order of
  events).
- Rossini's `:assumptions (apply ignore explore)` from common-lisp-stat
  maps onto this. *Apply* means an assumption must be declared. *Ignore*
  means it may be assumed, and the plan records it. *Explore* means every
  plan is listed, as `find-plans` does.

## Plan, run, replan

Only what is known before a method runs can be planned. Checks whose result
depends on the values (is the spread constant? are there two modes? does the
interval leave the domain?) are run, and their result enters as a new fact.
Then the question is planned again (examples 02, 05: the `spread-checked` and
`bimodal` knowledge). This keeps the planner classical (deterministic
actions) while the analysis reacts to the data.

## Open questions

- Should `compare`, `relate` and `predict` stay separate verbs, or should
  `compare` cover relations too, as in Rossini's `compare :comparison`?
- Where do declarations live: in the project plan (`plan-as-code`), on the
  data, or both, with the plan as the source?
- Ranking: when several plans remain, prefer fewer assumptions (fewer
  `assume-` steps)? Then 02 would prefer `robust-se` over `classical-se`.
