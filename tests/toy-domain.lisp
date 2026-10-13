;;;; tests/toy-domain.lisp - a tiny wouldwork domain for testing the
;;;; planner bridge. Same shape as examples/stat101/domain.lisp: relations
;;;; and actions only; types, init and goal are added by FIND-PLANS. Each
;;;; action records itself with (used <action>), so that plans using
;;;; different actions end in different states.

(define-dynamic-relations
  (raw item)
  (dirty item)
  (washed item)
  (peeled item)
  (cooked item)
  (used method))

(define-action wash 1
  (?i item)
  (and (raw ?i) (not (washed ?i)))
  (?i)
  (assert (washed ?i) (used wash)))

(define-action assume-clean 1          ; an assumption: allowed unless known dirty
  (?i item)
  (and (not (washed ?i)) (not (dirty ?i)))
  (?i)
  (assert (washed ?i) (used assume-clean)))

(define-action peel 1                  ; never needed for the goal
  (?i item)
  (not (peeled ?i))
  (?i)
  (assert (peeled ?i) (used peel)))

(define-action boil 1
  (?i item)
  (and (washed ?i) (not (cooked ?i)))
  (?i)
  (assert (cooked ?i) (used boil)))

(define-action fry 1
  (?i item)
  (and (washed ?i) (not (cooked ?i)))
  (?i)
  (assert (cooked ?i) (used fry)))
