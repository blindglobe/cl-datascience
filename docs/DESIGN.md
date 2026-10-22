---
title: "A Language for Data Science Practice"
subtitle: "Design of the verbs and the DSL for cl-datascience"
author: "Gwang-Jin Kim, for A.J. Rossini"
date: "Draft 0.1, 13 October 2026"
---

# Summary {-}

`cl-datascience` aims at "tools to build a philosophy for data science
practice, enforced through a DSL" (README). This document proposes what
that DSL consists of. Its centre is a set of **verbs** in three layers,
and a way to turn what is known about a study into the choice of analysis.

The proposal in ten points:

1. **Users ask questions, not methods.** `compare`, `relate`, `describe`,
   `predict` say what is wanted. The method (Welch, paired t-test,
   Mantel-Haenszel, ...) is chosen from what is known about the data.
2. **Three layers of verbs.** *Project verbs* carry a data science activity
   from plan to publication (from A.J. Rossini's sketch). *Question verbs*
   ask. *Method actions* answer; they are chosen by a planner.
3. **A general problem solver does the choosing.** Each method is an
   operator whose preconditions are its requirements and whose effects are
   what it delivers, as in GPS and its successors. The solver is generic
   (the wouldwork planner); all statistical knowledge sits in rules and in
   the data representation.
4. **Declarations are optional.** With nothing declared the system behaves
   like R and does what R does, but it writes the assumptions R makes
   silently into the plan. Declarations only remove plans whose assumptions
   they contradict, or make a question answerable.
5. **Assumptions are graded, not forbidden.** Hard rules (no mean of a
   nominal variable; nothing explains a randomized variable) are
   constraints. Soft rules (normality for a t-test) can be assumed and are
   recorded. Preferences rank what remains. Rossini's 2009
   `:assumptions (apply ignore explore)` becomes three planning modes.
6. **The plan comes first.** Design facts (block and treatment structure,
   origin and timing of each variable, the data-generating process) are
   declared in the plan and validated against the data.
7. **Rules come from the literature, with sources.** Statistics textbooks
   for medicine, pharmacy, psychology and sociology, experimental design
   books and regulatory guidance (ICH E9(R1)) are encoded as rules. Each
   rule cites its source; disagreements stay visible.
8. **Checks feed facts back.** Whatever depends on the values (is the
   spread constant? two modes?) is run, becomes a fact, and the question is
   planned again.
9. **Everything is recorded and checked against R.** Each result carries
   its plan, assumptions, alternatives and provenance. Every example has an
   R reference (run with uvr) whose numbers a Lisp version must reproduce.
10. **Examples first.** Six Statistics 101 examples already run through the
    planner (50 tests). Further tiers: experimental design, clinical trials,
    basic bioinformatics, LLM/AI.

What exists today and what is proposed is marked throughout. Section 14
lists the decisions this draft asks Rossini to take.

# Goal and scope

Rossini's sketch (`examples/1d-analysis.lisp`) describes a data science
project in its simplest form: a question is posed, information is
collected and analysed to address the question, with iterations that may
improve the question, add data, or restart the activity. It then asks for
four things before and during analysis:

1. data appropriate to the question, which requires knowing the
   data-generating process;
2. understanding how approximations reduce confidence;
3. the same check for the planned analysis: do its assumptions match the
   data, and the question?
4. execution with diagnostics on the data, the strategy, their interplay,
   and the reasonableness of the conclusions.

The DSL must make these steps explicit and, where possible, computable.
It must also stay usable for everyday work: the same code must run without
any of it.

**In scope:** verbs and their semantics, the DSL surface and its defining
forms, the data representation the solver needs, the rule base and its
sources, the solver, execution and record, reporting.
**Not in scope here:** numerical algorithms (taken from existing Lisp
libraries or R), user interfaces, storage back ends.

# Design principles

**P1 Questions, not methods.** A verb names what the user wants to know.
Methods remain callable directly, but choosing them is the system's job.

**P2 Optional, graded semantics.** Every declaration is optional. A plain
table gets R's default analysis with its assumptions made explicit.
Declarations narrow the choice; they never add hidden behaviour.

**P3 No silent assumptions.** Any assumption a method relies on and that is
not a declared fact appears as a step of the plan (`assume-...`) and in the
record.

**P4 Requirements as data.** What a method needs and delivers is data
(rules), not code branching. The solver is generic. Adding a method means
adding a rule.

**P5 Plan first.** Facts about design and data generation belong to the plan
of the study. Data are validated against the plan.

**P6 Reference results.** Every method and example is checked against an
established implementation (R, pinned with uvr).

**P7 Inform, do not override.** Checks report; they become facts; they never
silently switch methods behind the user's back.

**P8 Everything is recorded.** Declarations, plans, assumptions, checks,
overrides and versions form an analysis record that can be reviewed before
results leave the team.

# Architecture

```
project verbs   approve plan acquire validate analyze record report publish
                                       |
declarations    scale structure origin timing process counts units
                                       |
                               facts (statframe)
                                       |
question verbs  describe compare relate predict check simulate conclude
                                       | goal
                                       v
solver          rule base --compile--> planner (wouldwork) --> plans
                                       |
execution       methods: Lisp, R via uvr, later Python
                                       |
record          result objects, analysis record, reproduction envelope
                                       |
report          templates: Markdown, Quarto, PDF, corporate; checklists
```

Proposed packages (only `cl-datascience` with the planner bridge exists):

| Package | Role | Status |
|---|------|-----|
| `clds` | verbs, result objects, user package `clds-user` | partly (planner bridge, example reader) |
| `clds.frame` | statframe: data plus declarations; fact extraction; propagation through table verbs | proposed |
| `clds.rules` | `define-method`, `define-check`, `define-constraint`, `define-question`; rule base | proposed (25 hand-written actions today) |
| `clds.plan` | compile rules to wouldwork; plan, rank, replan | exists as `find-plans` |
| `clds.exec` | run methods: native Lisp, R via uvr, later Python | proposed |
| `clds.record` | analysis record, provenance, reproduction envelope | proposed |
| `clds.report` | report and publish through templates; reporting checklists | proposed |

Table operations come from the Common Lisp tidyverse packages (cl-tibble,
cl-dplyr, cl-tidyr, ...): filter, mutate, summarise, pivot and joins. They
are not redesigned here, but they must carry declarations through (section
6.5).

# The verbs

## Overview

| Layer | Verbs | Who uses them | Becomes |
|----|--------|------|------|
| Project | `approve`, `plan`, `acquire`, `validate`, `analyze`, `record`, `report`, `publish` | analyst, team | steps of an activity |
| Declaration | `declare-scale`, `declare-structure`, `declare-origin`, `declare-timing`, `declare-process`, `declare-counts`, `declare-units`, `declare-provenance` | analyst, plan author | facts |
| Question | `describe`, `compare`, `relate`, `predict`, `predict-next`, `check`, `simulate`, `conclude` | analyst | goals |
| Inspection | `plans`, `explain`, `alternatives`, `assumptions`, `record` | analyst, reviewer | views of the plan and record |
| Method | `welch-t-test`, `paired-t-test`, `ols-fit`, `robust-se`, `mantel-haenszel`, ... | the solver; experts directly | actions |
| Table | `filter`, `mutate`, `select`, `summarise`, `pivot-wider`, joins, ... | everyone | data operations that carry declarations |

## Project verbs

Rossini's sketch has two styles: a functional one (`plan-as-code`,
`data-validated`, `execute-analysis`, `report`, `publish`) and one with
side effects (`acknowledge/approve-activity`, `plan-activity`,
`execute-activity` with `collect`, `quality-check`, `analyse-data`,
`store-analysis`, `report-analysis`). The proposal keeps both: a functional
core where every verb returns a value, and a project object whose verbs
record what they did.

