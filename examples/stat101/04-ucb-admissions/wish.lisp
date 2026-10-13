;;;; examples/stat101/04-ucb-admissions/wish.lisp
;;;;
;;;; DESIGN SKETCH - does not load yet (see 01-sleep/wish.lisp for the tags);
;;;; the choice of methods already runs in the planner (plan.lisp).
;;;; Numbers in the comments are R's (reference.out, R 4.6.1).

(in-package :tidyverse-user)

(defparameter *ucb* (read-csv "examples/stat101/04-ucb-admissions/data.csv")) ; [tidyverse]
;; 24 rows, one per cell: Admit, Gender, Dept, Freq (4526 applicants)

;;; 1. Plain tibble. The counts must be named; otherwise 24 rows are
;;;    analysed instead of 4526 applicants.

(compare :outcome :admit :by :gender :data *ucb* :weights :freq)  ; [statproc]
;; => admitted  Male 44.5%  Female 30.4%
;;    odds ratio (male vs female) 1.84   chi-square p 1.1e-21

;;; 2. Declare roles, the count column, and the order of events.
;;;    Nothing here was randomized: all columns are :observed.

(defparameter *ucb-sf*
  (as-statframe *ucb*                                              ; [statframe]
                :roles '(:admit :outcome :gender :exposure
                         :dept :covariate :freq :frequency-weight)))
(declare-design *ucb-sf* :gender :observed :dept :observed :admit :observed)
(declare-timing *ucb-sf* :gender :before-application               ; [statframe]
                         :dept   :application
                         :admit  :decision)

;;; 3. The question decides the answer. Dept lies between gender and
;;;    admission in time, so "the effect of gender" has two meanings.

(compare :outcome :admit :by :gender :data *ucb-sf*
         :estimand :total)                                         ; [statproc]
;; => odds ratio 1.84 - includes the path gender -> choice of dept -> admit
;;    note: women applied mostly to departments that admit few applicants
;;          (C: 65% women, 35% admitted; A: 12% women, 64% admitted)

(compare :outcome :admit :by :gender :data *ucb-sf*
         :estimand :direct)                                        ; [statproc]
;; => procedure  mantel-haenszel, stratified by dept
;;               (chosen: dept is declared between gender and admit)
;;    odds ratio (male vs female) 0.905   p 0.23
;;    women admitted more often in 4 of 6 departments
;;    warning: the gender effect differs between departments
;;             (interaction p 0.0011; dept A: women 2.9 times the odds):
;;             one common odds ratio summarises it poorly
;;    note:    observational data - applicants' qualifications are not
;;             in the data; "direct" means "within department" only

;;; 4. Without :estimand, checks report the reversal instead of choosing.

(with-statistical-checks (:warn)
  (compare :outcome :admit :by :gender :data *ucb-sf*))            ; [statproc]
;; => the total-effect result, plus
;;    warning: the association reverses within dept (a declared covariate
;;             measured between exposure and outcome): Simpson's paradox.
;;             State :estimand :total or :direct.

;;; Hints this example needed:
;;;   :frequency-weight role (data given as counts)              -> statframe
;;;   timing used to place a covariate between exposure/outcome  -> statframe
;;;   :estimand (:total :direct) - the question, not the data    -> statproc
;;;   reversal (Simpson) check, effect-heterogeneity check       -> statproc
