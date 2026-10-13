# Changelog

## [Unreleased]

### Added
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
- A problem that fails to stage no longer breaks the wouldwork
  installation: wouldwork compiles its staged problem on every load, so
  `find-plans` stages wouldwork's own `blocks3` again after a failure, and
  `tests/run.lisp` repairs an installation left broken by a killed process.
- `tests/run.lisp` ends with a failure status on any error; under Roswell
  an error used to wait in the debugger and then exit with status 0.
