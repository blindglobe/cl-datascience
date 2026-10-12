;;; Copyright (c) 2026 Gwang Jin Kim. SPDX-License-Identifier: MIT.
(asdf:defsystem "declarative-analysis"
  :description "Experimental study grammar with isolated Wouldwork proposals"
  :version "0.3.0" :license "MIT" :depends-on ("uiop") :serial t
  :in-order-to ((asdf:test-op (asdf:test-op "declarative-analysis/tests")))
  :components ((:file "src/package") (:file "src/grammar")
               (:file "src/fixtures") (:file "src/demo")
               (:file "src/planner-process") (:file "src/wouldwork-adapter")))

(asdf:defsystem "declarative-analysis/tests"
  :description "Grammar, real planner, and REPL isolation checks"
  :depends-on ("declarative-analysis") :serial t
  :components ((:file "tests/package-checks"))
  :perform (asdf:test-op (operation system)
             (declare (ignore operation system))
             (uiop:symbol-call :clds-example :run-package-checks)))
