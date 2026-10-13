#!/bin/sh
# Run the test suite with SBCL + ~/quicklisp, with Roswell, or with both
# (the default). Both are supported equally; run both before committing.
#   scripts/test.sh [sbcl|ros|both]
cd "$(dirname "$0")/.." || exit 1
status=0
run_sbcl() { echo "== SBCL + ~/quicklisp"; sbcl --noinform --non-interactive --load tests/run.lisp || status=1; }
run_ros()  { echo "== Roswell";            ros run --load tests/run.lisp || status=1; }
case "${1:-both}" in
  sbcl) run_sbcl ;;
  ros)  run_ros ;;
  both) run_sbcl; run_ros ;;
  *) echo "usage: $0 [sbcl|ros|both]"; exit 2 ;;
esac
exit $status
