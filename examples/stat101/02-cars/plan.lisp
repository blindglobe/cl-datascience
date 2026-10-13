;;;; examples/stat101/02-cars/plan.lisp - see src/examples.lisp

(:objects ((frame cars)
           (variable dist speed))

 :facts ((continuous dist)           ; stopping distance, ft
         (continuous speed))         ; mph

 :knowledge ((plain)
             (independent (rows-independent cars))
             ;; after a check of the residuals: spread grows with speed
             (spread-checked (nonconstant-spread> dist speed)))

 ;; the purpose of the regression is part of the question
 :questions ((trend (estimated-trend> dist speed))
             (inference (inferred-trend> dist speed))
             (prediction (prediction-interval> dist speed))))
