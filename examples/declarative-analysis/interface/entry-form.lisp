;;; Copyright (c) 2026 Gwang Jin Kim. SPDX-License-Identifier: MIT.
;;; This file records Tony's reference interface; it does not implement those verbs.
;;; Our own executable grammar is in grammar-demo.lisp and ../GRAMMAR.md.
;;; Loading it only defines the quoted expression and conceptual return contracts.

(in-package :cl-user)

(defparameter *declarative-analysis-entry-form*
  '(publish :journal '(JASA Biometrics)
     (report
       (analyse
         (data-quality-check
           (source data-source)
           (plan 'specs 'resources))))))

(defparameter *declarative-analysis-return-contracts*
  '((source . source-data)
    (plan . specification-resource-plan)
    (data-quality-check . checked-study-with-data-and-plan)
    (analyse . proposal-collection-or-executed-analysis)
    (report . report-content)
    (publish . publication-receipt)))

;;; SPECS selects a goal from fixtures/goals.sexp, the study context, and an
;;; execution mode. RESOURCES declares backend availability and qualification.
;;; SOURCE returns data and metadata, not vectors stripped of statistical meaning.
;;; ANALYSE derives applicability and requests Wouldwork routes behind this API.
;;; In proposal-only mode no statistical computation or publication occurs.
;;; The first PUBLISH adapter will write locally; journal submission is separate.
