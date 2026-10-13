#!/bin/sh
# Run every reference analysis with the pinned R (uvr) and refresh
# reference.out, expected.json and data.csv in each example folder.
set -e
cd "$(dirname "$0")"
uvr sync -q
for script in */reference.R; do
  dir=$(dirname "$script")
  echo "== $dir"
  uvr run -q "$script" > "$dir/reference.out"
done
