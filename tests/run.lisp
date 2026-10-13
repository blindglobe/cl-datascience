;;;; tests/run.lisp - run the test suite; exit status 0 when all pass.
;;;;
;;;; Works the same with both ways of running Lisp used here:
;;;;   sbcl --non-interactive --load tests/run.lisp     (SBCL + ~/quicklisp)
;;;;   ros run --load tests/run.lisp                    (Roswell)
;;;; or scripts/test.sh [sbcl|ros|both].

(unless (find-package :ql)
  (load (merge-pathnames "quicklisp/setup.lisp" (user-homedir-pathname))))

;; Any error ends the run with a failure status instead of waiting in the
;; debugger (Roswell does not disable the debugger for --load).
(setf *debugger-hook*
      (lambda (condition hook)
        (declare (ignore hook))
        (format *error-output* "~&Error: ~a~%" condition)
        (uiop:quit 2)))

;; If ocicl's runtime is loaded from an init file, it tries to install
;; missing systems itself; leave that to Quicklisp.
(let ((ocicl (find-package :ocicl-runtime)))
  (when ocicl
    (setf (symbol-value (find-symbol "*DOWNLOAD*" ocicl)) nil)))

;; Find cl-datascience.asd in this checkout, whatever the current directory.
(push (uiop:pathname-parent-directory-pathname
       (uiop:pathname-directory-pathname *load-truename*))
      asdf:*central-registry*)

;; Wouldwork compiles its staged problem (src/problem.lisp) whenever it is
;; loaded. If a process was killed while a broken problem was staged, the
;; load fails; then stage wouldwork's own blocks3 again and retry once.
(defun restage-blocks3 ()
  (let ((src (merge-pathnames "src/" (asdf:system-source-directory :wouldwork))))
    (uiop:copy-file (merge-pathnames "problem-blocks3.lisp" src)
                    (merge-pathnames "problem.lisp" src))
    (uiop:delete-file-if-exists
     (merge-pathnames "vals.lisp" (asdf:system-source-directory :wouldwork)))))

(handler-case (ql:quickload :cl-datascience/tests :silent t)
  (error (e)
    (format *error-output* "~&Loading failed (~a);~%restaging wouldwork's blocks3 and retrying.~%" e)
    (restage-blocks3)
    (ql:quickload :cl-datascience/tests :silent t)))

(uiop:quit (if (uiop:symbol-call :cl-datascience/tests :run-all) 0 1))
