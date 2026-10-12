# Declarative statistical analysis with Wouldwork

Copyright (c) 2026 Gwang Jin Kim. SPDX-License-Identifier: MIT.

This directory contains a **runnable grammar and proposal prototype**, plus
statistical design specifications. It does not execute statistical estimates
or contain a scientifically qualified rule set. Start with [GRAMMAR.md](GRAMMAR.md)
for our object/aspect grammar and [AGENTS.md](AGENTS.md) for development instructions.

Tony's expression is a reference for the high level of abstraction:

```lisp
(publish :journal '(JASA Biometrics)
  (report
    (analyse
      (data-quality-check
        (source data-source)
        (plan 'specs 'resources)))))
```

The initial output adapter will write locally. The journal expression is a
presentation target, not authorization to submit or publish anything.
Our grammar uses `configure`, `check`, `propose`, `approve`, and `report` on a
study object. These spellings can evolve independently of the reference expression.
The runtime currently produces proposals only.

## Files that exist now

| File | Responsibility |
|---|---|
| `GRAMMAR.md` | Our grammar, revision semantics, and current runtime limits |
| `AGENTS.md` | Implementation instructions and scientific constraints |
| `declarative-analysis.asd`, `load.lisp`, `src/` | Loadable mini package, CLOS grammar, fixtures, isolated Wouldwork adapter |
| `interface/grammar-demo.lisp` | Executable high-level laboratory example |
| `run-grammar.py`, `tests/` | Isolated runtime, 29 domain checks and 5 package integration checks |
| `RULE-SOURCES.md` | Source map, research questions, and rule-admission checklist |
| `interface/entry-form.lisp` | Loadable, quoted record of the intended high-level expression |
| `fixtures/studies.sexp` | Synthetic independent, paired, and repeated-reading study forms; clinical and qPCR extension forms |
| `fixtures/goals.sexp` | Target quantities, claim requirements, policies, and resource requests |
| `fixtures/expectations.sexp` | Behavioral scenarios for the future system |
| `rules/catalog.sexp` | 18 draft rules, scoped claims, obligations, and source identifiers |
| `comparison/contracts.sexp` | Restricted equivalence and partial-order criteria |

The S-expression rule and comparison catalogs remain inert specifications.
The prototype loads the laboratory studies with explicit fixture overlays and
uses a small provisional rule subset in generated Wouldwork queries. The full
catalog is not compiled or scientifically reviewed.
The preceding runnable toy is still `../problem-assay-report.lisp` with
`../run-assay-report.py`; it manually declares permitted summaries. This new
system should derive applicability from richer metadata instead.

## First completed example

Use one two-condition enzyme assay in three designs:

1. Separate independent cultures per treatment.
2. Each donor supplies one aliquot per treatment; contrasts are paired.
3. Each paired aliquot is read twice; technical readings are nested.

All use cases-by-variables storage with a treatment/group variable, typed
response, identities, and relationships. The quantity is enzyme activity in
U/ml in a synthetic scenario whose readings are already calibrated. Calibration
is a declared premise, not something these fixtures establish experimentally.

The first goal is a mean contrast with an estimate, uncertainty description,
plot, and report. The system should derive independent versus paired structure,
propose the appropriate preparation and analysis paths, and expose unresolved
inferential premises. Pairing comes from design metadata, never numeric
similarity or adjacent row order. Averaging technical readings requires the
supplied aggregation policy and retains the independent-case structure.

Paired t versus one-sample t on the same differences is the first restricted
equivalence demonstration. They target the same mean contrast and must use
the same pairs, null, direction, interval definition, and inferential premises.
An independent-groups analysis is not an equivalent alternative for paired
uncertainty. A median contrast is a different target, not a replacement for
the requested mean contrast.

## Load and try at the REPL

From the repository root:

```lisp
(load "examples/try-declarative-analysis.lisp")
(in-package :clds-demo)  ; nickname for CLDS-EXAMPLE

;; The loader created a fresh synthetic study, without starting a planner.
(configure *example-study* :goal :design :assumptions)
(check *example-study* :data :design)
(propose *example-study* :analysis)
(proposals *example-study*)  ; conditional :PAIRED-T and :DIFFERENCE-T routes
(format t "~A" (report *example-study*))

(approve *example-study* :analysis-plan :proposal :paired-t :by :me)
(configure *example-study* (goal :confidence-level 0.90d0))
(approvals *example-study*)  ; selection is now stale
(propose *example-study* :analysis)

(defparameter independent (demo :fixture :independent-cultures))
(propose independent :analysis)  ; conditional Welch route
```

