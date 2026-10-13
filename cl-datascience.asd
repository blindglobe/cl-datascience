;;;; cl-datascience.asd

(defsystem "cl-datascience"
  :description "Common Lisp Data Science: a DSL for data science practice.
Examples first: textbook analyses, planned by the wouldwork planner from
what is declared about the data and what is asked."
  :author "AJ Rossini, Gwang-Jin Kim"
  :license "MIT"
  :depends-on ("wouldwork")
  :serial t
  :components ((:module "src"
                :components ((:file "package")
                             (:file "planner")
                             (:file "examples"))))
  :in-order-to ((test-op (test-op "cl-datascience/tests"))))

(defsystem "cl-datascience/tests"
  :depends-on ("cl-datascience" "fiveam")
  :serial t
  :components ((:module "tests"
                :components ((:file "package")
                             (:file "planner-tests")
                             (:file "stat101-tests"))))
  :perform (test-op (o c) (symbol-call :cl-datascience/tests :run-all)))
