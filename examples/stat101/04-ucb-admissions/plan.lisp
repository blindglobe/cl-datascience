;;;; examples/stat101/04-ucb-admissions/plan.lisp - see src/examples.lisp

(:objects ((frame ucb)
           (variable admit gender dept freq))

 :facts ((binary admit)              ; Admitted or Rejected
         (two-levels gender)
         (categorical dept))         ; six departments

 :knowledge ((plain)
             ;; one row per cell; freq counts the applicants
             (counts (frequency-weights ucb freq))
             ;; and the order of events: gender, then the choice of
             ;; department, then the admission decision
             (timing (frequency-weights ucb freq)
                     (measured-before> gender dept)
                     (measured-before> dept admit)
                     (measured-before> gender admit)))

 :questions ((total-effect (estimated-total-effect> admit gender))
             (direct-effect (estimated-direct-effect> admit gender))))
