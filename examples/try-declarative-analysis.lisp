;;; Copyright (c) 2026 Gwang Jin Kim. SPDX-License-Identifier: MIT.
;;; In a Lisp REPL: (load "examples/try-declarative-analysis.lisp")
;;; Then: (clds-demo:configure clds-demo:*example-study* :goal :design)
;;;       (clds-demo:propose clds-demo:*example-study* :analysis)
;;;       (format t "~A" (clds-demo:report clds-demo:*example-study*))
;;; Tests: (asdf:test-system "declarative-analysis")
;;; Loading creates a synthetic study; it does not start a planner.
(require :asdf)
(load (merge-pathnames "declarative-analysis/load.lisp"
                       (uiop:pathname-directory-pathname *load-truename*)))
(setf clds-demo:*example-study* (clds-demo:demo))
