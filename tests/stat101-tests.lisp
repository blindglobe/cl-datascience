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
