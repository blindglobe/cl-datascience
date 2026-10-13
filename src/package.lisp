;;;; src/package.lisp

(defpackage #:cl-datascience
  (:nicknames #:clds)
  (:use #:cl)
  (:export
   ;; planner bridge (src/planner.lisp)
   #:find-plans #:plan-assumptions #:planning-error #:keywordize
   ;; examples (src/examples.lisp)
   #:examples-directory #:load-example #:example-plans))