| Verb | Rossini's names | Input | Output | Side effect (project style) |
|------|----------------|--------|--------|---------|
| `approve` | `acknowledge/approve-activity` | resources, approvers | approval record | stored with the project |
| `plan` | `plan`, `plan-as-code`, `plan-activity`, `create-plan-metadata` | question(s), data sources, declarations, analyses | plan object | stored, versioned |
| `acquire` | `data-source`, `collect` | data source (URI, database, pointer) | raw data | provenance recorded |
| `validate` | `data-validated`, `quality-check` | plan, raw data | statframe (data plus checked declarations) or validation report | failures recorded |
| `analyze` | `execute-analysis`, `analyse-data` | plan, statframe | results (one per question) | record appended |
| `record` | `store-analysis` | project | analysis record | written to a repository |
| `report` | `report`, `report-analysis` | results, record, template | report document | stored |
| `publish` | `publish` | report, targets | published artefacts | delivered (PDF, Quarto, Word, CMS) |

In the functional style the whole activity is one expression, as in
Rossini's sketch:

```lisp
(publish
 (report
  (analyze (plan-of 'sleep-study)
           (validate (plan-of 'sleep-study)
                     (acquire (data-source :uri "file:data/sleep.csv"))))
  :template :markdown)
 :targets '((:pdf :style :jasa) (:markdown :storage "file:reports/")))
```

In the project style the same steps are commands on a named project; each
is stored, so the activity can be resumed, reviewed and repeated.

```lisp
(define-project sleep-study
  :question "Does drug 2 give more extra sleep than drug 1?"
  :owner "..." :approvers '("...") :resources '((:time 5 :hours)))

(plan 'sleep-study (sleep-plan))      ; see below
(acquire 'sleep-study (data-source :uri "file:data/sleep.csv"))
(validate 'sleep-study)
(analyze 'sleep-study)
(report 'sleep-study :template :markdown)
(publish 'sleep-study :targets '((:pdf :style :jasa)))
```

## Declaration verbs

Declarations are facts about the study, stated before analysis, normally in
the plan. Each returns a new statframe (no mutation). Each fact carries a
status (declared, inferred, observed by a check, assumed) and a source.

| Verb | States | Examples |
|----|-----|------|
| `declare-scale` | measurement level: nominal, ordinal, interval, ratio; count; binary | `(declare-scale d :extra :ratio :group :nominal)` |
| `declare-structure` | unit (block) structure and treatment structure, and what was randomized to which unit | section 6.3 |
| `declare-origin` | how a variable came about: set by design, randomized, observed, derived | `(declare-origin d :dose :set-by-design :len :observed)` |
| `declare-timing` | order of measurement (stages or timestamps) | `(declare-timing d :gender :before-application :dept :application :admit :decision)` |
| `declare-process` | data-generating process: random, known pattern, deterministic | `(declare-process d :stanza :known-pattern)` |
| `declare-counts` | rows are cells; a column counts cases | `(declare-counts d :freq)` |
| `declare-units` | units and value domains | `(declare-units d :dist "ft" :domain (:>= 0))` |
| `declare-provenance` | source, owner, extraction date, version, review status | |

Storage types give some facts for free: a string column is at least
nominal, a double column at least interval. These are *inferred* facts and
are marked as such.

## Question verbs

Each question verb compiles to a **goal** for the solver. Its keyword
arguments are part of the question, and so part of the goal.

