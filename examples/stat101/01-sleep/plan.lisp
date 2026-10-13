;;;; examples/stat101/01-sleep/plan.lisp - see src/examples.lisp

(:objects ((frame sleep)
           (variable extra group id))

 :facts ((continuous extra)          ; extra hours of sleep
         (two-levels group))         ; drug 1 or 2

 :knowledge ((plain)
             (independent (rows-independent sleep))
             (repeated (repeated-by> sleep id group)))   ; each patient got both drugs

 :questions ((difference (estimated-difference> extra group))))
