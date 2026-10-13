;;;; examples/stat101/00-one-variable/wish.lisp
;;;;
;;;; DESIGN SKETCH - does not load. How the analysis should read once the
;;;; DSL exists. The planner part works today: see plan.lisp and
;;;; tests/stat101-tests.lisp. Numbers in the comments are R's
;;;; (reference.out, R 4.6.1). Data: examples/1d-analysis.lisp.

(defparameter *stanzas* '("A" "B" "A" "B" "C" "B"))
(defparameter *pitch* '(1.2d0 0.8d0 1.0d0 3.2d0 -2.9d0))

;;; 1. Question verbs, nothing declared. The planner picks the method from
;;;    the storage type; the result lists the plan and its assumptions.

(describe-data *stanzas*)
;; => plan      (describe-categorical stanza)
;;    levels    A B C   counts 2 3 1   proportions 0.33 0.50 0.17
;;    plot      bar chart

(predict-next *stanzas*)
;; => plan      (assume-random-process stanza)
;;              (estimate-category-probabilities stanza)
;;    assumes   the stanzas arise by chance
;;    next      B, probability 0.50 (95% interval 0.12 .. 0.88 from 6 values)

(predict-next *pitch*)
;; => plan      (assume-random-process pitch) (estimate-mean-and-spread pitch)
;;    next      about 0.66, 95% prediction interval -6.06 .. 7.38

;;; 2. Declare how the values came about (A.J. Rossini's song example: the
;;;    standard structure has 8 parts, the data show the first 6).

(predict-next (declare-process *stanzas* :known-pattern '("A" "B" "A" "B" "C" "B" "C" "B")))
;; => plan      (continue-pattern stanza)
;;    next      C, then B - no probabilities, nothing assumed

(estimate-probabilities (declare-process *stanzas* :known-pattern '("A" "B" "A" "B" "C" "B" "C" "B")))
;; => no plan: the values do not arise by chance, so "the chance of the
;;    next stanza" is not a question these data can answer.

;;; 3. The same, in the shape of examples/1d-analysis.lisp: the plan
;;;    carries the declarations, the planner fills in the methods.

(report
 (execute-analysis
  :data-source (data-validated
                :data-source-object (data-source-variable *stanzas*)
                :plan-description (create-plan-metadata
                                   :outcome-variables-with-data-types/structures
                                   '((stanza :categorical :known-pattern ("A" "B" "A" "B" "C" "B" "C" "B")))))
  :plan (plan-as-code :specification '(:dimensions 1d :question next-value :plots t))))
