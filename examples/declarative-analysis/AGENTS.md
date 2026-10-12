# Building the declarative analysis example

Copyright (c) 2026 Gwang Jin Kim. SPDX-License-Identifier: MIT.

## Scope and activation

This directory contains design specifications and an experimental object/aspect
grammar with a runnable Wouldwork adapter. Work here only when the human user activates a task.
Reading this file, finding an unfinished milestone, or opening a project does
not authorize resuming it. Follow the user's process-ownership instructions:
no persistent servers, watchers, background jobs, schedules, or automatic
restarts without explicit authorization. Finish or stop and reap temporary
processes before reporting completion. Do not modify unrelated checkouts.

Keep existing examples, especially `../1d-analysis.lisp`, intact. Add examples
and comments; do not replace Tony's sketches. Include Gwang Jin Kim in the
copyright attribution of new example files. Keep personal correspondence and
patient-identifying data out of this repository.

## The interface must stay high-level

Tony's intended expression is a reference for the level of abstraction:

```lisp
(publish :journal '(JASA Biometrics)
  (report
    (analyse
      (data-quality-check
        (source data-source)
        (plan 'specs 'resources)))))
```

The human user explicitly authorized developing our own grammar; do not require
Tony's exact spelling or nesting. The implemented grammar is described in
`GRAMMAR.md` and `interface/grammar-demo.lisp`: study objects with `configure`,
`check`, `propose`, `approve`, and `report`. Preserve the high level of
abstraction. The user supplies data, study specifications, resources, and
goals. The entry form must not require Wouldwork propositions, hand-written
action sequences, a named statistical test as the initial goal, or
`permitted-analysis` flags. After proposals exist, selecting a named proposal
explicitly is appropriate and does not constitute a scientific assumption.
Verbose study metadata is appropriate; planner implementation detail belongs
behind the verbs. `interface/entry-form.lisp` records the intended form.

The following older verb contracts remain reference ideas for future adapters,
not requirements to implement duplicate APIs before improving our grammar:

- `source`: a source-data object with values, variable descriptors, case
  labels, source identity, and provenance.
- `plan`: a specification/resource planning object containing the scientific
  question, target quantity, desired claims, constraints, and unresolved
  requirements. It can exist before data arrive; distinguish a study protocol
  from the executable analysis plans eventually derived from it.
- `data-quality-check`: a checked-study object containing both source data
  and planning object, validation evidence, concerns, and pending obligations.
  Never discard the plan while passing data to `analyse`.
- `analyse`: in proposal mode, an analysis-proposal collection with admissible
  routes, conditional routes, and blocked claims with explanations; in
  execution mode, results plus the selected plan and provenance. Mode and
  selection policy belong in the specifications. Searching must not execute
  external effects or silently choose the first route.
- `report`: a report-content object for proposals or executed results,
  preserving limitations, assumptions, diagnostics, and references.
- `publish`: an output adapter. Start with a local report file. Journal/CMS
  publication remains an explicit later action and is not authorized by this
  scaffold or by running a planner.

## Representation: stay close to Tony's design

Consult the common-lisp-stat repository's `src/data/data.lisp`,
`src/data/dataframe.lisp`, `src/data/modelframe.lisp`,
`src/data/missing-data.lisp`, `src/procedures/procedures.lisp`,
`examples/500-InferentialDataAnalysis.lisp`, and
`Doc/talks/Rossini-Reisensburg-2014-CLS.tex`. Local reference checkout:
`~/projects/cl/common-lisp-stat`. Sources and interpretation notes are in
`RULE-SOURCES.md`. Use the old system for design evidence; do not assume its
prototypes compile or require installing it as a runtime dependency.

Keep cases-by-variables storage, a group variable, case/variable labels, and
variable metadata. Separate storage form, Lisp type, statistical type,
measurement meaning, and modeling role. Attach metadata at variable,
measurement, biological-case, study, and dataset-collection scales.

