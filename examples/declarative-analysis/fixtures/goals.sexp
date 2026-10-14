;; Copyright (c) 2026 Gwang Jin Kim. SPDX-License-Identifier: MIT.
;; Scientific specifications are separate from source values and search settings.

(:schema-version 0
 :goals
 ((:id :describe-study
   :quantity :observed-response-distribution
   :claim :descriptive
   :requested-outputs (:sample-count :summary :individual-values-plot :report)
   :execution-mode :propose-only)

  (:id :independent-mean-contrast
   :population :independent-cultures-under-declared-protocol
   :quantity :difference-in-population-means
   :contrast (treatment vehicle)
   :claim :population-mean-inference
   :requested-outputs (:estimate :confidence-interval :plot :report)
   :confidence-level 0.95d0 :direction :two-sided :null-value 0.0d0
   :execution-mode :propose-only
   :policy (:inferential-premises :explicit-acceptance-required
            :unresolved-requirements :return-conditional-proposals))

  (:id :paired-mean-contrast
   :population :donors-under-declared-protocol
   :quantity :population-mean-within-donor-difference
   :contrast (treatment vehicle)
   :claim :population-mean-inference
   :requested-outputs (:estimate :confidence-interval :paired-values-plot :report)
   :confidence-level 0.95d0 :direction :two-sided :null-value 0.0d0
   :execution-mode :propose-only
   :policy (:inferential-premises :explicit-acceptance-required
            :unresolved-requirements :return-conditional-proposals
            :comparison :retain-incomparable-candidates))

  (:id :clinical-treatment-effect
   :status :extension-specification
   :population :specified-trial-population :quantity :mean-endpoint-treatment-effect
   :contrast (treatment control) :claim :causal-under-identification-premises
   :endpoint-time :week-four :intercurrent-event-strategy :unknown
   :execution-mode :propose-only))

 :resource-contract
 (:backends (:availability :must-be-discovered :qualification :must-be-recorded)
  :rule-review-policy :reviewed-rules-only
  :search (:mode :serial :depth-bound :explicit :truncation-reporting :required)
  :numerical-tolerances :must-be-specified
  :random-stream (:seed :must-be-recorded-if-used)
  :publication (:adapter :local-file :external-submission :explicit-human-action)))
