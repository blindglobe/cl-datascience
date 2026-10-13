# Agents guide - cl-datascience

Common Lisp Data Science (CLDS): tools for a philosophy of data science
practice, enforced through a Common Lisp DSL (see README.md). Work is
examples first: textbook analyses are written before the DSL, to find out
which verbs, components and hints are needed.

## Layout

- `examples/1d-analysis.lisp` - A.J. Rossini's sketch of the verbs. Do not
  edit it without asking him; refer to it.
- `examples/stat101/` - Statistics 101 examples. Each has a README, an R
  reference (`reference.R`, `reference.out`, `expected.json`, `data.csv`), a
  design sketch (`wish.lisp`) and a planning specification (`plan.lisp`).
  `examples/stat101/domain.lisp` holds the method actions for the planner.
- `src/` - the `cl-datascience` system: the bridge to the wouldwork planner
  and the example reader.
- `tests/` - FiveAM tests; `tests/run.lisp` is the runner.
- `docs/VERBS.md` - the verbs, in three layers.

## Rules

1. **Test first.** Write or change a test, run it and see it fail, then
   change the code or the example until it passes.
2. **Two ways to run Lisp, both supported equally:** SBCL with
   `~/quicklisp`, and Roswell. Run `scripts/test.sh` (both) before every
   commit; `scripts/test.sh sbcl` or `scripts/test.sh ros` for one.
3. **R only through uvr** (`uvr add`, `uvr lock`, `uvr sync`, `uvr run`;
   R version via `uvr r`). Never `install.packages()` or a system R. The R
   references run with `examples/stat101/run-references.sh`.
4. **Git:** one logical change per commit on a topic branch; the message
   says why, and what changed in behaviour. Every commit adds an entry to
   `CHANGELOG.md` under `## [Unreleased]`, in the existing section
   (Added, Changed, Fixed, ...), never a second section of the same name.
   Do not push without the maintainers' agreement.
5. **No emojis** in documentation.

## Wouldwork notes

- The planner is used through `find-plans` (src/planner.lisp). It writes a
  problem file, stages it with wouldwork and returns the minimal plans.
- Staging reloads wouldwork, which resets its problem-folder list; the
  bridge registers its folder before every stage.
- Relations whose arguments share a type are symmetric in wouldwork; use the
  `>` suffix (`estimated-trend>`) for directional relations.
- Actions with several parameters of one type use the `product` header
  (`(product ?y variable ?g variable)`). Wouldwork's default instantiates
  such parameters with distinct objects, and when an example has fewer
  objects than parameters it fails ("too few elements ... to satisfy
  lambda list"; `get-pre-lambda-arg-lists` in wouldwork's ww-support.lisp
  returns a list of empty argument lists). Keep roles apart in the
  precondition, with `(not (eql ?a ?b))` where they could coincide.
- Staging writes `src/problem.lisp` and `vals.lisp` inside the wouldwork
  installation that is loaded (Quicklisp's copy for SBCL, a local project
  for Roswell). Do not run two test processes on the same installation at
  the same time.
- If `~/.sbclrc` loads the ocicl runtime, `tests/run.lisp` turns off its
  automatic downloads so that Quicklisp provides wouldwork.