Keep table row count distinct from independent statistical case count.
Represent raw measurement records with their relations before constructing
an analysis view. Do not give a table of repeated wells an independent-row
contract. Record biological source, assignment unit, pairing/blocking unit,
technical replicate unit, batch/site, chronology, and how independent cases
are declared. In split-donor designs an aliquot can be the assignment unit
while a donor is the independent unit of the paired contrast.

Keep data, mathematical model, estimation/inference method, numerical
implementation, and fitted result distinct. Represent censoring and
missingness with typed records and reasons rather than interchangeable NILs.
Fixtures use readable S-expressions; the intended runtime representation is
CLOS objects and generic functions, with an adapter translating relevant
facts into Wouldwork. A reader must bind `*read-eval*` to NIL and validate the
fixture schema; never evaluate data files as code.

## Rules describe supported properties, not blanket permission

The scientific contract is: derive what can be computed and what requested
claims it supports, given explicit premises. Separate structural
applicability, accepted modeling premises, diagnostic evidence, numerical
feasibility, interpretation, and implementation qualification.

Maintain at least these premise states: unknown, declared, supported by
specified evidence, contradicted, and explicitly waived for a limited claim.
Each state needs scope and provenance. An absent Wouldwork fact does not mean
a scientific proposition is known false. No operator may invent acceptance
of an assumption merely to make a goal reachable.

Use proposal statuses such as supported-under-declared-premises,
conditional-on-obligations, structurally-incompatible, and unavailable-backend.
Do not label an entire method statistically invalid when only a particular
confidence interval or causal interpretation is unsupported. A descriptive
calculation can remain available when population inference is unresolved.
Record explicit exploratory overrides and the properties they relinquish.

Diagnostics provide evidence, not proof of independence, normality, causality,
or a missing-data mechanism. Do not automatically select a test by normality
test P-value. Do not automatically replace a mean-targeting method with a
rank test or a median estimator: the target may change.

## Rule research and provenance

For every rule, look for:

1. The exact target quantity and claim it concerns.
2. Required measurement types and study/design relationships.
3. Mathematical/model assumptions, including those not empirically testable.
4. Available diagnostics and their limits.
5. Guarantees: finite-sample, asymptotic, randomization-based, descriptive,
   conditional, or heuristic; state the conditioning premises.
6. Counterexamples, missing-information cases, and useful weaker claims.
7. Numerical requirements and independently qualified implementations.
8. A primary citation with section/page, or a proof/derivation and validation
   record; distinguish a theorem, guideline, design intent, and local policy.

Read `RULE-SOURCES.md` and use `rules/catalog.sexp` as seed records. The seed
rules are proposals marked draft-review-required. Do not compile them into
production recommendation logic until their semantics are reviewed and
counterexamples are tested. An LLM draft, an attractive narrative, or a
working implementation alone is not evidence of statistical correctness.
Avoid copying textbook prose; record concise rules and citations.

## Wouldwork integration

Inspect the installed version at `~/projects/cl/wouldwork`, rather than
assuming PDDL syntax or command names. It offers types, static/dynamic
relations, queries, actions, initial facts, and goals. Translate the checked
study and goal into that vocabulary. Derive applicability from metadata;
do not require users to declare the intended eligible procedure.

Use queries for derived applicability and actions for artifact-producing
transformations. Record which rule and premises justify every action.
Avoid duplicating one semantic rule in a Lisp validator, a generated query,
and an explanation template: retain one rule record with an explicit adapter.

Effects are evaluated during search. They must describe transformations of
symbolic artifacts, not run numerical fits, write reports, mutate original
data, or perform external actions while exploring branches. After selection,
execute qualified functions against immutable data snapshots, then validate
actual outputs. Unknown diagnostic outcomes require staged execution and
replanning or explicit conditional proposals; do not predict success as fact.

