;;;; src/examples.lisp - the Statistics 101 examples as planning problems
;;;;
;;;; Each example folder examples/stat101/NAME/ has a plan.lisp holding one
;;;; plist:
;;;;   :objects    ((type object ...) ...)       what the data contains
;;;;   :facts      (proposition ...)             known in every case
;;;;   :knowledge  ((name proposition ...) ...)  alternative states of
;;;;               knowledge: what is declared (or observed by a check)
;;;;   :questions  ((name goal) ...)             what can be asked
;;;; The method actions shared by all examples are in
;;;; examples/stat101/domain.lisp.

(in-package #:cl-datascience)

(defun examples-directory ()
  "examples/stat101/ in this checkout."
  (asdf:system-relative-pathname :cl-datascience "examples/stat101/"))

(defun load-example (name)
  "The planning specification of example NAME (examples/stat101/NAME/plan.lisp),
symbols read as keywords."
  (let ((forms (read-forms (merge-pathnames (format nil "~a/plan.lisp" name)
                                            (examples-directory)))))
    (unless (and (= 1 (length forms)) (listp (first forms)))
      (error "~a/plan.lisp must hold exactly one plist" name))
    (first forms)))

(defun example-plans (name knowledge question &key (depth-cutoff 6))
  "Every minimal plan for example NAME when KNOWLEDGE (a keyword naming a
:knowledge entry) holds and QUESTION (a keyword naming a :questions entry)
is asked. See FIND-PLANS."
  (let* ((spec (load-example name))
         (known (assoc knowledge (getf spec :knowledge)))
         (asked (assoc question (getf spec :questions))))
    (unless known
      (error "Example ~a has no knowledge ~s; it has ~{~s~^, ~}."
             name knowledge (mapcar #'first (getf spec :knowledge))))
    (unless asked
      (error "Example ~a has no question ~s; it has ~{~s~^, ~}."
             name question (mapcar #'first (getf spec :questions))))
    (find-plans :objects (getf spec :objects)
                :facts (append (getf spec :facts) (rest known))
                :goal (second asked)
                :domain (merge-pathnames "domain.lisp" (examples-directory))
                :depth-cutoff depth-cutoff)))
