;;;; examples/stat101/03-toothgrowth/wish.lisp
;;;;
;;;; DESIGN SKETCH - does not load yet (see 01-sleep/wish.lisp for the tags);
;;;; the choice of methods already runs in the planner (plan.lisp).
;;;; Numbers in the comments are R's (reference.out, R 4.6.1).

(in-package :tidyverse-user)

(defparameter *tg* (read-csv "examples/stat101/03-toothgrowth/data.csv")) ; [tidyverse]
;; 60 rows: len (odontoblast length), supp ("OJ" or "VC"), dose (0.5, 1, 2)

;;; 1. Plain tibble: both directions "work", exactly as in R.

(fit (model :anova (~ len (* supp (factor dose)))) *tg*)          ; [models]
;; => supp F 15.57 p 2.3e-4 | dose F 92.0 p 4.0e-18 | supp:dose F 4.11 p 0.022

(fit (model :linear (~ dose len)) *tg*)                           ; [models]
;; => slope 0.066 per unit of len, p 1.2e-14  - silently, like lm(dose ~ len)

;;; 2. Declare how each column came about. Partial on purpose: the R
;;;    documentation does not say how animals were assigned to the six
;;;    groups, so that stays undeclared.

(defparameter *tg-sf*
  (as-statframe *tg* :roles '(:len :outcome :supp :exposure :dose :exposure))) ; [statframe]
(declare-design *tg-sf* :supp :set-by-design                      ; [statframe]
                        :dose :set-by-design
                        :len  :observed)
(declare-timing *tg-sf* :supp :assignment :dose :assignment       ; [statframe]
                        :len  :end-of-study)

;;; 3. The impossible direction is now caught.

(fit (model :linear (~ dose len)) *tg-sf* :checks :warn)          ; [models]
;; => warning: dose is :set-by-design and assigned before len was measured;
;;             a model with dose as response reverses the design.
;;    The fit is returned for :purpose :prediction only ("which dose did
;;    this animal get?"); its p-value is marked not meaningful, because
;;    dose values were fixed by the investigator, not sampled.

(check-design-consistency                                          ; [statproc]
  (graph '(:len -> :dose) '(:supp -> :len) '(:dose -> :len))
  *tg-sf*)
;; => tibble of violations:
;;    from  to    rule
;;    len   dose  edge-into-design-variable
;;    len   dose  later-measurement-to-earlier

;;; 4. The verb chooses the designed analysis.

(compare :outcome :len :by '(:supp :dose) :data *tg-sf*)          ; [statproc]
;; => procedure   two-way-anova-with-interaction
;;    chosen      two design factors, balanced (10 animals per cell)
;;    dose        treated as a factor: a straight line in dose does not fit
;;                (lack of fit p 0.00067)
;;    note        assignment of animals to groups not declared: a causal
;;                reading of the supp and dose effects relies on it

;;; Hints this example needed:
;;;   origin (:set-by-design :observed), partial declarations   -> statframe
;;;   timing (:assignment < :end-of-study)                      -> statframe
;;;   design-consistency rules for models and graphs            -> statproc
;;;   "response of a design variable" check inside fit          -> models
