# Changelog

## [Unreleased]

### Added
- Example 01 sleep as a planning problem: nothing declared gives
  assume-rows-independent then welch-t-test (R's default, assumption
  shown); declared independence gives welch-t-test; declared pairing gives
  paired-t-test or signed-rank-test. Domain: two-group methods and the
  row-independence assumption.
- Example 00 one variable, as a planning problem: `plan.lisp` (objects,
  facts, states of knowledge, questions), `wish.lisp` and README. The
  shared method actions start in `examples/stat101/domain.lisp`
  (describe, next value). `load-example` and `example-plans`
  (src/examples.lisp) read an example and plan one question under one
  state of knowledge.
- R references for six Statistics 101 examples (examples/stat101/): one
  variable (A.J. Rossini's two datasets from examples/1d-analysis.lisp),
  sleep, cars, ToothGrowth, UCBAdmissions, faithful. Each `reference.R`
  (base R) writes `reference.out`, `expected.json` (the numbers a Lisp
  version must reproduce, names kept) and its data as CSV. R 4.6.1 and
  jsonlite are pinned with uvr; `run-references.sh` reruns all.
- `find-plans` (src/planner.lisp): asks the wouldwork planner for every
  minimal plan that reaches a goal from a set of facts, using a domain file
  of relations and actions. Writes and stages a wouldwork problem, returns
  plans as keyword lists, shortest first; plans that add unneeded steps (an
  assumption they do not use) are dropped. `plan-assumptions` lists the
  `assume-...` steps of a plan; `planning-error` reports wouldwork's output.
  Tested with a toy domain (tests/toy-domain.lisp).

- ASDF systems `cl-datascience` and `cl-datascience/tests` (FiveAM), with
  `tests/run.lisp` and `scripts/test.sh` running the suite under SBCL with
  `~/quicklisp` and under Roswell alike. AGENTS.md records the working rules
  (test first, both Lisp setups, uvr for R, small commits, this changelog).

### Fixed
- Actions with several parameters of one type use wouldwork's `product`
  header. With the default, an example with fewer objects than parameters
  (example 00: two variables, a four-parameter action) crashed the planner
  with "too few elements ... to satisfy lambda list".
- A problem that fails to stage no longer breaks the wouldwork
  installation: wouldwork compiles its staged problem on every load, so
  `find-plans` stages wouldwork's own `blocks3` again after a failure, and
  `tests/run.lisp` repairs an installation left broken by a killed process.
- `tests/run.lisp` ends with a failure status on any error; under Roswell
  an error used to wait in the debugger and then exit with status 0.
