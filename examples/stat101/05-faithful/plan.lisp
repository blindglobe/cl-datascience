;;;; examples/stat101/05-faithful/plan.lisp - see src/examples.lisp

(:objects ((frame faithful)
           (variable eruptions waiting))

 :facts ((continuous eruptions)      ; duration, minutes
         (continuous waiting))       ; minutes to the next eruption

 :knowledge ((plain)
             ;; after a check of the distribution: two modes
             (bimodal (bimodal eruptions))
             ;; declared: rows are consecutive eruptions (R's documentation
             ;; does not say; lag-1 autocorrelation -0.55 suggests it)
             (time-ordered (row-order-time faithful)))

 :questions ((describe (described eruptions))
             (inference (inferred-trend> waiting eruptions))))
