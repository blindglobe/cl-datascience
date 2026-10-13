;;;; examples/stat101/02-cars/wish.lisp
;;;;
;;;; DESIGN SKETCH - does not load yet (see 01-sleep/wish.lisp for the tags);
;;;; the choice of methods already runs in the planner (plan.lisp).
;;;; Numbers in the comments are R's (reference.out, R 4.6.1).

(in-package :tidyverse-user)

(defparameter *cars* (read-csv "examples/stat101/02-cars/data.csv")) ; [tidyverse]
;; 50 rows: speed (mph), dist (stopping distance, ft)

;;; 1. Plain tibble: identical to lm(dist ~ speed), no warnings.

(defparameter *fit* (fit (model :linear (~ dist speed)) *cars*))  ; [models]
(tidy *fit*)                                                       ; [broom]
;; => term        estimate   std-error   p
;;    intercept   -17.58      6.758      0.0123
;;    speed         3.932     0.4155     1.49e-12      R^2 0.651

;;; 2. Declare units, the value domain, and what physics says.

(defparameter *cars-sf*
  (as-statframe *cars*                                             ; [statframe]
                :roles  '(:dist :outcome :speed :predictor)
                :units  '(:dist "ft" :speed "mph")
                :domain '(:dist (:>= 0))))
(declare-model-hint *cars-sf* :dist                                ; [statframe]
                    '(:grows-like (expt speed 2))
                    :source "kinetic energy: braking distance ~ speed^2")

;;; 3. Purpose :trend - "how much longer per mph, on average?"
;;;    The slope as an average linear trend needs no variance assumption.

(fit (model :linear (~ dist speed)) *cars-sf*
     :purpose :trend :checks :warn)                                ; [models]
;; => slope 3.93 ft per mph over speeds 4..25 mph
;;    no warnings
;;    std-error, p and intervals are shown, marked
;;    "not checked: not needed for purpose :trend"

;;; 4. Purpose :inference - "is the slope different from zero, how sure?"

(fit (model :linear (~ dist speed)) *cars-sf*
     :purpose :inference :checks :warn)                            ; [models]
;; => warning (suggestive): residual SD grows with speed
;;      4-12 mph 8.6 ft, 13-18 mph 17.2 ft, 19-25 mph 18.1 ft
;;      Breusch-Pagan p 0.073
;;    alternative: robust (HC3) std-error 0.4275, CI 3.07 .. 4.79
;;      (classical 0.4155, CI 3.10 .. 4.77): the conclusion does not change

;;; 5. Purpose :prediction - "how far does a car at 5 mph need?"

(predict *fit* (tibble :speed '(5 25)) :interval :prediction
         :purpose :prediction :checks :warn :data *cars-sf*)        ; [models]
;; => speed 5:  fit 2.1   interval -30.3 .. 34.5
;;    speed 25: fit 80.7  interval  48.5 .. 113.0
;;    warning: lower limit -30.3 ft violates the declared domain dist >= 0
;;    warning: the interval assumes constant spread; the spread is about
;;             half as large at low speed and larger at high speed
;;    note:    declared hint dist ~ speed^2 - quadratic term p 0.136:
;;             the data neither confirm nor contradict it

;;; Hints this example needed:
;;;   :purpose (:trend :inference :prediction), per-output validity -> models
;;;   :units, :domain (value range of a variable)                  -> statframe
;;;   model hint from subject knowledge (:grows-like ...)           -> statframe
;;;   graded warnings (suggestive vs clear)                         -> checks