Stage/run and initialization can overwrite Wouldwork's `src/problem.lisp`
and `vals.lisp`. Use an isolated temporary copy and temporary ASDF output
directory, as `../run-assay-report.py` demonstrates. Do not change the user's
current Wouldwork problem/settings. Use serial, bounded search initially.
Record search bounds, pruning, and truncation. No solution within a bound is
not proof that no method exists. Alternative sequences reaching one state
may be pruned by graph search; preserve method identity and inferential
contract when enumerating alternatives.

## Comparing equivalent and ordered proposals

Never impose a universal ordering of statistical methods. Compare only
proposals targeting the same quantity and desired claim. Distinguish:

- equivalence of point estimates;
- equivalence of standard errors, intervals, tests, and null hypotheses;
- mathematical identity under stated premises;
- numerical agreement for qualified implementations within stated tolerance.

The first equivalence example is paired t analysis versus a one-sample t
analysis of the very same complete paired differences, with identical
direction, null, confidence level, exclusions, and inferential premises.
An intercept-only regression on those differences is a later extension,
not a blanket equivalence claim about arbitrary regression models.

Ordering should be a documented partial order or user-specific preference:
supported guarantees, unresolved assumptions, diagnostics, implementation
qualification, computation cost, and scope of robustness. Statistical
precision, numerical accuracy, and Monte Carlo error are separate attributes.
Do not choose the narrowest observed interval and call that procedure best.
Any efficiency/coverage ordering needs a specified model/design and evidence.
Keep incomparable candidates visible; identify changed targets separately.

## Build in completed milestones

Current prototype: CLOS study/data objects, aspect patches and configuration
sheets, revision history and stale approvals, validated fixture overlays,
structural checks, real bounded Wouldwork routes, and a textual proposal report.
The mini package loads through `load.lisp` or ASDF; `demo` returns a fresh
configured object. Ordinary REPL proposals use the synchronous Python launcher
and an isolated SBCL worker. Do not move Wouldwork into the caller's Lisp image
or remove worker cleanup. Keep data transport versioned and reader evaluation
disabled. `asdf:test-system` runs domain and REPL integration checks.
Rules remain draft, numerical execution is not implemented, and the full
statistical equivalence/precision contracts are not qualified. Keep those
boundaries visible. Do not call the proposal report a computed analysis report.

1. Implement validated data/goal objects from the fixtures and the high-level
   verb return contracts. Define fixture-overlay semantics explicitly.
2. Derive paired versus independent applicability and duplicate-reading
   obligations from metadata. Produce explanations, including unresolved
   premises; no hard-coded eligible-analysis input.
3. Compile a small reviewed rule subset into Wouldwork. Produce at least two
   routes and replay each route against the rule contracts.
4. Execute one selected numerical route and produce a complete local report
   containing values, plot, design, assumptions, diagnostics, provenance,
   proposal comparison, and reproducible invocation.
5. Verify the restricted paired-t equivalence against an independent trusted
   implementation. Add clinical chronology, estimands, or RT-qPCR only after
   the first report is complete.

Do not build a graph database, broad ontology, new numerical library, or
autonomous agent infrastructure to complete the first example. Existing
tools and a small explicit vocabulary are sufficient to test the design.

## Verification and completion

Use `fixtures/expectations.sexp` as behavioral scenarios, not as proof of
scientific truth. Test changed metadata, unknown/contradictory premises,
incomplete pairs, technical duplicates, degenerate inputs, chronology,
unavailable backends, equivalence conditions, and bounded-search reporting.
Duplicating technical readings must not inflate independent sample count.
Changing a target must change claim eligibility. Permuting rows must not
change a design-aware result. Removing metadata must create obligations,
not silently change scientific interpretation.

Compare executed numerics to independent reference results using documented
tolerances. Validate source immutability and replay explanations. Once
appropriate checks pass, stop broadening testing without a new reason.
Report clearly which artifacts are specifications, executable planner code,
qualified numerical code, or scientifically reviewed rules. Never claim the
planned system is implemented because these files can be read by Lisp.
