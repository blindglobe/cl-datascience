;;; Copyright (c) 2026 Gwang Jin Kim. SPDX-License-Identifier: MIT.
(in-package :clds-example)

(defparameter *wouldwork-source*
  (merge-pathnames "projects/cl/wouldwork/" (user-homedir-pathname))
  "Existing Wouldwork source checkout, copied for each proposal request.")
(defparameter *quicklisp-setup*
  (merge-pathnames "quicklisp/setup.lisp" (user-homedir-pathname)))
(defparameter *planner-sbcl* "sbcl")
(defparameter *planner-python* "python3")

(defun wire-value (value)
  "Portable data-only transport; symbolic labels use the grammar's name semantics."
  (typecase value
    (null nil)
    (symbol (if (eq value t) t (intern (symbol-name value) :keyword)))
    (cons (cons (wire-value (car value)) (wire-value (cdr value))))
    (string (copy-seq value))
    (array (let ((copy (make-array (array-dimensions value))))
             (dotimes (i (array-total-size value) copy)
               (setf (row-major-aref copy i) (wire-value (row-major-aref value i))))))
    (number value)
    (t (error "Unsupported planner data value: ~S" (type-of value)))))

(defun read-message (path)
  "Read exactly one versioned data form, with reader evaluation disabled."
  (with-open-file (in path)
    (let* ((*read-eval* nil) (*package* (find-package :clds-example))
           (message (read in nil :eof)))
      (unless (and (listp message) (eql 1 (getf message :schema-version))
                   (eq :eof (read in nil :eof)))
        (error "Invalid planner message."))
      message)))

(defun write-message (value path)
  (with-open-file (out path :direction :output :if-exists :supersede)
    (let ((*print-readably* t) (*print-pretty* nil))
      (write (wire-value value) :stream out) (terpri out))))

(defun planner-request (object)
  (let ((data (study-data object)))
    (list :schema-version 1 :name (study-name object)
          :table (%table data) :columns (columns data) :variables (variables data)
          :row-labels (row-labels data) :metadata (source-metadata data)
          :aspects (aspects object) :revision (revision object)
          :generation (generation object))))

(defun propose-via-worker (object)
  "Synchronous worker request. Commit returned state only after worker success."
  (uiop:with-temporary-file (:pathname request :prefix "clds-request-" :type "sexp")
    (uiop:with-temporary-file (:pathname result :prefix "clds-result-" :type "sexp")
      (write-message (planner-request object) request)
      (multiple-value-bind (output errors status)
          (uiop:run-program
           (list *planner-python*
                 (namestring (asdf:system-relative-pathname "declarative-analysis" "run-grammar.py"))
                 "--request" (namestring request) "--result" (namestring result)
                 "--wouldwork" (namestring (pathname *wouldwork-source*))
                 "--quicklisp" (namestring (pathname *quicklisp-setup*))
                 "--sbcl" *planner-sbcl*)
           :output :string :error-output :output :ignore-error-status t)
        (declare (ignore errors))
        (unless (eql status 0)
          (error "Isolated planner failed; study state was preserved.~%~A" output)))
      (let ((message (read-message result)))
        (unless (and (eql (revision object) (getf message :revision))
                     (eql (1+ (generation object)) (getf message :generation))
                     (listp (getf message :proposals))
                     (listp (getf message :check)))
          (error "Planner response does not match the requested study."))
        (setf (current-check object) (getf message :check)
              (%proposals object) (getf message :proposals)
              (generation object) (getf message :generation))
        (dolist (approval (%approvals object))
          (when (eq (getf approval :aspect) :analysis-plan)
            (setf (getf approval :status) :stale)))
        (record-event object :proposed
                      (mapcar (lambda (p) (getf p :id)) (%proposals object))))))
  object)

(defun run-planner-request (request result)
  "Worker entry point; only called after the isolated Wouldwork runtime is loaded."
  (let* ((message (read-message request))
         (object (study :name (getf message :name)
                        :data (dataset (getf message :table) :columns (getf message :columns)
                                       :variables (getf message :variables)
                                       :row-labels (getf message :row-labels)
                                       :metadata (getf message :metadata)))))
    (apply #'configure object
           (mapcar (lambda (entry) (make-aspect (car entry) (cdr entry)))
                   (getf message :aspects)))
    (setf (%revision object) (getf message :revision)
          (generation object) (getf message :generation))
    (propose object :analysis)
    (write-message (list :schema-version 1 :revision (revision object)
                         :generation (generation object) :check (current-check object)
                         :proposals (proposals object)) result)))
