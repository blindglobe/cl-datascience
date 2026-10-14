# Finding and qualifying the rules

Copyright (c) 2026 Gwang Jin Kim. SPDX-License-Identifier: MIT.

The catalog's source identifiers refer to this document. Entries are research
starting points, not endorsements of every draft rule or a completed review.
Record a precise passage/section or mathematical derivation when qualifying a
rule. A source may justify an implementation convention without proving an
inferential guarantee. Access checked on 2026-10-12 where noted below.

## Tony's representation and process intentions

Reference repository: `common-lisp-stat`, in any available local checkout. The historical code is a
design reference; many procedures and examples are explicitly prototypes.

- **tony-data:** `src/data/data.lisp:25`: multiscale metadata; storage form,
  computational type, statistical type. Lines 76 onward describe statistical
  variables; lines 205 onward discuss observations and dependence.
- **tony-dataframe:** `src/data/dataframe.lisp:36`: computable statistical
  semantics and exploratory assumption violations; lines 94 onward describe
  the cases-by-variables contract; line 156 distinguishes rows from cases;
  line 203 discusses measured versus design-set variables.
- **tony-procedures:** `src/procedures/procedures.lisp:22`: procedure components;
  line 86 describes required statistical metadata; line 103 proposes a
  metadata/data consistency generic.
- **tony-missing:** `src/data/missing-data.lisp:59`: first-class censoring,
  coarsening and missingness, with context-sensitive policies.
- **tony-model:** `src/stat-models/model.lisp:320`: models, inference,
  implementations, and context as distinct concerns.
- **tony-talk:** `Doc/talks/Rossini-Reisensburg-2014-CLS.tex:438`: explicit
  assumptions, computations, and claims; line 524 sketches dataset metadata
  and `propose-analysis`.

These source IDs support intended architecture. They do not qualify a
mathematical result. Inspect the exact checkout/version used and record it
with any implementation that relies on the design interpretation.

## Primary statistical and clinical sources

- **r-t-test:** [R stats t.test documentation](https://stat.ethz.ch/R-manual/R-devel/library/stats/html/t.test.html).
  Checked 2026-10-12. Documents paired inputs, the Welch/pooled-variance
  distinction, and outputs. Use for backend behavior and independent numerical
  comparison; obtain a derivation for finite-sample distributional guarantees.
- **paired-t-derivation:** Required local derivation, not yet supplied. Define
  complete differences d_i = treatment_i - control_i, their sample mean and
  SD, t = (mean(d)-null)/(sd(d)/sqrt(n)), degrees of freedom n-1, and the
  specified confidence interval. Establish the iid normal-difference premises
  for finite-sample t inference. Prove equivalence only for identical analysis
  inputs/settings. Validate implementations independently.
- **replication-primary:** [Lazic et al., What exactly is N in cell culture and animal experiments?](https://pmc.ncbi.nlm.nih.gov/articles/PMC5902037/).
  Investigate experimental units, biological units, subsampling, and the
  limits of reducing hierarchical measurements to one value per unit.
- **fda-baseline:** [FDA guidance on adjusting covariates in randomized trials](https://www.fda.gov/regulatory-information/search-fda-guidance-documents/adjusting-covariates-randomized-clinical-trials-drugs-and-biological-products).
  Checked 2026-10-12. Concerns prognostic baseline adjustment in randomized
  parallel-group trials. Do not generalize its scope to observational
  confounding control or every post-treatment covariate analysis.
- **ich-e9-r1:** [ICH E9(R1), FDA-hosted final guidance](https://www.fda.gov/media/148473/download).
  Checked 2026-10-12. Use to distinguish the clinical question/estimand,
  intercurrent-event strategy, estimator, and sensitivity analysis. Missing
  outcomes and treatment discontinuation are different concepts.
- **miqe-2:** [MIQE 2.0, Clinical Chemistry (2025)](https://academic.oup.com/clinchem/article/71/6/634/8119148).
  Starting point for qPCR metadata and reporting. Read the relevant sections
  before encoding normalization requirements: reference validation, efficiency,
  controls, replicate handling, and detection/quantification limits. This
  catalog intentionally does not prescribe a normalization formula yet.
- **local-policy:** A proposed project policy, not an external theorem.
  Identify its rationale, scope, author/review state, and override semantics.

## Questions to ask of each candidate rule

What is the estimand? Which claim depends on this rule? Is it about data
representation, design, a theorem, numerical behavior, interpretation, or a
reporting convention? Which assumptions are supplied by the scientist? Which
can be assessed imperfectly by diagnostics? What counterexample breaks the
claim? What weaker result remains useful? Does a changed transformation,
weighting, exclusion, or missing-data policy change the target?

For a transformation, check units, scope, information loss, dependencies,
reversibility, and what metadata must survive. For inference, check the
sampling/randomization model, dependence, finite-sample versus asymptotic
status, missingness, coverage/error-rate statement, and multiplicity context.
For causal rules, record assignment mechanisms, time ordering, intervention
meaning, and identification assumptions. Chronology is a necessary restriction
on some causal claims, not a complete causal identification argument.

For ordering, look for a theorem or validation study under a specified design
that compares coverage, bias, variance, efficiency, or numerical error. An
observed shorter interval alone is not a superiority proof. Keep empirical
evidence, theoretical guarantees, and user preferences separate.

## Admission record

Every implemented rule needs an ID/version; family; structured premises;
derived artifacts/properties; affected claim; unresolved obligations;
warning/error/override semantics; sources with exact locations; guarantee
class; counterexamples; tests; reviewer/status; implementation dependencies;
and a user-readable explanation. Draft rules stay visibly draft. Rule changes
must be versioned so an old report can be reconstructed under its old rules.
