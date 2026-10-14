;;; Copyright (c) 2026 Gwang Jin Kim. SPDX-License-Identifier: MIT.
(in-package :clds-example)

(defun read-fixture (relative)
  (let ((*read-eval* nil) (*package* (find-package :clds-example)))
    (with-open-file (in (asdf:system-relative-pathname "declarative-analysis" relative))
      (let ((form (read in nil :eof)))
        (unless (and (listp form) (eql (getf form :schema-version) 0)
                     (eq (read in nil :eof) :eof))
          (error "Unsupported or malformed fixture: ~A" relative))
        form))))

(defun replace-at-path (plist path value)
  "Fixture overlays replace named paths; inherited entries remain unchanged."
  (if (null (cdr path))
      (setf (getf plist (car path)) (snapshot value))
      (setf (getf plist (car path))
            (replace-at-path (getf plist (car path)) (cdr path) value)))
  plist)

(defun resolve-study-fixture (id records &optional visited)
  (when (member id visited) (error "Cyclic fixture inheritance: ~S" id))
  (let* ((record (or (find id records :key (lambda (r) (getf r :id)))
                     (error "Unknown study fixture: ~S" id)))
         (base (if (getf record :extends)
                   (resolve-study-fixture (getf record :extends) records (cons id visited))
                   (snapshot record))))
    (dolist (replacement (getf record :replace))
      (setf base (replace-at-path base (getf replacement :path) (getf replacement :value))))
    (setf (getf base :id) id)
    base))

(defun study (&key (name "Laboratory analysis") data from)
  "Create a study from a dataset object or one of the synthetic lab fixtures."
  (when (and from data) (error "Supply :from or :data, not both."))
  (if from
      (let* ((fixture (read-fixture "fixtures/studies.sexp"))
             (record (resolve-study-fixture from (getf fixture :studies)))
             (source (or (getf record :data)
                         (error "This fixture is an extension specification, not runnable data.")))
             (metadata (getf record :study-metadata))
             (object (study :name name
                            :data (dataset (getf source :store)
                                           :columns (getf source :var-labels)
                                           :variables (getf fixture :shared-variable-descriptors)
                                           :row-labels (getf source :case-labels)
                                           :metadata (list :context (getf record :context)
                                                           :row-role (getf source :row-role)
                                                           :study-metadata metadata)))))
        (unless (= (array-dimension (getf source :store) 0) (length (getf source :case-labels)))
          (error "Fixture row labels do not match storage."))
        (configure object
          (design :structure (if (getf metadata :paired-by) :paired :independent)
                  :independent-unit (getf metadata :independent-case)
                  :assignment-unit (getf metadata :assignment-unit)
                  :paired-by (getf metadata :paired-by) :replicates-within 'aliquot)
          (measurements :outcome 'response :group 'condition :statistical-type :continuous
                        :units :u-per-ml
                        :aggregation (if (listp (getf metadata :technical-aggregation)) :mean :none))
          (assumptions :independent-cases (getf (getf metadata :independence) :status)
                       :normal-differences :unknown :normal-groups :unknown
                       :source :synthetic-design))
        object)
      (progn
        (unless (typep data 'dataset) (error "A study requires a dataset object or :from fixture."))
        (make-instance 'study :name (snapshot name) :data data))))
