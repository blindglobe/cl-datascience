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

## Setup on a new machine

Use ocicl for project-local, locked dependencies. See [SETUP.md](SETUP.md)
for explicit ocicl installation commands on macOS/Debian, ASDF registration,
installation locations and custom paths.
With Homebrew available on macOS, or a supported Linux package manager:

```sh
bash examples/declarative-analysis/setup.sh --install-system --test
sbcl --load examples/declarative-analysis/.deps/load.lisp
```

The script installs OS tools when explicitly requested, restores the committed
`ocicl.csv`, including Wouldwork installed by ocicl from a pinned Git source. It reuses a working ocicl
2.20.0+ or builds one locally. Quicklisp is optional. Setup and tests are
synchronous; loading the package performs no installation.

## Files that exist now

| File | Responsibility |
|---|---|
| `SETUP.md`, `setup.sh`, `setup.py`, `ocicl.csv` | Fresh-machine setup and locked Lisp dependencies |
| `GRAMMAR.md` | Our grammar, revision semantics, and current runtime limits |
| `AGENTS.md` | Implementation instructions and scientific constraints |
| `declarative-analysis.asd`, `load.lisp`, `src/` | Loadable mini package, CLOS grammar, fixtures, isolated Wouldwork adapter |
| `interface/grammar-demo.lisp` | Executable high-level laboratory example |
| `run-grammar.py`, `tests/` | Isolated runtime, 29 domain checks and 8 package integration checks |
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

## ASDF discovery and planner isolation

Both collaborators use SBCL. The grammar has only UIOP as an in-image dependency;
the worker libraries are Alexandria, Iterate and Lparallel. ASDF resolves their
transitive dependency sources when a proposal is requested. The standalone
launcher and the REPL have no assumed repository or Quicklisp directory.

If ASDF already knows the systems, load normally:

```lisp
(asdf:load-system "declarative-analysis")
(defparameter experiment (clds-demo:demo))
(clds-demo:propose experiment :analysis)
```

The setup script writes an ASDF registry for the directories you choose.
`--prefix` selects the dependency location; `--wouldwork-source` can reuse a
checkout anywhere. Its generated loader uses relative registry entries and
`asdf:load-system`, supporting movement of the whole installation. Independent
moves require updated ASDF registration. See [SETUP.md](SETUP.md).

Wouldwork's definition is located using `asdf:locate-system`, without evaluating
its initializer in the original checkout. Only the copied system is loaded in
a temporary SBCL worker. The worker receives ASDF-resolved source directories
as data, uses the same SBCL executable as the caller, and needs no guessed
Quicklisp or ocicl startup path. An explicit `*wouldwork-source*` override is
available for special cases; its default is NIL, meaning ASDF discovery.

Calls are synchronous and bounded. Workers are waited for or killed and reaped
on failure; temporary sources and ASDF output are removed. No persistent worker
is started. The caller's Wouldwork state and source checkout are preserved.
Missing registered systems signal an error while preserving previous study
checks, proposals and approvals. Loading the grammar performs no installation.

## Run the tests

After loading either entry file:

```lisp
(asdf:test-system "declarative-analysis")
```

This runs 29 grammar and real Wouldwork domain checks in one isolated worker,
then 8 package integration checks through the ordinary REPL API. The checks
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

The runner uses ASDF source discovery. `--dependency-setup` accepts a registry
initializer, and an explicit `--quicklisp` can initialize an existing Quicklisp
environment. Neither initializer path is guessed. `--wouldwork` remains an
explicit source override. The full
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
