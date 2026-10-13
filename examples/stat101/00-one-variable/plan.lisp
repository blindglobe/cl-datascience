;;;; examples/stat101/00-one-variable/plan.lisp
;;;;
;;;; What is known and what is asked, for the planner (see
;;;; src/examples.lisp). Data: A.J. Rossini's two datasets from
;;;; examples/1d-analysis.lisp.

(:objects ((frame song guitar)
           (variable stanza pitch))

 ;; Known from the storage types alone: strings are categorical,
 ;; double floats continuous.
 :facts ((categorical stanza)
         (continuous pitch))

 :knowledge ((plain)                                   ; nothing declared
             (pattern-known (known-pattern stanza))    ; the song's structure is known
             (random (random-process stanza)           ; values arise by chance
                     (random-process pitch)))

 :questions ((describe-stanza (described stanza))
             (describe-pitch (described pitch))
             (next-stanza (predicted-next stanza))
             (stanza-probabilities (estimated-probabilities stanza))
             (next-pitch (predicted-next pitch))))
