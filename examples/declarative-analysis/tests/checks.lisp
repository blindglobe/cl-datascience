;;; Copyright (c) 2026 Gwang Jin Kim. SPDX-License-Identifier: MIT.
(in-package :clds-example)
(format t "~&=== GRAMMAR CHECKS ===~%")
(defvar *checks-passed* 0)

(defmacro verify (name &body body)
  `(progn ,@body (incf *checks-passed*) (format t "PASS: ~A~%" ,name)))

(defun error-signaled-p (function)
  (handler-case (progn (funcall function) nil) (error () t)))

(defun configured-study (&optional (fixture :paired-technical-duplicates))
  (let ((object (study :from fixture)))
    (configure object
      (goal :quantity (if (eq fixture :independent-cultures)
                          :difference-in-population-means :mean-within-case-difference)
            :contrast '(treatment vehicle) :claim :population-mean-inference
            :confidence-level 0.95d0))
    object))

(defun quiet-propose (object)
  (let ((*standard-output* (make-broadcast-stream))
        (*trace-output* (make-broadcast-stream)))
    (propose object :analysis)))

(defun reordered-study (object indices)
  (let* ((old (study-data object))
         (table (make-array (list (length indices) (length (columns old)))))
         (fresh nil))
    (loop for old-row in indices for new-row from 0
          do (dotimes (col (length (columns old)))
               (setf (aref table new-row col) (aref (%table old) old-row col))))
    (setf fresh (study :data (dataset table :columns (columns old) :variables (variables old)
                                     :metadata (source-metadata old))))
    (apply #'configure fresh (mapcar (lambda (entry) (make-aspect (car entry) (cdr entry)))
                                    (aspects object)))
    fresh))

(let ((object (study :from :paired-aliquots)))
  (verify "Selectors return a configuration sheet without mutation"
    (let ((before (revision object)) (events (history object))
          (sheet (configure object :goal :design)))
      (assert (= 2 (length (getf sheet :aspects))))
      (assert (member :quantity (getf (first (getf sheet :aspects)) :missing)))
      (assert (= before (revision object))) (assert (equal events (history object)))))
  (verify "Multiple aspect updates are one revision and return the study"
    (let ((before (revision object)))
      (assert (eq object (configure object
                          (goal :quantity :mean-within-case-difference
                                :contrast '(treatment vehicle) :claim :population-mean-inference)
                          (assumptions :normal-differences :unknown))))
      (assert (= (1+ before) (revision object)))))
  (verify "Mixed selectors and updates are rejected atomically"
    (let ((before (revision object)))
      (assert (error-signaled-p (lambda () (configure object :goal (goal :claim :descriptive)))))
      (assert (= before (revision object)))))
  (verify "Invalid fields and duplicate aspect updates preserve the revision"
    (let ((before (revision object)))
      (assert (error-signaled-p (lambda () (configure object (goal :typo 1)))))
      (assert (error-signaled-p (lambda () (configure object (goal :claim :descriptive)
                                                    (goal :claim :population-mean-inference)))))
      (assert (= before (revision object)))))
  (verify "Invalid confidence specifications are rejected"
    (assert (error-signaled-p (lambda () (goal :confidence-level -0.1d0))))
    (assert (error-signaled-p (lambda () (goal :confidence-level 1d0)))))
  (verify "Aspect patches preserve omitted values; identical patches are no-ops"
    (configure object (goal :confidence-level 0.9d0))
    (assert (eq :mean-within-case-difference (field object :goal :quantity)))
    (let ((before (revision object)))
      (configure object (goal :confidence-level 0.9d0))
      (assert (= before (revision object))))))

(let* ((object (configured-study)) (data (study-data object)))
  (verify "Fixture overlays retain metadata and preserve source storage"
    (assert (= 12 (array-dimension (%table data) 0)))
    (assert (= 12 (length (row-labels data))))
    (assert (variables data)) (assert (source-metadata data))
    (let ((copy (dataset-table data)))
      (setf (aref copy 0 4) -100d0)
      (assert (= 0.8d0 (aref (%table data) 0 4)))))
  (verify "Checks distinguish 12 measurements from 3 independent case keys"
    (let ((result (check object :data :design)))
      (assert (= 12 (getf result :rows))) (assert (= 3 (getf result :independent-cases)))
      (assert (getf result :complete-pairs)) (assert (getf result :technical-duplicates))))
  (verify "Wouldwork derives two paired routes with mandatory aggregation"
    (let ((package-before *package*))
      (quiet-propose object)
      (assert (eq package-before *package*)))
    (assert (= 2 (length (proposals object))))
    (dolist (proposal (proposals object))
      (assert (member (getf proposal :id) '(:paired-t :difference-t)))
      (assert (equal "AGGREGATE-TECHNICAL-READINGS"
                     (symbol-name (first (first (getf proposal :steps))))))
      (assert (eq :conditional-on-obligations (getf proposal :status)))
      (assert (member :normal-difference-premise (getf proposal :obligations)))))
  (verify "Approval requires a current explicit selection and actor"
    (assert (error-signaled-p (lambda () (approve object :analysis-plan :by :tester))))
    (assert (error-signaled-p (lambda () (approve object :analysis-plan :proposal :nonexistent :by :tester))))
    (assert (error-signaled-p (lambda () (approve object :analysis-plan :proposal :paired-t)))))
  (verify "Selecting a proposal does not accept an unknown model premise"
    (approve object :analysis-plan :proposal :paired-t :by :tester)
    (assert (eq :unknown (field object :assumptions :normal-differences)))
    (assert (eq :current (getf (first (approvals object)) :status))))
  (verify "Configuration changes invalidate previous checks, proposals, and approvals"
    (configure object (goal :confidence-level 0.90d0))
    (assert (null (proposals object))) (assert (null (current-check object)))
    (assert (eq :stale (getf (first (approvals object)) :status))))
  (verify "History and stale approvals preserve the reviewed specification"
    (let* ((approved (getf (first (approvals object)) :approved-specification))
           (event (find :configured (reverse (history object)) :key (lambda (e) (getf e :event))))
           (change (find :goal (getf event :detail) :key (lambda (c) (getf c :aspect)))))
      (assert (= 0.95d0 (getf (getf approved :goal-contract) :confidence-level)))
      (assert (= 0.95d0 (getf (getf change :before) :confidence-level)))
      (assert (= 0.90d0 (getf (getf change :after) :confidence-level)))))
  (verify "Regenerating proposals invalidates selections even at the same revision"
    (quiet-propose object)
    (approve object :analysis-plan :proposal :paired-t :by :tester)
    (let ((before (revision object)))
      (quiet-propose object)
      (assert (= before (revision object)))
      (assert (eq :stale (getf (first (approvals object)) :status)))))
  (verify "Proposal reports disclose review and comparison limits"
    (let ((text (report object)))
      (assert (search "numerical validation pending" text))
      (assert (search "No precision ranking established" text))
      (assert (search "statistical rules await scientific review" text)))))

(verify "Independent cultures produce Welch rather than paired routes"
  (let ((object (configured-study :independent-cultures)))
    (quiet-propose object)
    (assert (= 6 (getf (current-check object) :independent-cases)))
    (assert (= 1 (length (proposals object))))
    (assert (eq :welch (getf (first (proposals object)) :id)))))

(verify "Contradictory independent-group metadata produces no route"
  (let ((object (configured-study :paired-aliquots)))
    (configure object (design :structure :independent :paired-by nil)
                      (goal :quantity :difference-in-population-means))
    (quiet-propose object)
    (assert (null (proposals object)))
    (assert (find :contradictory-design (getf (current-check object) :issues)
                  :key (lambda (issue) (getf issue :code))))))

(verify "Nominal metadata does not produce mean-inference suggestions"
  (let ((object (configured-study)))
    (configure object (measurements :statistical-type :nominal))
    (quiet-propose object) (assert (null (proposals object)))))

(verify "Unknown aggregation policy creates an obligation, not a guessed transformation"
  (let ((object (configured-study)))
    (configure object (measurements :aggregation :unknown))
    (quiet-propose object) (assert (null (proposals object)))
    (assert (find :aggregation-policy (getf (current-check object) :issues)
                  :key (lambda (issue) (getf issue :code))))))

(verify "A missing pair key is not inferred from row order"
  (let ((object (configured-study)))
    (configure object (design :paired-by nil))
    (quiet-propose object) (assert (null (proposals object)))
    (assert (find :pairing-key (getf (current-check object) :issues)
                  :key (lambda (issue) (getf issue :code))))))

(verify "Calling the in-image backend without an isolated runtime is rejected"
  (let ((*wouldwork-isolated-root* nil) (object (configured-study)))
    (assert (error-signaled-p (lambda () (propose-in-isolated-runtime object))))))

(verify "Contradicted independence blocks the requested inferential routes"
  (let ((object (configured-study)))
    (configure object (assumptions :independent-cases :contradicted))
    (quiet-propose object) (assert (null (proposals object)))
    (assert (find :contradicted-independence (getf (current-check object) :issues)
                  :key (lambda (issue) (getf issue :code))))))

(verify "A contradicted difference model is not silently accepted"
  (let ((object (configured-study)))
    (configure object (assumptions :normal-differences :contradicted))
    (quiet-propose object) (assert (null (proposals object)))))

(verify "Mean-inference rules do not promise causal identification"
  (let ((object (configured-study)))
    (configure object (goal :claim :causal-treatment-effect))
    (quiet-propose object) (assert (null (proposals object)))
    (assert (search "not a proof" (report object)))))

(verify "Row ordering does not determine pairing or candidate methods"
  (let* ((base (configured-study :paired-aliquots))
         (permuted (reordered-study base '(5 1 3 0 4 2))))
    (quiet-propose base) (quiet-propose permuted)
    (flet ((ids (object) (sort (mapcar (lambda (p) (getf p :id)) (proposals object))
                              #'string< :key #'symbol-name)))
      (assert (equal (ids base) (ids permuted))))
    (assert (= 3 (getf (current-check permuted) :independent-cases)))))

(verify "Incomplete pairs become obligations without silent deletion"
  (let ((object (reordered-study (configured-study :paired-aliquots) '(0 1 2 3 4))))
    (quiet-propose object) (assert (null (proposals object)))
    (assert (= 5 (getf (current-check object) :rows)))
    (assert (find :incomplete-pairs (getf (current-check object) :issues)
                  :key (lambda (issue) (getf issue :code))))))

(verify "Missing or wrong replicate grouping cannot bypass aggregation"
  (dolist (key '(nonexistent reading))
    (let ((object (configured-study)))
      (configure object (design :replicates-within key))
      (quiet-propose object)
      (assert (getf (current-check object) :technical-duplicates))
      (assert (null (proposals object))))))

(verify "Multiple assignment aliquots per donor and condition need another preparation contract"
  (let* ((base (configured-study)) (table (dataset-table (study-data base))))
    (setf (aref table 1 1) 'A7)
    (let ((object (study :data (dataset table :columns (columns (study-data base))))))
      (apply #'configure object
             (mapcar (lambda (entry) (make-aspect (car entry) (cdr entry))) (aspects base)))
      (quiet-propose object)
      (assert (null (proposals object)))
      (assert (find :incomplete-pairs (getf (current-check object) :issues)
                    :key (lambda (issue) (getf issue :code)))))))

(verify "Public grammar works with caller-package symbols and keyword column references"
  (let ((object (configured-study :paired-aliquots)))
    (configure object
      (goal :contrast (list (intern "TREATMENT" :cl-user) (intern "VEHICLE" :cl-user)))
      (design :independent-unit :biological-id :paired-by :biological-id))
    (quiet-propose object)
    (assert (= 2 (length (proposals object))))))

(format t "~&~D grammar and backend checks passed.~%" *checks-passed*)
