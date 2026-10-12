;;; Copyright (c) 2026 Gwang Jin Kim. SPDX-License-Identifier: MIT.
(defpackage :clds-example
  (:nicknames :clds-demo)
  (:use :cl)
  (:export #:study #:dataset #:goal #:design #:measurements #:assumptions
           #:configure #:configuration-sheet #:check #:propose #:approve #:report
           #:revision #:proposals #:approvals #:history #:dataset-table
           #:demo #:*wouldwork-source* #:*quicklisp-setup*
           #:*planner-sbcl* #:*planner-python* #:*example-study*))
