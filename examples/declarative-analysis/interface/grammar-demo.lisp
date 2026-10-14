;;; Copyright (c) 2026 Gwang Jin Kim. SPDX-License-Identifier: MIT.
;;; Run using run-grammar.py so Wouldwork's working files are isolated.
(in-package :clds-example)

(defparameter *example-study*
  (study :name "Paired enzyme assay" :from :paired-technical-duplicates))

;; Aspect names inspect current configuration and identify missing fields.
(format t "~&Configuration sheet: ~S~%" (configure *example-study* :goal :design))

;; Aspect objects provide an atomic, reproducible specification update.
(configure *example-study*
  (goal :quantity :mean-within-case-difference
        :contrast '(treatment vehicle)
        :claim :population-mean-inference
        :confidence-level 0.95d0)
  (assumptions :independent-cases :declared :normal-differences :unknown))

(check *example-study* :data :design)
(propose *example-study* :analysis)

;; Selection is explicit. It does not accept unknown assumptions or run a test.
(approve *example-study* :analysis-plan :proposal :paired-t
         :by :demo-author :note "Select this route for further qualification.")
(format t "~&~A~%" (report *example-study*))

;; A specification change invalidates the old selection and its proposal set.
(configure *example-study* (goal :confidence-level 0.90d0))
(format t "~&After changing confidence level: revision ~D, previous approval statuses ~S.~%"
        (revision *example-study*)
        (mapcar (lambda (approval) (getf approval :status)) (approvals *example-study*)))
(propose *example-study* :analysis)
(format t "~&Updated proposals: ~S~%" (mapcar (lambda (p) (getf p :id))
                                            (proposals *example-study*)))
