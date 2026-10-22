#!/bin/sh
# Build docs/DESIGN.pdf from docs/DESIGN.md (needs pandoc and xelatex).
#   docs/build-pdf.sh
cd "$(dirname "$0")" || exit 1
pandoc DESIGN.md -o DESIGN.pdf --pdf-engine=xelatex --toc --toc-depth=2 -N \
  -V geometry:margin=2.2cm -V papersize=a4 -V fontsize=11pt \
  -V mainfont="Palatino" -V colorlinks=true -V linkcolor=black -V urlcolor=blue \
  -H pdf-header.tex
