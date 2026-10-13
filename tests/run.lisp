;;;; tests/run.lisp - run the test suite; exit status 0 when all pass.
;;;;
;;;; Works the same with both ways of running Lisp used here:
;;;;   sbcl --non-interactive --load tests/run.lisp     (SBCL + ~/quicklisp)
;;;;   ros run --load tests/run.lisp                    (Roswell)
;;;; or scripts/test.sh [sbcl|ros|both].

(unless (find-package :ql)
  (load (merge-pathnames "quicklisp/setup.lisp" (user-homedir-pathname))))

;; If ocicl's runtime is loaded from an init file, it tries to install
;; missing systems itself; leave that to Quicklisp.
(let ((ocicl (find-package :ocicl-runtime)))
  (when ocicl
    (setf (symbol-value (find-symbol "*DOWNLOAD*" ocicl)) nil)))

;; Find cl-datascience.asd in this checkout, whatever the current directory.
(push (uiop:pathname-parent-directory-pathname
       (uiop:pathname-directory-pathname *load-truename*))
      asdf:*central-registry*)

(ql:quickload :cl-datascience/tests :silent t)

(uiop:quit (if (uiop:symbol-call :cl-datascience/tests :run-all) 0 1))
