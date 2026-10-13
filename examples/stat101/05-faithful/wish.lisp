;;;; examples/stat101/05-faithful/wish.lisp
;;;;
;;;; DESIGN SKETCH - does not load yet (see 01-sleep/wish.lisp for the tags);
;;;; the choice of methods already runs in the planner (plan.lisp).
;;;; Numbers in the comments are R's (reference.out, R 4.6.1).

(in-package :tidyverse-user)

(defparameter *faithful* (read-csv "examples/stat101/05-faithful/data.csv")) ; [tidyverse]
;; 272 rows: eruptions (minutes), waiting (minutes to the next eruption)

;;; 1. Plain tibble: the usual summary, as summary() and sd() give it.

(describe *faithful*)                                              ; [stats]
;; => eruptions  mean 3.49  sd 1.14  min 1.6  max 5.1
;;    waiting    mean 70.9  sd 13.6  min 43   max 96

;;; 2. With checks, describe looks at the shape before trusting the mean.

(describe *faithful* :checks :warn)                                ; [stats]
;; => warning: eruptions has two modes (1.98 and 4.37 minutes); only 13.6%
;;             of eruptions lie within half a minute of the mean 3.49.
;;             The mean is not a typical value here.
;;    suggestion: (describe *faithful* :by (split-at :eruptions 3))
;;      short (36%) mean 2.04 | long (64%) mean 4.29

;;; 3. A strong correlation that is mostly between the two clusters.

(compare :outcome :waiting :by :eruptions :data *faithful*
         :checks :warn)                                            ; [statproc]
;; => procedure  linear-trend / correlation
;;    r 0.90, slope 10.7 minutes of waiting per minute of eruption
;;    warning: within the two clusters r is 0.29 (short) and 0.37 (long);
;;             the overall r mostly measures the gap between clusters

;;; 4. Row order. R's documentation does not say whether rows are in time
;;;    order, but lag-1 autocorrelation is -0.55 (short and long eruptions
;;;    alternate). Recording what is known - and that it is unknown -
;;;    is itself a declaration.

(defparameter *faithful-sf*
  (as-statframe *faithful* :row-order :unknown))                   ; [statframe]

(with-statistical-checks (:warn)
  (fit (model :linear (~ waiting eruptions)) *faithful-sf*
       :purpose :inference))                                        ; [models]
;; => warning: row order :unknown, but lag-1 autocorrelation of eruptions
;;             is -0.55: if rows are consecutive eruptions they are not
;;             independent and standard errors are wrong.
;;             Declare :row-order :time (then a time-series model is
;;             suggested) or :row-order :arbitrary to silence.

;;; 5. If clusters are found by a random algorithm, the result records
;;;    the seed and versions so it can be reproduced.

(describe *faithful* :by (cluster :eruptions :k 2 :method :kmeans :seed 42)) ; [stats]
;; => ... plus reproduction envelope: seed 42, RNG, package versions

;;; Hints this example needed:
;;;   shape checks (modes) inside describe                       -> stats
;;;   between- vs within-group correlation check                 -> statproc
;;;   :row-order (:time :arbitrary :unknown) as frame metadata   -> statframe
;;;   seeds and versions travel with random results             -> stats
