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
;;;; - Actions with several parameters use the product header
;;;;   ((product ?y variable ?g variable)). Wouldwork's default (standard)
;;;;   instantiates same-type parameters with distinct objects and fails
;;;;   ("too few elements ... to satisfy lambda list") when an example has
;;;;   fewer objects than parameters (wouldwork 2026-01: an empty
;;;;   instantiation becomes a list of empty argument lists). Preconditions
;;;;   keep the roles apart, with (not (eql ?a ?b)) where roles could
;;;;   coincide.
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
  (two-levels variable)
  (binary variable)
  ;; how the rows relate
  (rows-independent frame)
  (repeated-by> frame variable variable)   ; (repeated-by> f id within): each id seen under every level of within
  (frequency-weights frame variable)       ; one row per cell, the variable counts cases
  (one-row-per-case frame)
  ;; how a variable came about, and when it was measured
  (set-by-design variable)                 ; chosen by the investigator
  (randomized variable)                    ; assigned by a random mechanism
  (observed variable)                      ; arose from the process studied
  (measured-before> variable variable)
  ;; spread of y around its trend in x (declared, or observed by a check)
  (constant-spread> variable variable)
  (nonconstant-spread> variable variable)
  ;; how the values came about
  (random-process variable)
  (known-pattern variable)
  ;; answers
  (described variable)
  (predicted-next variable)
  (estimated-probabilities variable)
  (estimated-difference> variable variable) ; (estimated-difference> outcome groups)
  (estimated-trend> variable variable)      ; (estimated-trend> y x): average linear trend
  (inferred-trend> variable variable)       ; ... with standard error, test, interval
  (prediction-interval> variable variable)  ; ... interval for a new y at given x
  (explained-by-design> variable variable)  ; effect of a design factor on an outcome
  (predicted-from> variable variable)       ; prediction only, no causal reading
  (estimated-total-effect> variable variable)
  (estimated-direct-effect> variable variable) ; effect not passing through a later variable
  (common-odds-ratio> variable variable)    ; the same odds ratio in every stratum
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

;;; Two groups: compare an outcome

(define-action welch-t-test 1                  ; R's t.test(y ~ g)
  (product ?f frame ?y variable ?g variable)
  (and (continuous ?y) (two-levels ?g) (rows-independent ?f)
       (not (estimated-difference> ?y ?g)))
  (?y ?g)
  (assert (estimated-difference> ?y ?g) (used welch-t-test)))

(define-action paired-t-test 1
  (product ?f frame ?y variable ?g variable ?id variable)
  (and (continuous ?y) (two-levels ?g) (repeated-by> ?f ?id ?g)
       (not (estimated-difference> ?y ?g)))
  (?y ?g ?id)
  (assert (estimated-difference> ?y ?g) (used paired-t-test)))

(define-action signed-rank-test 1              ; Wilcoxon, paired
  (product ?f frame ?y variable ?g variable ?id variable)
  (and (continuous ?y) (two-levels ?g) (repeated-by> ?f ?id ?g)
       (not (estimated-difference> ?y ?g)))
  (?y ?g ?id)
  (assert (estimated-difference> ?y ?g) (used signed-rank-test)))

;;; Design consistency (A.J. Rossini's clinical-trial example: a network
;;; analysis concluded that the outcome influenced the randomized
;;; treatment). No state may contain an explanation of a variable that was
;;; set by design or randomized, or of a variable by one measured after it.
;;; Prediction (predicted-from>) is not an explanation and stays allowed.

(define-constraint
  (not (exists ((?y ?x) variable)
         (and (estimated-trend> ?y ?x)
              (or (set-by-design ?y)
                  (randomized ?y)
                  (measured-before> ?y ?x))))))

;;; Designed experiments

(define-action two-way-anova 1                 ; aov(y ~ a * b), factors as designed
  (product ?f frame ?y variable ?a variable ?b variable)
  (and (continuous ?y) (not (set-by-design ?y))
       (set-by-design ?a) (set-by-design ?b) (not (eql ?a ?b))
       (rows-independent ?f)
       (not (explained-by-design> ?y ?a)))
  (?f ?y ?a ?b)
  (assert (explained-by-design> ?y ?a) (explained-by-design> ?y ?b)
          (used two-way-anova)))

(define-action predictive-fit 1                ; a prediction model; no causal reading
  (product ?y variable ?x variable)
  (and (continuous ?y) (continuous ?x) (not (eql ?y ?x))
       (not (predicted-from> ?y ?x)))
  (?y ?x)
  (assert (predicted-from> ?y ?x) (used predictive-fit)))

;;; Binary outcome, two groups: which effect is asked for. A total effect
;;; includes paths through later variables; a direct effect holds a
;;; variable fixed that lies between exposure and outcome in time.

