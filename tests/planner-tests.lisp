;;;; tests/planner-tests.lisp - the bridge to the wouldwork planner

(in-package #:cl-datascience/tests)

(def-suite planner :in :cl-datascience)
(in-suite planner)

(test wouldwork-is-loaded
  (is (find-package :ww)))
