;;;; examples/stat101/domain.lisp - the method actions of the Statistics 101
;;;; examples, in wouldwork syntax.
;;;;
;;;; This file is the "procedure library" seen by the planner. A user asks
;;;; a question (a goal such as (estimated-difference> extra group)); the
;;;; planner finds every minimal sequence of these actions that answers it
;;;; from what is known (the facts of plan.lisp). An action's precondition
;;;; is what the method requires; its effect is what it delivers.
;;;;
;;;; Conventions
;;;; - Types: frame (a dataset), variable (a column), method (filled in by
;;;;   find-plans with every action name).
;;;; - Relations ending in > are directional (wouldwork treats relations
;;;;   whose arguments share a type as symmetric unless marked with >).
;;;; - Every action asserts (used <action>): the final state records which
;;;;   methods answered the question.
;;;; - Actions named assume-... make an assumption. They are only possible
;;;;   when nothing known contradicts the assumption, and they appear in a
;;;;   plan only when the plan needs them. A plain dataset with nothing
;;;;   declared therefore gets R's default method, with its assumptions
;;;;   listed in the plan.
;;;; - Only what can be known before running a method is planned. Results
;;;;   that depend on the values (does a check find unequal spread?) enter
;;;;   as facts of a :knowledge entry after the check, and the question is
;;;;   planned again.

(define-dynamic-relations
  ;; what a variable is (from storage types or declared)
  (categorical variable)
  (continuous variable)
  ;; how the values came about
  (random-process variable)
  (known-pattern variable)
  ;; answers
  (described variable)
  (predicted-next variable)
  (estimated-probabilities variable)
  ;; record
  (used method))

;;; One variable: describe

(define-action describe-categorical 1          ; levels, counts, proportions, bar chart
  (?v variable)
  (and (categorical ?v) (not (described ?v)))
  (?v)
  (assert (described ?v) (used describe-categorical)))

(define-action describe-continuous 1           ; mean, sd, quantiles, histogram
  (?v variable)
  (and (continuous ?v) (not (described ?v)))
  (?v)
  (assert (described ?v) (used describe-continuous)))

;;; One variable: the next value. Which question makes sense depends on how
;;; the values came about (examples/1d-analysis.lisp).

(define-action continue-pattern 1              ; the structure is known
  (?v variable)
  (and (known-pattern ?v) (not (predicted-next ?v)))
  (?v)
  (assert (predicted-next ?v) (used continue-pattern)))

(define-action estimate-category-probabilities 1   ; most likely value and how wrong we could be
  (?v variable)
  (and (categorical ?v) (random-process ?v) (not (estimated-probabilities ?v)))
  (?v)
  (assert (estimated-probabilities ?v) (predicted-next ?v)
          (used estimate-category-probabilities)))

(define-action estimate-mean-and-spread 1      ; prediction interval for the next value
  (?v variable)
  (and (continuous ?v) (random-process ?v) (not (predicted-next ?v)))
  (?v)
  (assert (predicted-next ?v) (used estimate-mean-and-spread)))

(define-action assume-random-process 1
  (?v variable)
  (and (not (random-process ?v)) (not (known-pattern ?v)))
  (?v)
  (assert (random-process ?v) (used assume-random-process)))
