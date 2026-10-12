;; Copyright (c) 2026 Gwang Jin Kim. SPDX-License-Identifier: MIT.
;; Inert rule research/design records; WHEN/DERIVE/REQUIRE are proposed vocabulary.
;; Every record inherits draft-review-required. No rule compiler exists yet.
;; Source identifiers resolve through ../RULE-SOURCES.md.

(:schema-version 0
 :default-review-status :draft-review-required
 :premise-states (:unknown :declared :supported-by-evidence :contradicted :waived-for-limited-claim)
 :proposal-states (:supported-under-declared-premises :conditional-on-obligations
                   :structurally-incompatible :unavailable-backend)
 :rules
 ((:id :R01-measurement-meaning
   :family :representation
   :when (:numeric-storage :nominal-statistical-type)
   :derive (:categorical-summary-candidate)
   :restrict-claim :arithmetic-mean-as-meaningful-category-summary
   :explanation "Numeric storage alone does not give category codes arithmetic meaning."
   :source-ids (:tony-data :local-policy)
   :counterexample "Counts stored as integers are not nominal category codes.")

  (:id :R02-independent-design
   :family :experimental-design
   :when (:two-group-variable :independent-assignment-units :no-pairing)
   :derive (:independent-group-contrast-structure)
   :require (:independent-case-scope-and-provenance)
   :explanation "The design supplies the independence structure; row order does not."
   :source-ids (:tony-dataframe :replication-primary))

  (:id :R03-paired-design
   :family :experimental-design
   :when (:two-group-variable :paired-by-case :one-prepared-value-per-case-and-group)
   :derive (:within-case-contrast-construction)
   :require (:explicit-contrast-direction :complete-pair-or-missingness-policy)
   :explanation "Construct treatment minus control within the declared pair."
   :source-ids (:tony-dataframe :paired-t-derivation))

  (:id :R04-technical-aggregation
   :family :preparation
   :when (:repeated-readings-within-aliquot :known-identities :approved-aggregation-policy)
   :derive (:candidate-aggregate-readings-within-aliquot)
   :preserve (:biological-source :assignment-unit :pairing :units :raw-values :provenance)
   :require (:replicate-quality-policy :missing-reading-policy)
   :explanation "Combine technical readings for their intended aliquot-level quantity."
   :source-ids (:replication-primary :local-policy)
   :counterexample "Unequal precision or a different target can require another model or weighting.")

  (:id :R05-independent-case-count
   :family :representation
   :when (:known-independent-case-key :repeated-measurement-records)
   :derive (:independent-case-count-from-keys-and-design)
   :restrict-claim :measurement-row-count-is-independent-sample-count
   :explanation "Repeated readings do not create new independent biological cases."
   :source-ids (:tony-dataframe :replication-primary))

  (:id :R06-unknown-premise
   :family :epistemic-state
   :when (:required-premise-has-no-recorded-status)
   :derive (:unknown-premise :pending-obligation)
   :prohibit (:infer-false-from-absence :accept-assumption-as-search-action)
   :explanation "Unspecified scientific information stays unresolved."
   :source-ids (:local-policy))

  (:id :R07-calibration-and-units
   :family :measurement
   :when (:goal-requests-calibrated-quantity :source-is-raw-signal)
   :derive (:calibration-obligation)
   :require (:applicable-calibration-model :units :calibration-provenance)
   :supported-weaker-claim :describe-observed-signal
   :explanation "Raw instrument signal cannot be relabeled as concentration or activity."
   :source-ids (:tony-data :local-policy))

  (:id :R08-welch-candidate
   :family :inference
   :when (:continuous-response :independent-group-contrast-structure :mean-difference-goal)
   :derive (:welch-two-sample-candidate)
   :require (:independence-premise :sampling-model-and-approximation-assessment
             :nondegenerate-group-variance :qualified-backend)
   :guarantee :conditional-approximate-inference
   :explanation "Welch inference uses separate group variance estimates; validity is conditional."
   :source-ids (:r-t-test :local-policy)
   :research-needed (:distributional-derivation :small-sample-limits :robustness-evidence))

  (:id :R09-paired-t-candidate
   :family :inference
   :when (:within-case-contrast-construction :population-mean-within-case-difference-goal)
   :derive (:paired-t-candidate)
   :require (:independent-differences :accepted-normal-difference-model-for-exact-inference
             :at-least-two-complete-cases :positive-finite-difference-variance :qualified-backend)
   :guarantee :finite-sample-t-inference-under-iid-normal-difference-premises
   :supported-weaker-claim :describe-observed-within-case-differences
   :explanation "The model concerns paired differences, not separate normality tests on each arm."
   :source-ids (:paired-t-derivation :r-t-test))

  (:id :R10-difference-route
   :family :composition-and-equivalence
   :when (:same-complete-differences :same-direction-null-confidence-and-exclusions
           :same-inferential-premises)
   :derive (:candidate-one-sample-t-on-differences :restricted-paired-t-equivalence)
   :require (:equivalence-derivation :backend-comparison-with-tolerance)
   :explanation "The one-sample route analyzes the identical donor-level differences."
   :source-ids (:paired-t-derivation :r-t-test)
   :counterexample "Different exclusions, weights, nulls, or interval definitions break the claim.")

  (:id :R11-dependent-observations
   :family :claim-compatibility
   :when (:paired-or-nested-design :proposed-independent-observation-uncertainty)
   :derive (:unsupported-independence-based-uncertainty-claim)
   :supported-weaker-claim :descriptive-computation
   :explanation "A numerical summary can exist without supporting its proposed standard error."
   :source-ids (:tony-dataframe :replication-primary))

  (:id :R12-diagnostic-evidence
   :family :diagnostics
   :when (:diagnostic-output)
   :derive (:scoped-evidence-record)
   :prohibit (:diagnostic-proves-independence :normality-p-value-selects-test-automatically)
   :require (:diagnostic-purpose :limits :explicit-action-policy)
   :explanation "Record evidence and concerns without replacing design or modeling premises."
   :source-ids (:tony-model :local-policy))

  (:id :R13-numerical-feasibility
   :family :numerical-analysis
   :when (:chosen-estimator-and-inference-backend)
   :require (:finite-prepared-values :sufficient-independent-cases
             :variance-or-rank-requirements :conditioning-assessment-if-applicable
             :convergence-assessment-if-applicable :numerical-tolerance)
   :derive (:feasibility-evidence-or-execution-obligation)
   :explanation "Numerical feasibility is checked separately from scientific applicability."
   :source-ids (:r-t-test :tony-model :local-policy))

  (:id :R14-clinical-chronology
   :family :causal-interpretation
   :when (:assignment-before-outcome :proposed-later-outcome-causes-earlier-assignment)
   :derive (:contradicted-causal-direction-under-declared-chronology)
   :supported-weaker-claim :separate-predictive-question-with-its-own-contract
   :explanation "Prediction and causal direction are distinct claims; chronology alone does not identify effects."
   :source-ids (:tony-dataframe :local-policy)
   :research-needed (:explicit-temporal-model :identification-premises-and-counterexamples))

  (:id :R15-baseline-adjustment
   :family :clinical-design
   :when (:randomized-parallel-group-trial :prognostic-baseline-covariate)
   :derive (:candidate-prespecified-baseline-adjustment)
   :require (:target-and-model-specification :compatible-inference-contract)
   :explanation "Consider baseline adjustment in its randomized-trial context."
   :source-ids (:fda-baseline)
   :counterexample "A post-treatment variable is not automatically an eligible baseline adjustment.")

  (:id :R16-missingness-and-intercurrent-events
   :family :missing-data-and-estimand
   :when (:missing-censored-or-coarsened-values-or-intercurrent-event)
   :derive (:typed-reason-and-target-obligations)
   :prohibit (:silently-drop-values :replace-nondetect-by-zero-by-default
              :treat-treatment-discontinuation-as-identical-to-missing-outcome)
   :require (:measurement-or-event-meaning :explicit-policy :target-preservation-assessment)
   :explanation "The reason for unavailable information affects preparation and interpretation."
   :source-ids (:tony-missing :ich-e9-r1 :miqe-2 :local-policy))

  (:id :R17-implementation-availability
   :family :resources
   :when (:scientifically-applicable-candidate)
   :require (:available-backend :recorded-qualification :version-and-runtime-provenance)
   :derive (:execution-availability-status)
   :prohibit (:missing-backend-refutes-scientific-applicability)
   :explanation "A valid analytical idea can remain unavailable for execution in this environment."
   :source-ids (:tony-model :local-policy))

  (:id :R18-report-contract
   :family :reporting-and-execution
   :when (:proposals-or-executed-analysis)
   :require (:target :design :premises :diagnostics :rule-trace :pending-obligations
             :comparison-evidence :search-bounds :data-and-code-provenance)
   :derive (:report-content-contract)
   :prohibit (:claim-executed-result-from-symbolic-plan :publish-during-search)
   :explanation "A report states what was proposed, what was executed, and what remains unsupported."
   :source-ids (:tony-talk :tony-procedures :local-policy))))
