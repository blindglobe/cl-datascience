# A study object and verbs over its aspects

Copyright (c) 2026 Gwang Jin Kim. SPDX-License-Identifier: MIT.

This prototype develops our own grammar while preserving the high level of
Tony's examples. A study contains immutable source measurements, scientific
specifications, check records, candidate analyses, selections, and history.
The public example contains no Wouldwork facts or ordered workflow.

```lisp
(defparameter experiment
  (study :name "Paired enzyme assay" :from :paired-technical-duplicates))

(configure experiment :goal :design)

(configure experiment
  (goal :quantity :mean-within-case-difference
        :contrast '(treatment vehicle)
        :claim :population-mean-inference
        :confidence-level 0.95d0)
  (assumptions :independent-cases :declared
               :normal-differences :unknown))

(check experiment :data :design)
(propose experiment :analysis)
(approve experiment :analysis-plan :proposal :paired-t :by :analyst)
(report experiment)
```

Load `../try-declarative-analysis.lisp` to try these forms at the REPL, or
run `python3 run-grammar.py` for the full scripted demonstration. In that
example `:demo-author` records a hypothetical plan selection. None of these
forms performs statistical estimation, accepts the unknown normality premise,
publishes externally, or certifies the model. The proposal report states these
limits. `(asdf:test-system "declarative-analysis")` runs domain and package checks.
`python3 run-grammar.py --check` runs the isolated domain checks alone.

## Two forms of configure

`(configure study :goal :design)` returns a configuration sheet: known values,
available fields, and missing required fields. It does not mutate or prompt.
A future REPL, form UI, or LLM interface can use the sheet to ask questions.
The API itself remains reproducible and usable without a conversational UI.

`(configure study (goal ...) (design ...))` applies supplied aspect objects.
These are value descriptions, not instructions to run an analysis. Updates
patch named fields, retaining omitted fields; multiple aspects are validated
before one revision is committed. Mixing selectors and updates is rejected.
An identical update is a no-op. Duplicate updates to one aspect in one batch
are rejected rather than relying on hidden precedence.

Use `configuration-sheet` explicitly if polymorphic `configure` return types
are undesirable in client code. Updates return the study, allowing composition:

```lisp
(report
  (propose
    (configure experiment (goal :confidence-level 0.90d0))
    :analysis))
```

This composition is ordinary Common Lisp evaluation: configuration precedes
proposal generation, which precedes reporting. It does not quote or schedule
those calls. The planner derives the analysis preparation steps separately.

## Implemented aspects

| Aspect | Meaning |
|---|---|
| `goal` | Target quantity, ordered contrast, claim, confidence level |
| `design` | Independent case key, assignment unit, pairing, replicate grouping (`:replicates-within`) |
| `measurements` | Response/group columns, statistical type, units, aggregation |
| `assumptions` | Explicit premise states and their stated source |

Source values are supplied through `study :data (dataset ...)` or a fixture.
The dataset retains a two-dimensional table, labels, variable descriptions,
and source metadata. `dataset-table` returns a copy. Configuration creates
an explicit current interpretation while retaining the source's descriptions.
Column references are normalized to keyword names; callers can use symbols,
keywords, or strings for those references. Symbolic category labels are
compared by symbol name in this small vocabulary, independently of the caller's
Lisp package. Strings and numeric category values retain their own equality.
The prototype does not model distinct category namespaces with identical names.

The first grammar uses a small aspect schema. Per-aspect descriptors can later
become extensible CLOS objects with context-sensitive fields. Do not implement
a broad configurator before completing the first numerical analysis example.

## Checks and proposals

`check` returns evidence and obligations at a study revision. The current
checks cover column mappings, finite responses, contrast presence, paired
completeness, declared structure, and repeated readings. Independent case
counts are counts of declared case keys; the existence of keys does not prove
independence. Technical aggregation remains an explicit policy.

`propose` recomputes current checks, translates metadata to an isolated
Wouldwork domain, and searches for compatible preparation and analysis routes.
Paired continuous data with a paired mean goal admit a direct paired-t route
and a route through explicit differences and a one-sample t procedure.
Independent cultures with an independent mean goal admit a Welch candidate.
Changing statistical type, design, claim, or unresolved preparation policy
changes the routes. Queries derive compatibility; there are no user-supplied
method permission flags. The mini package runs Wouldwork in a synchronous
isolated subprocess per request; it does not load or replace the caller's
Wouldwork domain. Worker results use versioned data-only S-expressions, with
reader evaluation disabled. Symbolic labels cross the boundary by name, matching
the current category vocabulary. If the worker fails, the parent retains its
previous study state. Paths can be configured through the exported backend
variables documented in README.md.

Every suggestion stays conditional: rule review, numerical qualification,
variance/sample-size assessment, and applicable model premises remain explicit
obligations. Contradicted independence and a contradicted exact paired-t model
do not become acceptable through search or approval. Other inferential
justifications are outside this prototype. Causal identification, predictions,
clinical estimands, and qPCR normalization are also outside its runtime scope.

## Approval and revision semantics

Approval records review or selection, not scientific truth. A plan requires
a named current proposal and an actor; the implementation never chooses the
first candidate for the user. The approval retains its exact specification,
revision, and proposal generation. An aspect update invalidates checks,
proposals, and earlier approvals conservatively. Regenerating proposals makes
previous plan selections stale even at the same configuration revision.
History retains before/after aspect values. No approval permits numerical
execution or publication in this prototype.

## Comparison and next boundary

The report identifies the two paired routes as candidates for equivalence
under identical pairs, contrast direction, settings and inferential premises.
It does not claim numerical equivalence has been validated or rank precision.
The comparison contracts remain specifications for that future work.

The next activated milestone should execute one selected route with qualified
numerics and report its actual results. Only then add an execution verb and
prove the restricted paired-t equivalence against an independent reference.
