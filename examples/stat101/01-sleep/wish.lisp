;;;; examples/stat101/01-sleep/wish.lisp
;;;;
;;;; DESIGN SKETCH - this file does not load yet. It shows how the analysis
;;;; should read once the statistics layers exist; the choice of methods
;;;; already runs in the planner (plan.lisp, tests/stat101-tests.lisp).
;;;; Every form is tagged with the component that would own it (see
;;;; docs/VERBS.md):
;;;;   [tidyverse] exists today (cl-tidyverse)
;;;;   [statframe] data plus declarations    [stats] descriptives, distributions
;;;;   [models] model fitting                [broom] tidy model output
;;;;   [statproc] question verbs, chosen through the planner
;;;; Numbers in the comments are R's (reference.out, R 4.6.1).

(in-package :tidyverse-user)

(defparameter *sleep*
  (read-csv "examples/stat101/01-sleep/data.csv"))                ; [tidyverse]
;; 20 rows: extra (hours), group ("1" or "2"), ID (patient 1..10)

;;; 1. Plain tibble: nothing declared, nothing checked. Must give exactly
;;;    what R's t.test(extra ~ group) gives: declarations are optional.

(compare :outcome :extra :by :group :data *sleep*)                ; [statproc]
;; => procedure   welch-t-test
;;    chosen      continuous outcome, two groups, rows taken as independent
;;    contrast    group 1 - group 2
;;    estimate    -1.58   t -1.861   df 17.78   p 0.0794   95% CI -3.37 .. 0.21

;;; 2. Say what the data is: every patient received both drugs.

(defparameter *sleep-sf*
  (as-statframe *sleep*                                           ; [statframe]
                :roles '(:extra :outcome :group :exposure :id :id)
                :structure '(:repeated :by :id :within :group)))

;;; 3. The same verb now dispatches on the declaration.

(compare :outcome :extra :by :group :data *sleep-sf*
         :contrast '("2" "1"))                                    ; [statproc]
;; => procedure   paired-t-test
;;    chosen      structure (:repeated :by :id :within :group)
;;    contrast    group 2 - group 1
;;    estimate    1.58   t 4.062   df 9   p 0.00283   95% CI 0.70 .. 2.46
;;    relies on   differences roughly normal (n = 10)
;;    also fits   wilcoxon-signed-rank  V 45  p 0.0091  (1 zero difference)

(alternatives *)                                                  ; [statproc]
;; => tibble: procedure, relies-on, estimate, p - one row per procedure
;;    that fits the declared structure

;;; 4. A hint without a declaration. With checks switched on, the plain
;;;    tibble is inspected and a possible pairing is reported, not assumed.

(with-statistical-checks (:warn)                                  ; [statproc]
  (compare :outcome :extra :by :group :data *sleep*))
;; => same Welch result as in 1, plus
;;    warning: column ID takes each of its 10 values once in every group;
;;             rows may be paired (within-patient correlation 0.80).
;;             Declare :structure (:repeated :by :id) or (:independent).

;;; 5. The analysis record: what was declared, what ran, what was overridden.

(analysis-record *sleep-sf*)                                      ; [statproc]
;; => tibble: step, verb, declaration-used, checks, overrides, result-id

;;; Hints this example needed:
;;;   :structure (:repeated :by :id :within :group)        -> statframe
;;;   :contrast (which group minus which)                  -> statproc
;;;   "possible pairing" detector for undeclared data      -> statproc check