(define-action pooled-odds-ratio 1             ; 2x2 table over everything
  (product ?f frame ?y variable ?x variable)
  (and (binary ?y) (two-levels ?x)
       (or (one-row-per-case ?f) (exists (?w variable) (frequency-weights ?f ?w)))
       (not (estimated-total-effect> ?y ?x)))
  (?f ?y ?x)
  (assert (estimated-total-effect> ?y ?x) (used pooled-odds-ratio)))

(define-action mantel-haenszel 1               ; mantelhaen.test: one common odds ratio
  (product ?f frame ?y variable ?x variable ?z variable)
  (and (binary ?y) (two-levels ?x) (categorical ?z)
       (measured-before> ?x ?z) (measured-before> ?z ?y)
       (common-odds-ratio> ?y ?x)
       (or (one-row-per-case ?f) (exists (?w variable) (frequency-weights ?f ?w)))
       (not (estimated-direct-effect> ?y ?x)))
  (?f ?y ?x ?z)
  (assert (estimated-direct-effect> ?y ?x) (used mantel-haenszel)))

(define-action logistic-by-stratum 1           ; glm(y ~ x * z): an effect per stratum
  (product ?f frame ?y variable ?x variable ?z variable)
  (and (binary ?y) (two-levels ?x) (categorical ?z)
       (measured-before> ?x ?z) (measured-before> ?z ?y)
       (or (one-row-per-case ?f) (exists (?w variable) (frequency-weights ?f ?w)))
       (not (estimated-direct-effect> ?y ?x)))
  (?f ?y ?x ?z)
  (assert (estimated-direct-effect> ?y ?x) (used logistic-by-stratum)))

(define-action assume-common-odds-ratio 1
  (product ?y variable ?x variable)
  (and (binary ?y) (two-levels ?x) (not (common-odds-ratio> ?y ?x)))
  (?y ?x)
  (assert (common-odds-ratio> ?y ?x) (used assume-common-odds-ratio)))

(define-action assume-one-row-per-case 1       ; R's default for a data frame
  (?f frame)
  (and (not (one-row-per-case ?f))
       (not (exists (?w variable) (frequency-weights ?f ?w))))
  (?f)
  (assert (one-row-per-case ?f) (used assume-one-row-per-case)))

;;; Regression: one fit, three purposes. What each output needs:
;;; trend - nothing beyond the fit; inference - independent rows, and
;;; constant spread for the classical standard error; prediction -
;;; independent rows and a model of the spread.

(define-action ols-fit 1                       ; R's lm(y ~ x)
  (product ?y variable ?x variable)
  (and (continuous ?y) (continuous ?x) (not (eql ?y ?x))
       (not (estimated-trend> ?y ?x)))
  (?y ?x)
  (assert (estimated-trend> ?y ?x) (used ols-fit)))

(define-action classical-se 1                  ; summary(lm): needs constant spread
  (product ?f frame ?y variable ?x variable)
  (and (estimated-trend> ?y ?x) (rows-independent ?f) (constant-spread> ?y ?x)
       (not (inferred-trend> ?y ?x)))
  (?f ?y ?x)
  (assert (inferred-trend> ?y ?x) (used classical-se)))

(define-action robust-se 1                     ; heteroscedasticity-consistent (HC3)
  (product ?f frame ?y variable ?x variable)
  (and (estimated-trend> ?y ?x) (rows-independent ?f)
       (not (inferred-trend> ?y ?x)))
  (?f ?y ?x)
  (assert (inferred-trend> ?y ?x) (used robust-se)))

(define-action normal-prediction-interval 1    ; predict(..., interval = "prediction")
  (product ?f frame ?y variable ?x variable)
  (and (estimated-trend> ?y ?x) (rows-independent ?f) (constant-spread> ?y ?x)
       (not (prediction-interval> ?y ?x)))
  (?f ?y ?x)
  (assert (prediction-interval> ?y ?x) (used normal-prediction-interval)))

(define-action spread-model-prediction-interval 1   ; spread modelled as a function of x
  (product ?f frame ?y variable ?x variable)
  (and (estimated-trend> ?y ?x) (rows-independent ?f) (nonconstant-spread> ?y ?x)
       (not (prediction-interval> ?y ?x)))
  (?f ?y ?x)
  (assert (prediction-interval> ?y ?x) (used spread-model-prediction-interval)))

(define-action assume-constant-spread 1
  (product ?y variable ?x variable)
  (and (estimated-trend> ?y ?x)
       (not (constant-spread> ?y ?x)) (not (nonconstant-spread> ?y ?x)))
  (?y ?x)
  (assert (constant-spread> ?y ?x) (used assume-constant-spread)))

;;; Assumptions about how rows relate

(define-action assume-rows-independent 1       ; R's silent default
  (?f frame)
  (and (not (rows-independent ?f))
       (not (exists ((?a ?b) variable) (repeated-by> ?f ?a ?b))))
  (?f)
  (assert (rows-independent ?f) (used assume-rows-independent)))
