;;; Copyright (c) 2026 Gwang Jin Kim. SPDX-License-Identifier: MIT.
;;; Load from any working directory. Loading does not start Wouldwork.
(require :asdf)
(let ((directory (uiop:pathname-directory-pathname
                  (or *load-truename* (error "Load this file with LOAD.")))))
  (let ((registry (probe-file (merge-pathnames ".deps/dependencies.lisp" directory))))
    (when registry (load registry)))
  (asdf:load-asd (merge-pathnames "declarative-analysis.asd" directory))
  (asdf:load-system "declarative-analysis"))
