  -*- mode: Markdown -*-


Tentative Project title:  Common Lisp Data Science

Goal: tools to build a philosophy for data science practice, enforced
through a DSL.  This should be general enough for practical activities
using R or Python, but enforced via a Common-Lisp based DSL because
I'm ("we") are difficult.





## Examples and tests

`examples/1d-analysis.lisp` sketches the verbs of a data science
activity. `examples/stat101/` works through Statistics 101 examples: each
analysis is checked against R, and the choice of methods is made by the
wouldwork planner from what is declared about the data and what is
asked. See `examples/stat101/README.md` and `docs/VERBS.md`.

The test suite runs with SBCL and `~/quicklisp`, and with Roswell:

```sh
scripts/test.sh            # both
scripts/test.sh sbcl
scripts/test.sh ros
```

Working rules for contributors and agents are in AGENTS.md.
