;;; Copyright (c) 2026 Gwang Jin Kim. SPDX-License-Identifier: MIT.
(in-package :clds-example)

(defvar *example-study* nil)

(defun demo (&key (fixture :paired-technical-duplicates) (name "Enzyme assay"))
  "Return a fresh configured synthetic study. Does not launch a planner."
  (let ((object (study :name name :from fixture)))
    (configure object
      (goal :quantity (if (eq fixture :independent-cultures)
                          :difference-in-population-means :mean-within-case-difference)
            :contrast '(:treatment :vehicle) :claim :population-mean-inference
            :confidence-level 0.95d0))
    object))
