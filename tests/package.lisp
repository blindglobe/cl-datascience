;;;; tests/package.lisp

(defpackage #:cl-datascience/tests
  (:use #:cl #:fiveam #:cl-datascience)
  (:export #:run-all))

(in-package #:cl-datascience/tests)

(def-suite :cl-datascience :description "All cl-datascience tests.")

(defun run-all ()
  "Run every test; print the report; return T when all passed."
  (let ((results (run :cl-datascience)))
    (explain! results)
    (every (lambda (r) (typep r 'fiveam::test-passed)) results)))
