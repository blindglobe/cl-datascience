;;; Copyright (c) 2026 Gwang Jin Kim. SPDX-License-Identifier: MIT.
(in-package :clds-example)

#-sbcl (error "This example's isolated planner requires SBCL.")
(defparameter *planner-sbcl* (namestring sb-ext:*runtime-pathname*)
  "Use the same SBCL executable as the caller; may be overridden explicitly.")
(defparameter *planner-python* "python3")
(defparameter *wouldwork-source* nil
  "Optional explicit source override. NIL locates Wouldwork through ASDF.")

(defun wouldwork-source-directory ()
  "Locate the source through ASDF without evaluating Wouldwork's .asd initializer."
  (let* ((definition (if *wouldwork-source*
                         (merge-pathnames "wouldwork.asd"
                                          (uiop:ensure-directory-pathname *wouldwork-source*))
                         (nth-value 2 (asdf:locate-system "wouldwork"))))
         (found (and definition (probe-file definition))))
    (unless found
      (error "ASDF cannot locate Wouldwork. Register its source directory with ASDF or run the example's setup script."))
    (uiop:pathname-directory-pathname found)))

(defun worker-source-directories ()
  "Resolve all transitive library sources using ASDF's dependency plan, without loading them."
  (remove-duplicates
   (loop for system in (asdf:required-components "declarative-analysis/worker-dependencies"
                         :other-systems t :keep-component 'asdf:system)
         for file = (asdf:system-source-file system)
         when file collect (uiop:pathname-directory-pathname (truename file)))
   :test #'equal))

(defun worker-arguments ()
  "Pass resolved ASDF source directories to a clean SBCL worker as data."
  (append (list "--wouldwork" (namestring (wouldwork-source-directory))
                "--sbcl" *planner-sbcl*)
          (loop for directory in (worker-source-directories)
                append (list "--source-directory" (namestring directory)))))

(defun emit-worker-arguments ()
  "Private standalone-runner discovery protocol; POSIX pathnames cannot contain NUL."
  (let ((arguments (worker-arguments)))
    (format t "~&CLDS-WORKER-ARGV~%")
    (dolist (argument arguments) (write-string argument) (write-char #\Null))
    (write-string "CLDS-WORKER-ARGV-END") (write-char #\Null)))
