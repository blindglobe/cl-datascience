;;;; tests/stat101-tests.lisp - the Statistics 101 examples
;;;;
;;;; For each example: given what is known (a :knowledge entry of its
;;;; plan.lisp) and what is asked (a :question), these are the plans the
;;;; planner must find. Expected plans are the analyses described in the
;;;; example's README; the numbers they produce are in expected.json.

(in-package #:cl-datascience/tests)

(def-suite stat101 :in :cl-datascience)
(in-suite stat101)

(defmacro plans-for ((example knowledge question) &body expected-plans)
  "Check that EXAMPLE, with KNOWLEDGE, asked QUESTION, gives exactly
EXPECTED-PLANS (compared as sets; see NORMALIZE-PLANS)."
  `(let ((actual (example-plans ,example ,knowledge ,question)))
     (is (plans-equal actual ',expected-plans)
         "~a, knowing ~s, asked ~s:~%  expected ~s~%  got      ~s"
         ,example ,knowledge ,question ',expected-plans actual)))

;;; Example reader

(test load-example-reads-the-specification
  (let ((spec (load-example "00-one-variable")))
    (is (getf spec :objects))
    (is (assoc :plain (getf spec :knowledge)))
    (is (assoc :next-stanza (getf spec :questions)))))

(test unknown-knowledge-or-question-is-an-error
  (signals error (example-plans "00-one-variable" :no-such-knowledge :next-stanza))
  (signals error (example-plans "00-one-variable" :plain :no-such-question)))

;;; 00 one variable (A.J. Rossini, examples/1d-analysis.lisp)

(test one-variable-description-follows-the-type
  (plans-for ("00-one-variable" :plain :describe-stanza)
    ((describe-categorical stanza)))
  (plans-for ("00-one-variable" :plain :describe-pitch)
    ((describe-continuous pitch))))

(test one-variable-next-value-needs-the-data-generating-process
  ;; Nothing known about how the stanzas arose: predicting the next one
  ;; assumes a random process, and the plan says so.
  (plans-for ("00-one-variable" :plain :next-stanza)
    ((assume-random-process stanza) (estimate-category-probabilities stanza)))
  ;; The song's structure is known: the next stanza follows from it.
  (plans-for ("00-one-variable" :pattern-known :next-stanza)
    ((continue-pattern stanza)))
  ;; Declared random: no assumption needed.
  (plans-for ("00-one-variable" :random :next-pitch)
    ((estimate-mean-and-spread pitch)))
  (plans-for ("00-one-variable" :plain :next-pitch)
    ((assume-random-process pitch) (estimate-mean-and-spread pitch))))

(test one-variable-chance-makes-no-sense-for-a-known-pattern
  ;; "it makes much less sense to talk about the chance of a change"
  (plans-for ("00-one-variable" :pattern-known :stanza-probabilities))
  (plans-for ("00-one-variable" :plain :stanza-probabilities)
    ((assume-random-process stanza) (estimate-category-probabilities stanza))))

;;; 01 sleep: two drugs, ten patients

(test sleep-nothing-declared-gives-welch-and-says-what-it-assumes
  ;; R's t.test(extra ~ group): Welch, rows taken as independent.
  (plans-for ("01-sleep" :plain :difference)
    ((assume-rows-independent sleep) (welch-t-test extra group))))

(test sleep-declared-independent-needs-no-assumption
  (plans-for ("01-sleep" :independent :difference)
    ((welch-t-test extra group))))

(test sleep-declared-pairing-gives-the-paired-methods
  ;; Every patient got both drugs: paired t-test, or the signed-rank test
  ;; as the alternative; Welch is no longer possible.
  (plans-for ("01-sleep" :repeated :difference)
    ((paired-t-test extra group id))
    ((signed-rank-test extra group id))))

;;; 02 cars: one regression, three purposes

(test cars-trend-needs-no-assumption
  ;; The slope as an average trend needs neither independence nor
  ;; constant spread.
  (plans-for ("02-cars" :plain :trend)
    ((ols-fit dist speed))))

(test cars-inference-offers-both-standard-errors-with-their-assumptions
  (plans-for ("02-cars" :plain :inference)
    ((assume-rows-independent cars) (ols-fit dist speed) (robust-se cars dist speed))
    ((assume-rows-independent cars) (ols-fit dist speed)
     (assume-constant-spread dist speed) (classical-se cars dist speed)))
  (plans-for ("02-cars" :independent :inference)
    ((ols-fit dist speed) (robust-se cars dist speed))
    ((ols-fit dist speed) (assume-constant-spread dist speed) (classical-se cars dist speed))))

(test cars-after-the-spread-check-only-robust-inference-remains
  ;; A check found the spread growing with speed: the classical standard
  ;; error is no longer a plan.
  (plans-for ("02-cars" :spread-checked :inference)
    ((assume-rows-independent cars) (ols-fit dist speed) (robust-se cars dist speed))))

(test cars-prediction-needs-a-model-of-the-spread
  (plans-for ("02-cars" :plain :prediction)
    ((assume-rows-independent cars) (ols-fit dist speed)
     (assume-constant-spread dist speed) (normal-prediction-interval cars dist speed)))
  (plans-for ("02-cars" :spread-checked :prediction)
    ((assume-rows-independent cars) (ols-fit dist speed)
     (spread-model-prediction-interval cars dist speed))))

;;; 03 ToothGrowth: design variables and the reversed model

(test toothgrowth-nothing-declared-allows-the-reversed-model
  ;; Like R, which runs lm(dose ~ len) without complaint.
  (plans-for ("03-toothgrowth" :plain :dose-from-len)
    ((ols-fit dose len))))

(test toothgrowth-declared-design-forbids-the-reversed-model
  ;; dose was set by the investigator, before len was measured: no plan
  ;; may explain dose by len (a constraint of the domain).
  (plans-for ("03-toothgrowth" :design :dose-from-len)))

(test toothgrowth-prediction-in-the-reversed-direction-stays-allowed
  ;; "Which dose did this animal get?" is a legitimate prediction.
  (plans-for ("03-toothgrowth" :design :predict-dose)
    ((predictive-fit dose len))))

(test toothgrowth-declared-design-gives-the-designed-analysis
  (plans-for ("03-toothgrowth" :design :effects)
    ((two-way-anova toothgrowth len supp dose))))

(test toothgrowth-design-effects-need-a-declared-design
  (plans-for ("03-toothgrowth" :plain :effects)))

;;; 04 UCBAdmissions: counts, and which effect is asked for

(test ucb-counts-must-be-declared-or-the-plan-assumes-one-row-per-applicant
  ;; Nothing declared: 24 rows would be read as 24 applicants - the plan
  ;; says so instead of doing it silently.
  (plans-for ("04-ucb-admissions" :plain :total-effect)
    ((assume-one-row-per-case ucb) (pooled-odds-ratio ucb admit gender)))
  (plans-for ("04-ucb-admissions" :counts :total-effect)
    ((pooled-odds-ratio ucb admit gender))))

(test ucb-direct-effect-needs-the-order-of-events
  ;; Without knowing that the department is chosen between gender and the
  ;; admission decision, "direct effect" has no plan.
  (plans-for ("04-ucb-admissions" :counts :direct-effect)))

(test ucb-direct-effect-stratifies-by-department
  ;; Mantel-Haenszel assumes one common odds ratio across departments;
  ;; the logistic model with a gender-by-department term does not.
  (plans-for ("04-ucb-admissions" :timing :direct-effect)
    ((assume-common-odds-ratio admit gender) (mantel-haenszel ucb admit gender dept))
    ((logistic-by-stratum ucb admit gender dept))))

(test ucb-total-effect-stays-pooled-when-the-timing-is-known
  (plans-for ("04-ucb-admissions" :timing :total-effect)
    ((pooled-odds-ratio ucb admit gender))))
