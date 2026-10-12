;; Copyright (c) 2026 Gwang Jin Kim. SPDX-License-Identifier: MIT.
;; Inert input specifications. Synthetic values, not experimental evidence.
;; EXTENDS/REPLACE are proposed overlay instructions; implement and validate them.

(:schema-version 0
 :status :design-scaffold
 :shared-variable-descriptors
 ((:name biological-id :storage-type symbol :role :biological-source-id)
  (:name aliquot :storage-type symbol :role :assignment-unit-id)
  (:name condition :storage-type symbol :statistical-type :nominal
   :levels (vehicle treatment) :role :group :origin :set-by-design)
  (:name reading :storage-type integer :role :technical-reading-id)
  (:name response :storage-type double-float :statistical-type :continuous
   :role :outcome :origin :measured :quantity :enzyme-activity :units :u-per-ml))
 :studies
 ((:id :independent-cultures
   :context :molecular-laboratory
   :data
   (:store #2A((C1 A1 vehicle 1 0.81d0)
               (C2 A2 vehicle 1 0.93d0)
               (C3 A3 vehicle 1 0.71d0)
               (C4 A4 treatment 1 1.01d0)
               (C5 A5 treatment 1 1.19d0)
               (C6 A6 treatment 1 0.87d0))
    :var-labels (biological-id aliquot condition reading response)
    :case-labels (M1 M2 M3 M4 M5 M6)
    :row-role :measurement-record :variable-descriptors :shared)
   :study-metadata
   (:assignment-unit biological-id :assignment-mechanism :randomized-between-cultures
    :independent-case biological-id :pairing :none
    :independence (:status :declared :scope :between-cultures :source :synthetic-design)
    :measurement-state (:status :declared :value :calibrated :source :synthetic-design)
    :missingness :none :technical-aggregation :not-needed
    :model-premises ((:id :normal-independent-groups :status :unknown))))

  (:id :paired-aliquots
   :context :molecular-laboratory
   :data
   (:store #2A((D1 A1 vehicle 1 0.81d0)
               (D1 A2 treatment 1 1.01d0)
               (D2 A3 vehicle 1 0.93d0)
               (D2 A4 treatment 1 1.19d0)
               (D3 A5 vehicle 1 0.71d0)
               (D3 A6 treatment 1 0.87d0))
    :var-labels (biological-id aliquot condition reading response)
    :case-labels (M1 M2 M3 M4 M5 M6)
    :row-role :measurement-record :variable-descriptors :shared)
   :study-metadata
   (:assignment-unit aliquot :assignment-mechanism :randomized-within-donor
    :independent-case biological-id :paired-by biological-id
    :independence (:status :declared :scope :between-donors :source :synthetic-design)
    :measurement-state (:status :declared :value :calibrated :source :synthetic-design)
    :missingness :none :technical-aggregation :not-needed
    :model-premises ((:id :iid-normal-paired-differences :status :unknown))))

  (:id :paired-technical-duplicates
   :extends :paired-aliquots
   :replace
   ((:path (:data :store)
     :value #2A((D1 A1 vehicle 1 0.80d0) (D1 A1 vehicle 2 0.82d0)
                (D1 A2 treatment 1 1.00d0) (D1 A2 treatment 2 1.02d0)
                (D2 A3 vehicle 1 0.92d0) (D2 A3 vehicle 2 0.94d0)
                (D2 A4 treatment 1 1.18d0) (D2 A4 treatment 2 1.20d0)
                (D3 A5 vehicle 1 0.70d0) (D3 A5 vehicle 2 0.72d0)
                (D3 A6 treatment 1 0.86d0) (D3 A6 treatment 2 0.88d0)))
    (:path (:data :case-labels) :value (M1 M2 M3 M4 M5 M6 M7 M8 M9 M10 M11 M12))
    (:path (:study-metadata :technical-aggregation)
     :value (:operation :arithmetic-mean :within aliquot :status :declared
             :purpose :estimate-aliquot-response :source :synthetic-analysis-policy))))

  (:id :clinical-chronology
   :status :extension-specification
   :context :randomized-parallel-group-trial
   :columns (subject treatment baseline-biomarker week-four-outcome)
   :metadata
   (:assignment-unit subject :independent-case subject
    :assignment-mechanism :randomized
    :variable-origins ((treatment :set-by-design)
                       (baseline-biomarker :measured) (week-four-outcome :measured))
    :chronology ((baseline-biomarker :before treatment)
                 (treatment :before week-four-outcome))
    :population :synthetic-trial-population
    :intercurrent-event-strategy :not-yet-specified)
   :questions (:which-baseline-adjustments :which-causal-claims :which-estimand-obligations))

  (:id :qpcr-normalization
   :status :extension-specification
   :context :rt-qpcr
   :columns (biological-id aliquot condition gene plate reading cq detection-status)
   :metadata
   (:reference-validation :unknown :amplification-efficiency :unknown
    :measurement-limits :unknown :replicate-policy :unknown
    :nondetect-representation :typed-record-with-reason)
   :questions (:normalization-prerequisites :nondetect-meaning :independent-unit-of-inference))))
