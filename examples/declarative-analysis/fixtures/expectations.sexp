;; Copyright (c) 2026 Gwang Jin Kim. SPDX-License-Identifier: MIT.
;; Acceptance specifications, not results from an implemented recommendation engine.

(:schema-version 0
 :scenarios
 ((:id :paired-structure
   :study :paired-aliquots :goal :paired-mean-contrast
   :expect (:independent-case-count 3
            :conditional-candidates (:paired-t :one-sample-t-on-differences)
            :obligations (:accept-iid-normal-difference-premise :qualify-backend)
            :supported-weaker-output :descriptive-paired-differences))

  (:id :independent-structure
   :study :independent-cultures :goal :independent-mean-contrast
   :expect (:independent-case-count 6 :conditional-candidate :welch-two-sample
            :incompatible-for-requested-design :paired-t))

  (:id :technical-duplicates
   :study :paired-technical-duplicates :goal :paired-mean-contrast
   :expect (:measurement-row-count 12 :independent-case-count 3
            :required-step :aggregate-within-aliquot
            :retain-relations (:donor :aliquot :technical-reading)
            :same-prepared-values-as :paired-aliquots))

  (:id :unknown-pairing
   :study :paired-aliquots :goal :paired-mean-contrast
   :change (:remove-metadata :paired-by)
   :expect (:obligation :clarify-design :must-not-infer-pairing :from-row-order))

  (:id :incomplete-pair
   :study :paired-aliquots :goal :paired-mean-contrast
   :change (:remove-record M6)
   :expect (:obligation :explicit-incomplete-pair-policy
            :must-not-silently-delete :incomplete-donor))

  (:id :restricted-equivalence
   :study :paired-aliquots :goal :paired-mean-contrast
   :change (:accept-premise :iid-normal-paired-differences)
   :expect (:equivalent-contracts (:paired-t :one-sample-t-on-differences)
            :conditions (:same-differences :same-settings :qualified-backends)))

  (:id :target-changed
   :study :paired-aliquots :goal :paired-mean-contrast
   :change (:quantity :median-within-donor-difference)
   :expect (:must-not-classify-as-equivalent :mean-contrast-inference))

  (:id :row-permutation
   :study :paired-aliquots :goal :paired-mean-contrast
   :change (:permute-records (M6 M2 M4 M1 M5 M3))
   :expect (:same-analysis-contracts-and-values-as :paired-structure))

  (:id :unsupported-independent-wells-claim
   :study :paired-technical-duplicates :goal :paired-mean-contrast
   :expect (:unsupported-uncertainty-claim :independent-wells
            :descriptive-access-to-readings :available))

  (:id :bounded-search
   :study :paired-technical-duplicates :goal :paired-mean-contrast
   :change (:search-depth-bound 1)
   :expect (:must-report :bound-and-truncation
            :must-not-report :no-valid-analysis-exists))

  (:id :clinical-time-order
   :study :clinical-chronology :goal :clinical-treatment-effect
   :change (:propose-causal-edge (week-four-outcome treatment))
   :expect (:contradicted-claim :backwards-causal-edge
            :prediction-goal :requires-separate-contract
            :chronology-alone-proves-causality :false))

  (:id :unavailable-backend
   :study :paired-aliquots :goal :paired-mean-contrast
   :change (:backends :none)
   :expect (:execution-status :unavailable-backend
            :scientific-applicability :not-refuted))))
