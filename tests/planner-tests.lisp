;;;; tests/planner-tests.lisp - the bridge to the wouldwork planner

(in-package #:cl-datascience/tests)

(def-suite planner :in :cl-datascience)
(in-suite planner)

(defun toy-domain ()
  (asdf:system-relative-pathname :cl-datascience/tests "tests/toy-domain.lisp"))

(defun normalize-plans (plans)
  "PLANS as a sorted list of sorted step lists: plans are compared as sets
of plans, each a set of steps (wouldwork's step order among independent
steps is not part of the contract)."
  (flet ((key (x) (prin1-to-string x)))
    (sort (mapcar (lambda (plan) (sort (copy-list (keywordize plan)) #'string< :key #'key))
                  plans)
          #'string< :key #'key)))

(defun plans-equal (actual expected)
  (equal (normalize-plans actual) (normalize-plans expected)))

(defun toy-plans (&rest facts)
  (find-plans :objects '((item potato)) :facts facts :goal '(cooked potato)
              :domain (toy-domain)))

(test wouldwork-is-loaded
  (is (find-package :ww)))

(test keywordize-turns-symbols-into-keywords
  (is (equal '(:cook :potato 1 "x") (keywordize '(cook potato 1 "x"))))
  (is (equal '((:a (:b))) (keywordize '((a (b)))))))

(test every-minimal-plan-is-returned
  (let ((plans (toy-plans '(raw potato))))
    (is (plans-equal plans '(((wash potato) (boil potato))
                             ((wash potato) (fry potato))
                             ((assume-clean potato) (boil potato))
                             ((assume-clean potato) (fry potato))))
        "got ~s" plans)))

(test plans-are-keyword-lists-shortest-first
  (let ((plans (toy-plans '(raw potato) '(washed potato))))
    (is (plans-equal plans '(((boil potato)) ((fry potato)))) "got ~s" plans)
    (is (every (lambda (plan) (every (lambda (step) (every #'keywordp step)) plan))
               plans))))

(test unneeded-steps-are-dropped
  ;; (peel potato) is always possible; plans that add it are not minimal.
  (is (notany (lambda (plan) (find :peel plan :key #'first))
              (toy-plans '(raw potato)))))

(test a-known-fact-blocks-an-assumption
  (let ((plans (toy-plans '(raw potato) '(dirty potato))))
    (is (plans-equal plans '(((wash potato) (boil potato))
                             ((wash potato) (fry potato))))
        "got ~s" plans)))

(test consecutive-calls-are-independent
  ;; Regression: staging reloads wouldwork, which forgets extra problem
  ;; folders; a second call must not silently re-solve the first problem.
  (let ((first (toy-plans '(raw potato) '(washed potato)))
        (second (toy-plans '(raw potato) '(dirty potato))))
    (is (not (plans-equal first second)))))

(test planning-leaves-the-callers-package-alone
  ;; Regression: staging reloads wouldwork, which changed *PACKAGE*; forms
  ;; read after a call (a script, the REPL) were then read in wouldwork's
  ;; package.
  (let ((*package* (find-package :cl-datascience/tests)))
    (toy-plans '(raw potato))
    (is (eq (find-package :cl-datascience/tests) *package*))))

(test unreachable-goal-gives-no-plans
  (is (null (find-plans :objects '((item potato)) :facts '((dirty potato))
                        :goal '(cooked potato) :domain (toy-domain)))))

(test plan-assumptions-are-the-assume-steps
  (is (equal '((:assume-clean :potato))
             (plan-assumptions '((:assume-clean :potato) (:boil :potato))))))

(test a-broken-domain-signals-planning-error
  (let ((file (uiop:with-temporary-file (:stream s :pathname p :keep t :type "lisp")
                (write-string "(define-dynamic-relations (cooked item) (used method))
(define-action burn 1 (?i item) (no-such-relation ?i) (?i) (assert (cooked ?i)))" s)
                p)))
    (unwind-protect
         (signals planning-error
           (find-plans :objects '((item potato)) :facts '() :goal '(cooked potato)
                       :domain file))
      (delete-file file))
    ;; Regression: wouldwork compiles its staged problem every time it is
    ;; loaded, so a failed stage must not stay staged.
    (is (string-equal "blocks3" (symbol-name ww::*problem-name*)))
    (is (search "blocks3" (uiop:read-file-string
                           (asdf:system-relative-pathname :wouldwork "src/problem.lisp"))))))
