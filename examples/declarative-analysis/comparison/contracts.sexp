;; Copyright (c) 2026 Gwang Jin Kim. SPDX-License-Identifier: MIT.
;; Proposed comparison contracts. No ranking/equivalence engine is implemented.

(:schema-version 0
 :equivalence
 ((:id :paired-t-and-one-sample-differences
   :status :derivation-and-backend-validation-required
   :members (:paired-t :one-sample-t-on-differences)
   :required-identity
   (:estimand :complete-pairs :difference-direction :null-value :confidence-level
    :alternative :exclusions :weights :inferential-premises)
   :claims-to-compare (:point-estimate :standard-error :degrees-of-freedom
                       :test-statistic :p-value :confidence-interval)
   :numerical-qualification (:tolerance :explicit :reference :independent-implementation)
   :source-ids (:paired-t-derivation :r-t-test))

  (:id :intercept-only-on-differences
   :status :later-extension
   :members (:paired-t :ols-intercept-on-identical-differences)
   :must-prove (:same-residual-variance-estimate :same-degrees-of-freedom
                :same-test-and-interval-definition)
   :not-a-claim-about :arbitrary-regression-models))

 :partial-order
 (:precondition :same-target-and-requested-claim
  :dimensions (:supported-guarantees :unresolved-premises :diagnostic-coverage
               :qualified-implementation :numerical-error :computation-cost)
  :comparison-results (:equivalent :dominates-under-stated-conditions
                       :incomparable :different-target :insufficient-evidence)
  :preference-policy (:user-specified :versioned :explanation-required)
  :statistical-efficiency-order (:requires :specified-data-generating-model-and-evidence)
  :prohibited-shortcuts (:shortest-plan-is-statistically-best
                         :narrowest-observed-interval-is-best
                         :most-significant-p-value-is-best
                         :higher-float-precision-means-better-inference))

 :precision-vocabulary
 ((:statistical :sampling-variance-interval-width-and-coverage-under-a-model)
  (:numerical :algorithmic-error-conditioning-and-floating-point-tolerance)
  (:monte-carlo :simulation-error-with-seed-repetitions-and-error-assessment)))