To load only the package, without creating the example object:

```lisp
(load "examples/declarative-analysis/load.lisp")
(defparameter experiment (clds-demo:demo))
```

Both loaders resolve source files relative to their own pathname. Supply an
absolute loader pathname if the REPL is in another working directory. If ASDF
already knows this directory, `(asdf:load-system "declarative-analysis")` also
works. The package has only UIOP as an in-image dependency. Loading it neither
loads Wouldwork into your Lisp image nor performs a search.

`demo` returns a new configured object each time. Its `:fixture` accepts
`:paired-aliquots`, `:paired-technical-duplicates` (default), or
`:independent-cultures`. These are synthetic data, not calibrated lab results.
You can also construct your own study with `study :data (dataset ...)` and
configure its aspects; see [GRAMMAR.md](GRAMMAR.md).

## Planner prerequisites and isolation

A proposal request uses Python 3 to launch a temporary SBCL process with an
isolated copy of an existing Wouldwork checkout. It needs existing Quicklisp
and the installed `alexandria`, `iterate`, and `lparallel` dependencies. Nothing
is installed by the package. Defaults match the local project layout; override
these special variables before calling `propose` if necessary:

```lisp
(setf clds-demo:*wouldwork-source* #p"/path/to/wouldwork/"
      clds-demo:*quicklisp-setup* #p"/path/to/quicklisp/setup.lisp"
      clds-demo:*planner-sbcl* "sbcl"
      clds-demo:*planner-python* "python3")
```

Calls are synchronous. Each worker has a 60-second bound, is waited for or
killed and reaped on failure, and removes temporary sources and ASDF output.
The parent removes request/result files on both success and failure. No
persistent worker is started. The source checkout's active problem and settings
and the caller's loaded Wouldwork package are left alone. Missing prerequisites
signal an error while preserving previous study checks, proposals and approvals.

## Run the tests

After loading either entry file:

```lisp
(asdf:test-system "declarative-analysis")
```

This runs 29 grammar and real Wouldwork domain checks in one isolated worker,
then 5 package integration checks through the ordinary REPL API. The checks
cover metadata and unit counts, alternate paired routes, independent-group
eligibility, missing or contradicted premises, incomplete pairs, configuration
atomicity, revision/selection invalidation, source immutability, worker state
transport, unavailable backends, caller isolation, and data-only reading.
They test prototype behavior; they do not validate numerical inference or the
draft scientific rule catalog. `test-op` requires the planner prerequisites.

The original standalone runners remain available:

```sh
python3 examples/declarative-analysis/run-grammar.py
python3 examples/declarative-analysis/run-grammar.py --check
```

The runner accepts `--wouldwork`, `--quicklisp`, and `--sbcl` paths. The full
demonstration configures a goal, checks the study, finds paired-analysis routes,
records an explicit selection, and demonstrates stale selections after edits.

## Remaining milestones

Implement qualified numerical execution and a computed local report; verify
restricted paired-t equivalence against independent results; then implement
context-sensitive comparisons and additional rule families. The clinical and
qPCR entries are extension specifications, not runnable inference examples.

## What a proposal must contain

Record the target, model/inference contract, ordered computational steps or
execution DAG, supported claims, premises with provenance, pending obligations,
warnings, implementation availability/qualification, rule trace, search bounds,
and comparison evidence. Report conditional proposals as conditional. A failed
search is not a diagnosis of scientific impossibility.

Optional and required diagnostics belong to explicit context/claim policies.
They must not be hidden in hand-written workflow order. An execution result
records what actually happened and can invalidate a predicted plan, requiring
updated proposals or a report of the unresolved issue.

## Success criterion

The high-level form yields different justified proposals when design metadata
change, shows the paired-t equivalence only under its recorded conditions,
executes one selected route into a real local report, and explains what it
cannot support. Preserve a small working end-to-end example before expanding
to clinical data or molecular assay normalization.