| Verb | Asks | Key arguments | Goal (today's relations) |
|-----|--------|-------|------------|
| `describe` | what does a variable look like? | `:variables`, `:by` | `(described v)` |
| `predict-next` | what comes next? | `:variable` | `(predicted-next v)`, `(estimated-probabilities v)` |
| `compare` | do groups differ, by how much? | `:outcome`, `:by`, `:contrast`, `:estimand` | `(estimated-difference> y g)`; with a design `(explained-by-design> y a)`; with an estimand `(estimated-total-effect> y x)` or `(estimated-direct-effect> y x)` |
| `relate` | how does y change with x? | `:outcome`, `:with`, `:purpose` | `(estimated-trend> y x)`; `:purpose :inference` gives `(inferred-trend> y x)` |
| `predict` | what y for new cases? | `:outcome`, `:from`, `:new-data` | `(prediction-interval> y x)`; reversed direction `(predicted-from> y x)` |
| `check` | does an assumption hold? | `:assumption`, `:for` | runs a check, adds a fact, replans |
| `simulate` | what data would this model produce? | `:from` (a result or plan), `:n`, `:seed` | proposed |
| `conclude` | what do we decide, on which scale? | `:result`, `:scale`, `:threshold` | proposed (Rossini's "conclusion" component) |

Common keyword arguments:

- `:data` -- a statframe or a plain table.
- `:purpose` -- `:trend`, `:inference`, `:prediction`. Example 02 shows that
  the same regression needs different assumptions for each.
- `:estimand` -- `:total`, `:direct` (example 04), later the ICH E9(R1)
  attributes (population, variable, intercurrent events, summary).
- `:contrast` -- which group minus which; R's sign conventions differ
  between calls (example 01: -1.58 vs 1.58).
- `:assumptions` -- `:apply`, `:ignore`, `:explore` (section 4.5).
- `:checks` -- `:off`, `:warn`, `:error`: whether checks run and how their
  findings are reported.

`compare`, `relate` and `predict` are kept apart here because their goals
differ. Rossini's 2009 sketch had one `compare` with a `:comparison`
argument; section 14 asks which he prefers.

## Assumption modes: apply, ignore, explore

Rossini's 2009 `compare` (in common-lisp-stat,
`examples/500-InferentialDataAnalysis.lisp`) had
`:assumptions (list 'apply 'ignore 'explore)`. In the planner these become
three modes:

| Mode | Meaning | Planner behaviour |
|---|----|------|
| `:apply` | use only what is declared | `assume-...` actions are disabled; a question without a fully declared basis has no plan, and the answer says which declarations are missing |
| `:ignore` (default) | proceed like R, but record | `assume-...` actions are allowed; they appear in the plan and the record |
| `:explore` | show what difference the assumptions make | every minimal plan is executed; results are tabulated side by side |

`:ignore` is the default because it matches the behaviour users expect from
R. `:explore` is Rossini's sensitivity analysis: "statistical assumptions
are made to be violated", and the point is to see what the violation
changes.

## Inspection verbs

| Verb | Shows |
|---|-------|
| `plans` | every minimal plan for a question, ranked |
| `explain` | why a plan was chosen: facts used, rules applied, plans excluded and by which fact |
| `alternatives` | the other plans with their assumptions |
| `assumptions` | assumptions of a plan or result, with status |
| `record` | the analysis record (a table) |

`explain` is the answer to "why did it not use Welch?": because
`repeated-by> sleep id group` was declared (by whom, when), and Welch's
plan needs `rows-independent`, which that fact excludes.

## Method actions

Methods are defined by rules (section 5.2) and are callable directly by
anyone who wants a specific method: `(welch-t-test :outcome :extra :by :group
:data d)`. A direct call still checks the method's hard requirements and
records its assumptions, so the record is complete either way.

## Results

Every question verb returns a result object:

| Slot | Content |
|---|-------|
| `question` | the verb call and its goal |
| `answer` | a tidy table (estimates, intervals, tests) |
| `plan` | the executed plan (steps with arguments) |
| `assumptions` | assumptions relied on, each with status: declared, observed, assumed |
| `alternatives` | other minimal plans; in `:explore` mode their answers |
| `checks` | checks run, their results, grades |
| `facts` | the facts the plan used, with source and status |
| `warnings` | graded messages (note, suggestive, clear) |
| `reference` | the equivalent R call for each step, e.g. `t.test(extra ~ group)` |
| `provenance` | versions, seed, data fingerprint, time |

Printed, a result reads like a short report:

```
compare extra by group (contrast 2 - 1)
  plan        paired-t-test extra group id
  because     declared: repeated-by> sleep id group (plan, 2026-10-13)
  estimate    1.58   t 4.06   df 9   p 0.0028   95% CI 0.70 .. 2.46
  relies on   differences roughly normal (n = 10; assumed)
  also fits   signed-rank-test   V 45   p 0.0091
  R           t.test(extra[group == "2"], extra[group == "1"], paired = TRUE)
```

# The DSL

## Surface syntax for analysts

The sleep example, plain and declared:

```lisp
(in-package :clds-user)

(defparameter *sleep* (read-csv "examples/stat101/01-sleep/data.csv"))

;; plain table: R's answer, with R's silent assumption made visible
(compare :outcome :extra :by :group :data *sleep*)
;; plan: assume-rows-independent, welch-t-test

;; declared: every patient received both drugs
(defparameter *sleep-d*
  (-> *sleep*
      (declare-scale :extra :ratio :group :nominal :id :nominal)
      (declare-structure :units '(:id) :treatments '(:group)
                         :treatment-varies-within :id)))

(compare :outcome :extra :by :group :data *sleep-d* :contrast '("2" "1"))
;; plan: paired-t-test (alternative: signed-rank-test)

(compare :outcome :extra :by :group :data *sleep-d* :assumptions :explore)
;; both plans executed, answers side by side
```

A plan, in the shape of Rossini's `plan-as-code`, carries declarations and
questions together:

```lisp
(defun sleep-plan ()
  (plan-as-code
   :question "Does drug 2 give more extra sleep than drug 1?"
   :data-source (data-source :uri "file:data/sleep.csv")
   :declarations '((declare-scale :extra :ratio :group :nominal :id :nominal)
                   (declare-structure :units (:id) :treatments (:group)
                                      :treatment-varies-within :id))
   :questions '((difference (compare :outcome :extra :by :group :contrast ("2" "1"))))
   :metadata-needs '(:scale :structure)))
```

`validate` checks the data against these declarations: that `id` has every
level of `group` once, that `extra` is numeric, and so on. A failed
validation stops the activity with a report instead of analysing data that
do not match the plan.

## Defining forms for method authors

Method authors write rules; they never write dispatch code.

**`define-method`** -- a method with its requirements, soft assumptions,
preferences, implementation and sources:

```lisp
(define-method paired-t-test
  :answers     (estimated-difference> ?y ?g)
  :requires    ((scale ?y (:interval :ratio))          ; hard: precondition
                (levels ?g 2)
                (repeated-by> ?f ?id ?g))
  :relies-on   ((normal-differences ?y ?g              ; soft: may be assumed
                 :relaxed-when (>= (n-pairs ?id) 30)))
  :prefer-over ((signed-rank-test :when (normal-differences ?y ?g)))
  :r-equivalent "t.test(y[g == b], y[g == a], paired = TRUE)"
  :implementation clds.stats:paired-t-test
  :sources     ("Altman 1991" "Sheskin 2011" "Student 1908"))
```

**`define-check`** -- a check whose result depends on the values; it adds
facts:

```lisp
(define-check spread-check
  :about     (estimated-trend> ?y ?x)
  :observes  ((constant-spread> ?y ?x) (nonconstant-spread> ?y ?x))
  :grades    (:suggestive 0.10 :clear 0.01)
  :implementation clds.checks:breusch-pagan
  :sources   ("Breusch & Pagan 1979" "Koenker 1981"))
```

**`define-constraint`** -- a rule no plan may break (wouldwork constraint):

```lisp
(define-constraint design-consistency
  :forbid (and (explains> ?y ?x)
               (or (set-by-design ?y) (randomized ?y) (measured-before> ?y ?x)))
  :except-purpose :prediction
  :sources ("Fisher 1935" "ICH E9"))
```

**`define-question`** -- how a question verb maps to a goal:

```lisp
(define-question compare (&key outcome by estimand purpose contrast)
  :goal (cond ((eq estimand :total)  `(estimated-total-effect> ,outcome ,by))
              ((eq estimand :direct) `(estimated-direct-effect> ,outcome ,by))
              ((design-factor-p by)  `(explained-by-design> ,outcome ,by))
              (t                     `(estimated-difference> ,outcome ,by))))
```

**`define-fact-rule`** -- how declarations become planner facts (section 6):

```lisp
(define-fact-rule treatment-within-unit
  :when  (and (unit-factor ?id) (treatment-factor ?g)
              (every-level-within ?g ?id))
  :then  (repeated-by> ?frame ?id ?g))
```

## Compilation

1. **Facts.** The statframe's declarations and inferred storage facts are
   turned into planner facts by the fact rules.
2. **Goal.** The question verb's `define-question` gives the goal.
3. **Domain.** Each `define-method` becomes a wouldwork action:
   `:requires` becomes the precondition; `:answers` the effect, together
   with `(used <method>)` for the record. Each soft `:relies-on` fact
   generates an action `assume-<fact>`, possible unless the opposite fact
   is known. Each `define-constraint` becomes a wouldwork constraint.
4. **Plans.** The planner returns every minimal plan (no plan containing
   all steps of another).
5. **Ranking.** Fewest assumed facts first; then `:prefer-over` rules; then
   shortest.
6. **Execution.** The chosen plan (or all, in `:explore`) runs through the
   implementations; checks add facts; if a fact contradicts an executed
   step's assumption, the question is planned again.

Today step 3 is written by hand (`examples/stat101/domain.lisp`, 25
actions); steps 1, 2 and 6 are done by the example files and tests. The
first milestone (section 13) builds the compiler and re-expresses the 25
actions as rules, with the 50 tests unchanged.

## Why a DSL in Lisp

The rules are data and code at once: the same forms are compiled into
planner actions, printed into reports, checked by tests and read by an LLM.
Macros give rule authors a compact notation without a separate parser.
The planner itself (wouldwork) is Lisp and is called in-process. Rossini's
README states the aim: the DSL enforces a philosophy, while the work itself
may run in R or Python; Lisp is the layer that holds the knowledge.

# The data representation

Rossini's point: the problem solver can only be as good as the
representation of the data it reasons about. The examples show which facts
the representation must carry.

## Levels

| Level | Facts | Example |
|---|---|---|
| value | measurement scale, unit, domain, missingness kind | `dist` in ft, `>= 0` |
| variable | role, origin, timing, provenance | `dose` set by design before `len` |
| frame | unit of observation, row relations (independent, repeated, clustered, time-ordered, unknown), counts | `ucb` rows are cells with counts |
| study | block structure, treatment structure, randomization, stages | `npk`: plots in blocks, N x P x K |
| question | purpose, estimand, contrast | `:purpose :prediction` |

The last level is not data: it belongs to the verb call. Keeping it out of
the frame means the same data can answer different questions.

## Variable facts

| Fact | Values | Source |
|---|---|---|
| scale | nominal, ordinal, interval, ratio (Stevens 1946); binary; count | declared, or inferred from storage type |
| unit, domain | "ft", `(:>= 0)` | declared |
| origin | set by design, randomized, observed, derived (with sources) | declared; `derived` set automatically by `mutate` |
| timing | ordered stages or timestamps | declared |
| process | random, known pattern, deterministic | declared (Rossini's 1d example) |

## Unit and treatment structure

Experimental design has a precise representation that predates software
for it: Nelder (1965) separated the **block structure** of the units from
the **treatment structure**, with randomization mapping one onto the other.
Genstat, Nelder's system, analyses designed experiments from declared
`BLOCKSTRUCTURE` and `TREATMENTSTRUCTURE`; R's `aov(... + Error(block))` is
a remnant of the idea where users write the error strata by hand. Bailey
(2008) gives the modern form.

Proposal: the statframe carries both structures and the randomization map,
and the planner facts are derived from them by fact rules.

```lisp
;; npk (R datasets): 2 x 2 x 2 factorial in 6 blocks of 4 plots,
;; N:P:K confounded with blocks
(declare-structure npk
  :units      '(:block (:plot :within :block))
  :treatments '(:n :p :k)
  :treatment-model '(* :n :p :k)
  :randomized '((:n :p :k) :to :plot)
  :confounded '((:n :p :k) :with :block))

;; Oats (MASS): split-plot; variety on whole plots, nitrogen on subplots
(declare-structure oats
  :units      '(:block (:wholeplot :within :block) (:subplot :within :wholeplot))
  :treatments '(:variety :nitro)
  :randomized '((:variety :to :wholeplot) (:nitro :to :subplot)))
```

From these, fact rules derive what the methods require: which error stratum
tests which effect, which effects are not estimable within blocks, which
unit is the unit of analysis (pseudo-replication, Hurlbert 1984), and,
for sleep, that each patient saw both drugs (`repeated-by>`).

## Fact status

Every fact has a status and a source:

| Status | Meaning | May choose a method? |
|---|-----|-----|
| declared | stated in the plan or by `declare-...` | yes |
| inferred | from storage types or validated structure | yes, for scale and levels only |
| observed | result of a check | yes (replanning) |
| assumed | made by an `assume-...` step | yes, and recorded as an assumption |
| suspected | a detector's hint (e.g. "rows may be paired") | no: reported only |

The planner sees only true facts; the status and source live in the
statframe and the record, so that `explain` can say where each fact came
from.

## Propagation through table verbs

Declarations must survive wrangling, or be dropped with a warning:

| Table verb | Effect on declarations |
|---|------|
| `filter` | kept; warns if it breaks a structure (removes one of a patient's pair) |
| `select` | drops facts of dropped columns; dropping a unit factor makes row relations unknown |
| `mutate` | new column gets origin `derived`, its sources read from the expression, and the latest timing of its sources |
| `summarise` by a unit factor | new unit of observation; repeated becomes independent at the new level |
| `pivot-wider` by a unit factor | repeated long form becomes paired columns |
| `arrange` | a declared time order is marked lost if rows are sorted by something else |
| joins | facts merged; conflicting declarations warn |

## Serialization

Declarations and provenance are written next to the data (a sidecar file)
and are part of the plan (`plan-as-code`), so they travel with the dataset
and can be reviewed like code.

# The solver

## From GPS to wouldwork

The solver is a general problem solver in the sense of Newell, Shaw and
Simon (1959): operators with preconditions and effects, and a search that
connects a start state to a goal. Norvig's *Paradigms of AI Programming*
(1992, chapter 4) presents GPS in Common Lisp and shows its limits with
interacting goals. STRIPS (Fikes and Nilsson 1971) fixed the operator
format, PDDL (1998) standardised it. Wouldwork (Dave Brown) is a
PDDL-flavoured planner in Common Lisp: typed objects, quantifiers,
constraints, fluents, durative actions, and every-solution or optimal
search. It searches state space forward rather than by means-ends analysis,
which avoids GPS's problem with interacting goals.

## Mapping

| Planner | Data science |
|---|-----|
| initial state | facts from declarations, storage types and checks |
| goal | the question |
| action, precondition, effect | method, requirements, what it delivers |
| `assume-...` action | an assumption, made only when a plan needs it |
| constraint | a rule no analysis may break (design consistency) |
| every solution | alternatives; `:explore` |
| plan trace | the "why" in `explain` and the record |

## What the planner does today

`find-plans` (src/planner.lisp) writes a wouldwork problem from objects,
facts, goal and a domain file, stages and solves it with solution type
*every* and graph search, and returns the **minimal plans**: plans that
contain every step of another plan are dropped. This removes assumptions a
plan does not need. Each action asserts `(used <action>)` so that plans
with different methods end in different states and are all kept.

## Plan, run, replan

Only what is known before a method runs can be planned. Checks whose result
depends on the values are executed; their result enters as an observed
fact; the question is planned again. Examples 02 (spread) and 05 (two
modes) show this as two states of knowledge. This keeps the planner
classical (deterministic actions) while the analysis reacts to the data.

## Limits and alternatives

- Wouldwork is built as an application: staging a problem copies it into
  its own source tree and reloads the system (about a second). Fine for
  analysis-sized problems; a library entry point would be cleaner and could
  be proposed to its author.
- A bug was found: with its default parameter instantiation, an action
  with more same-type parameters than objects crashes the planner. The
  domain uses the `product` header instead (documented in AGENTS.md).
- The search spaces are small (tens of actions, plans of up to five
  steps). If needed, a small matcher with the same rule format can replace
  wouldwork without changing the rules.

# The rule base

## Kinds of rules

| Kind | Example | Compiled to |
|---|---|---|
| hard requirement | a mean needs at least interval scale | precondition |
| soft assumption | normality of paired differences | `assume-...` action, recorded |
| preference | paired t-test over signed-rank when normality holds | ranking |
| constraint | nothing explains a randomized variable | wouldwork constraint |
| check | Breusch-Pagan for spread | `define-check`, adds observed facts |
| fact rule | treatment varies within unit gives `repeated-by>` | fact derivation |
| reporting rule | what to report for a t-test (SAMPL) | report templates |

## Sources

| Field | Sources (examples) |
|--|-------|
| one entry per test | Sheskin, *Handbook of Parametric and Nonparametric Statistical Procedures*; Kanji, *100 Statistical Tests*; Siegel and Castellan, *Nonparametric Statistics for the Behavioral Sciences* |
| soft rules, preferences | van Belle, *Statistical Rules of Thumb* |
| medicine | Altman, *Practical Statistics for Medical Research*; Bland, *An Introduction to Medical Statistics*; Kirkwood and Sterne, *Essential Medical Statistics*; Petrie and Sabin, *Medical Statistics at a Glance* |
| clinical trials | ICH E9 and E9(R1) (estimands); Friedman, Furberg and DeMets; Piantadosi; Senn, *Cross-over Trials in Clinical Research* |
| pharmacy, pharmacology | Bolton and Bon, *Pharmaceutical Statistics*; Motulsky and Christopoulos, *Fitting Models to Biological Data*; Chow and Liu (bioequivalence) |
| psychology, sociology | Field, *Discovering Statistics Using R*; Howell, *Statistical Methods for Psychology*; Tabachnick and Fidell, *Using Multivariate Statistics*; Agresti and Finlay; Shadish, Cook and Campbell (quasi-experiments) |
| experimental design | Fisher, *The Design of Experiments*; Cochran and Cox; Cox, *Planning of Experiments*; Bailey, *Design of Comparative Experiments*; Mead, Gilmour and Mead; Box, Hunter and Hunter; Montgomery |
| errors (constraints) | Good and Hardin, *Common Errors in Statistics*; Hurlbert (1984) on pseudo-replication |
| reporting | SAMPL (Lang and Altman 2013); CONSORT, STROBE, ARRIVE |
| open, with data | NIST/SEMATECH e-Handbook (public domain); McDonald, *Handbook of Biological Statistics*; OpenIntro Statistics (CC BY-SA); Navarro, *Learning Statistics with R* (CC BY-SA); Holmes and Huber, *Modern Statistics for Modern Biology* |

## Rules with provenance

- Every rule lists its sources. Rules are encoded from the content of
  books; tables and text are not copied.
- Sources disagree, and some teaching rules are disputed (testing normality
  first, then choosing between t and Mann-Whitney, distorts error rates;
  several authors recommend Welch by default). Conflicting rules are kept,
  marked as conflicting, and the conflict is shown in `explain`.
- Every rule is tested: a worked example from its source (or an open
  dataset) with an R reference, as in `examples/stat101`.

## Coverage plan

1. the common test-selection table (about 30 tests: outcome scale x number
   of groups x paired or independent);
2. experimental design (block and treatment structures; R's `PlantGrowth`,
   `npk`, `OrchardSprays`, `Oats`);
3. clinical trials (estimands, randomization, crossover, intention to
   treat);
4. pharmacology (dose-response, bioequivalence: equivalence as a different
   question);
5. psychology and sociology (ordinal scales, repeated measures,
   reliability);
6. bioinformatics (many tests at once, paired samples, compositional data).

# Execution, record and report

**Executors.** Each method rule names an implementation: native Lisp (as
the Lisp statistics libraries mature), R through uvr (already used for the
references; R versions and packages pinned), later Python. The same plan
can run on different executors, and the R reference doubles as a check.

**Record.** Every verb appends to the analysis record: declarations (with
author and time), questions, plans, assumptions, checks and their grades,
overrides with reasons, versions, seeds. The record is a table and can be
reviewed before results leave the team. This answers Rossini's earlier idea
of keeping context for a project: not an unlimited memory, but a curated
record of what was known, asked, assumed and done.

**Reproduction envelope.** Results carry what is needed to reproduce them:
data fingerprint, plan, versions (Lisp systems, R and packages via
`uvr.lock`), seeds.

**Report and publish.** Reports are generated from results and record
through templates (Markdown, Quarto, PDF in journal style, corporate
templates, CMS). Reporting rules (SAMPL; CONSORT, STROBE, ARRIVE checklists)
are rules like the others: a report template knows what must be stated for
each method in the plan.

# What the examples show

Six examples run through the planner today (`examples/stat101`, 50 tests,
SBCL with Quicklisp and Roswell):

| Example | Trap | What the planner does |
|---|----|-----|
| 00 one variable (Rossini's datasets) | the data-generating process decides which questions make sense | next value needs a declared or assumed process; "chance" of a known pattern has no plan |
| 01 sleep | paired data analysed as two groups (p 0.079 vs 0.0028) | nothing declared: assume-rows-independent, welch-t-test; pairing declared: paired-t-test or signed-rank-test |
| 02 cars | spread grows with speed | trend: ols-fit only; inference: robust-se, or classical-se with an assumption; after the check only robust and spread-model plans |
| 03 ToothGrowth | `lm(dose ~ len)` fits but reverses the design | a constraint forbids explaining dose once the design is declared; prediction stays allowed |
| 04 UCBAdmissions | Simpson's paradox; counts | counts declared or assumed; total vs direct effect is the goal; direct needs the order of events |
| 05 faithful | two modes; rows in time order | describe-by-modes after the check; declared time order leaves ols-fit with hac-se |

Five observations:

1. Requirements as data work: no method is chosen by hand-written
   branching.
2. Optional declarations come for free: a plain table gets R's default
   with R's silent assumptions as plan steps.
3. Declarations remove plans or make questions answerable; they never
   surprise.
4. Purpose and estimand belong to the question.
5. Checks are not planned; they feed facts back.

# Data science with LLMs

- **Plans as guardrails.** An LLM proposes an analysis (a plan or a list of
  method calls); the solver checks it against the declared facts and
  constraints, and `explain` says what is wrong. This makes generated
  analyses checkable.
- **Rules from text, verified.** An LLM can draft rules from a methods
  section or a textbook chapter the team has; the draft becomes a rule only
  with a source, a worked example and an R reference that agrees.
- **Declarations from documentation.** Data dictionaries and protocols can
  be turned into draft declarations for a person to confirm (status
  `suspected` until confirmed).
- **Context.** The analysis record, not an unlimited context window, is
  what a model (or a colleague) needs to continue a project: what was
  known, asked, assumed and done.
- Example tier planned: an LLM proposes a plan for `sleep`; leakage across
  a declared grouping in a train/test split; two models compared on the
  same prompts (paired, as in example 01).

# Prior art

| Work | What it contributes | Difference here |
|----|-----|-----|
| GPS (Newell, Shaw, Simon 1959); PAIP (Norvig 1992) | operators with preconditions and effects; a general solver | the same idea, applied to analyses |
| STRIPS (1971), PDDL (1998), wouldwork | the planning language and solver | used as is |
| REX (Gale and Pregibon, Bell Labs, 1982-84) | regression expert on top of S: checks assumptions, proposes corrections | plans across methods; declarations optional; R as reference |
| Student (Gale 1986) | tool for building consultation systems | rules as Lisp forms, tested |
| GLIMPSE (Wolstenholme, O'Brien, Nelder 1987-88) | Prolog front end for GLIM | design structure as first-class data |
| KENS (Hand 1987) | knowledge *enhancement* rather than an expert that decides | same stance: inform, do not override |
| Genstat block and treatment structures (Nelder) | analysis derived from declared design structure | carried into the statframe |
| Lisp-Stat (Tierney 1990); common-lisp-stat (Rossini 2009) | Lisp as the language of statistics; procedures that declare required metadata (`ttest.lisp`, `proc-consistent-data-p`); `compare` with `:assumptions` | the procedure design, made searchable |
| R packages that choose tests (`rstatix`, `visStatistics`, `testflow`, `AssumpSure`) | open rule sets for the common tables | they select by testing assumptions on the same data; here design and purpose decide, checks inform |

Lessons from the expert systems of the 1980s (Hand 1984, 1985; Hahn 1985;
Raes 1992): rules were hard to elicit and to maintain, users were asked
many questions, and systems that took decisions away from users were not
trusted. The design here answers with optional declarations, plans that
show their assumptions, rules with sources and tests, and R as the
reference.

# Roadmap

| Milestone | Content | Done when |
|---|-----|----|
| M0 (done) | planner bridge; six Statistics 101 examples; R references; 50 tests | merged |
| M1 rules | `define-method`, `define-check`, `define-constraint`, `define-question`; compiler to wouldwork; the 25 actions re-expressed as rules | the 50 tests pass unchanged |
| M2 statframe | declaration verbs; fact rules; fact status; propagation through table verbs | examples declare through verbs, not plan.lisp facts |
| M3 design tier | block and treatment structures; `PlantGrowth`, `npk`, `OrchardSprays`, `Oats`; repeated measures | analyses derived from declared structure match R |
| M4 execution | executors (Lisp, R via uvr); result objects; `:explore` | results match `expected.json` |
| M5 record and report | analysis record, reproduction envelope, Markdown and PDF report templates | an example produces a report |
| M6 common core | the test-selection table with sources | about 30 methods with tests |
| M7 project verbs | `plan`, `validate`, `analyze`, `report`, `publish` over a project | Rossini's 1d examples run end to end |
| M8 clinical and pharmacology | estimands, crossover, bioequivalence | examples from open sources |
| M9 bioinformatics | paired differential expression; many tests | example with a public dataset |
| M10 LLM tier | plan checking, rule drafting | the three LLM examples |

# Decisions for Rossini

1. **Verb names.** Keep `plan-as-code`, `data-validated`, `execute-analysis`
   from the sketch, or use the shorter `plan`, `validate`, `analyze`?
2. **One `compare` or several verbs?** Separate `compare`, `relate`,
   `predict`, or one `compare` with `:comparison`, as in 2009?
3. **Where declarations live.** Plan as the source of truth, copied onto the
   data at validation (proposed), or on the data with the plan as a view?
4. **Default assumption mode.** `:ignore` (R-like, recorded; proposed) or
   `:apply`?
5. **Ranking.** Fewest assumptions first (proposed), or rule preferences
   first?
6. **Functional and project style.** Both (proposed), or one?
7. **Scope of the first rule base.** Common core first, or design first
   (Nelder structures), or clinical trials first?
8. **Execution.** R as an executor beside native Lisp (proposed), or R only
   as a reference?
9. **Solver.** Keep wouldwork (proposed, with a library entry point
   discussed with its author), or write a small matcher?
10. **Name.** "Common Lisp Data Science" (CLDS) as in the README, or a
    project name (e.g. *Gnomon*, the pointer of a sundial: reading meaning
    from shadows)?

# Appendix A: the method actions today {-}

From `examples/stat101/domain.lisp`. Preconditions in wouldwork syntax are
abridged to their requirements; every action also requires that its result
is not yet known.

| Action | Requires | Delivers |
|-----|------|-----|
| describe-categorical | categorical v | described v |
| describe-continuous | continuous v; not bimodal v | described v |
| describe-by-modes | continuous v; bimodal v | described v |
| continue-pattern | known-pattern v | predicted-next v |
| estimate-category-probabilities | categorical v; random-process v | estimated-probabilities v, predicted-next v |
| estimate-mean-and-spread | continuous v; random-process v | predicted-next v |
| welch-t-test | continuous y; two-levels g; rows-independent f | estimated-difference> y g |
| paired-t-test | continuous y; two-levels g; repeated-by> f id g | estimated-difference> y g |
| signed-rank-test | continuous y; two-levels g; repeated-by> f id g | estimated-difference> y g |
| two-way-anova | continuous y, not set by design; a, b set by design; rows-independent f | explained-by-design> y a, y b |
| predictive-fit | continuous y, x | predicted-from> y x |
| pooled-odds-ratio | binary y; two-levels x; one row per case or frequency weights | estimated-total-effect> y x |
| mantel-haenszel | binary y; two-levels x; categorical z between x and y in time; common-odds-ratio> y x; counts known | estimated-direct-effect> y x |
| logistic-by-stratum | as mantel-haenszel, without a common odds ratio | estimated-direct-effect> y x |
| ols-fit | continuous y, x | estimated-trend> y x |
| classical-se | estimated-trend> y x; rows-independent f; constant-spread> y x | inferred-trend> y x |
| robust-se | estimated-trend> y x; rows-independent f | inferred-trend> y x |
| hac-se | estimated-trend> y x; row-order-time f | inferred-trend> y x |
| normal-prediction-interval | estimated-trend> y x; rows-independent f; constant-spread> y x | prediction-interval> y x |
| spread-model-prediction-interval | estimated-trend> y x; rows-independent f; nonconstant-spread> y x | prediction-interval> y x |
| assume-random-process | not random-process v; not known-pattern v | random-process v |
| assume-rows-independent | not time-ordered; no repeated-by> | rows-independent f |
| assume-constant-spread | estimated-trend> y x; spread unknown | constant-spread> y x |
| assume-common-odds-ratio | binary y; two-levels x | common-odds-ratio> y x |
| assume-one-row-per-case | no frequency weights declared | one-row-per-case f |

Constraint: no state may contain `estimated-trend> y x` where y is set by
design or randomized, or measured before x.

# Appendix B: glossary {-}

- **Action** -- a planner operator; here a statistical method or an
  assumption.
- **Assumption step** -- an `assume-...` action: a fact taken as true
  without declaration, recorded in the plan.
- **Declaration** -- a fact about the study stated by a person (in the plan
  or by a `declare-...` verb).
- **Estimand** -- the quantity a question asks for (ICH E9(R1)); here total
  or direct effect so far.
- **Fact** -- a proposition the planner treats as true, with a status and
  a source outside the planner.
- **Minimal plan** -- a plan that does not contain all steps of another
  plan.
- **Statframe** -- a data table together with its declarations.
- **Unit and treatment structure** -- Nelder's description of a designed
  experiment: how units are grouped, and how treatments are combined and
  assigned.

# Appendix C: references {-}

- Bailey, R.A. (2008). *Design of Comparative Experiments*. Cambridge University Press.
- Fikes, R.E., Nilsson, N.J. (1971). STRIPS: a new approach to the application of theorem proving to problem solving. *Artificial Intelligence* 2.
- Fisher, R.A. (1935). *The Design of Experiments*. Oliver and Boyd.
- Gale, W.A. (ed.) (1986). *Artificial Intelligence and Statistics*. Addison-Wesley.
- Gale, W.A., Pregibon, D. (1982). An expert system for regression analysis. *Proceedings of the 14th Symposium on the Interface*.
- Hahn, G.J. (1985). More intelligent statistical software and statistical expert systems: future directions. *The American Statistician* 39.
- Hand, D.J. (1984). Statistical expert systems: design. *The Statistician* 33, 351-369.
- Hand, D.J. (1985). Statistical expert systems: necessary attributes. *Journal of Applied Statistics* 12, 19-27.
- Hand, D.J. (1987). A statistical knowledge enhancement system. *Journal of the Royal Statistical Society A* 150, 334-345.
- Hurlbert, S.H. (1984). Pseudoreplication and the design of ecological field experiments. *Ecological Monographs* 54.
- ICH (1998). E9: Statistical principles for clinical trials. ICH (2019). E9(R1): Addendum on estimands and sensitivity analysis.
- Lang, T.A., Altman, D.G. (2013). Basic statistical reporting for articles published in biomedical journals: the SAMPL guidelines.
- Nelder, J.A. (1965). The analysis of randomized experiments with orthogonal block structure, I and II. *Proceedings of the Royal Society A* 283.
- Newell, A., Shaw, J.C., Simon, H.A. (1959). Report on a general problem-solving program. *Proceedings of the International Conference on Information Processing*.
- Norvig, P. (1992). *Paradigms of Artificial Intelligence Programming*. Morgan Kaufmann.
- Pregibon, D., Gale, W.A. (1984). REX: an expert system for regression analysis. *COMPSTAT 1984*.
- Raes, J. (1992). Inside two commercially available statistical expert systems. *Statistics and Computing* 2.
- Rossini, A.J. (2008-2014). common-lisp-stat: design notes, procedures, talks. <https://github.com/blindglobe/common-lisp-stat>.
- Stevens, S.S. (1946). On the theory of scales of measurement. *Science* 103.
- Student (1908). The probable error of a mean. *Biometrika* 6.
- Tierney, L. (1990). *LISP-STAT: An Object-Oriented Environment for Statistical Computing and Dynamic Graphics*. Wiley.
- Wolstenholme, D.E., O'Brien, C.M. (1987). GLIMPSE: a statistical adventure. *IJCAI 1987*.
- Wouldwork planner, D. Brown. <https://github.com/davypough/wouldwork>.
