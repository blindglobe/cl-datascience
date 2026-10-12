#!/usr/bin/env python3
# Copyright (c) 2026 Gwang Jin Kim. SPDX-License-Identifier: MIT.
"""Run the object/aspect grammar demo and real Wouldwork search in isolation.

python3 run-grammar.py           # user-facing grammar and generated proposals
python3 run-grammar.py --check   # grammar/state/metadata/search checks

Requires existing SBCL, Quicklisp and Wouldwork dependencies. No background
process is left running; temporary source and ASDF output directories are removed.
"""
import argparse
import json
from pathlib import Path
import shutil
import subprocess
import tempfile


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true')
    parser.add_argument('--request', type=Path, help='Data-only Lisp request file')
    parser.add_argument('--result', type=Path, help='Data-only Lisp result file')
    parser.add_argument('--wouldwork', type=Path,
                        default=Path.home() / 'projects/cl/wouldwork')
    parser.add_argument('--quicklisp', type=Path,
                        default=Path.home() / 'quicklisp/setup.lisp')
    parser.add_argument('--sbcl', default='sbcl')
    args = parser.parse_args()
    if bool(args.request) != bool(args.result) or (args.check and args.request):
        parser.error('--request and --result must be supplied together, without --check.')
    executable = shutil.which(args.sbcl)
    project = Path(__file__).resolve().parent
    source = args.wouldwork.expanduser().resolve()
    quicklisp = args.quicklisp.expanduser().resolve()
    if executable is None or not (source / 'wouldwork.asd').is_file() or not quicklisp.is_file():
        parser.error('Specify existing SBCL, Wouldwork, and Quicklisp installations.')
    with tempfile.TemporaryDirectory(prefix='clds-grammar-runtime-') as temporary:
        root = Path(temporary)
        runtime = root / 'wouldwork'
        runtime.mkdir()
        shutil.copyfile(source / 'wouldwork.asd', runtime / 'wouldwork.asd')
        shutil.copytree(source / 'src', runtime / 'src',
                        ignore=shutil.ignore_patterns('*.fasl', 'problem.lisp'))
        (runtime / '.clds-isolated-runtime').write_text('Temporary CLDS grammar runtime.\n')
        bootstrap = root / 'bootstrap.lisp'
        entry = project / ('tests/checks.lisp' if args.check else 'interface/grammar-demo.lisp')
        entry_form = (f'(clds-example::run-planner-request '
                      f'{json.dumps(str(args.request.resolve()))} '
                      f'{json.dumps(str(args.result.resolve()))})'
                      if args.request else f'(load {json.dumps(str(entry))})')
        bootstrap.write_text(f'''
(require :asdf)
(load {json.dumps(str(quicklisp))})
(asdf:initialize-output-translations
 '(:output-translations (t {json.dumps(str(root / 'fasl') + '/')}) :ignore-inherited-configuration))
(ql:quickload '(:alexandria :iterate :lparallel) :silent t)
(asdf:load-asd {json.dumps(str(runtime / 'wouldwork.asd'))})
(asdf:load-system :wouldwork)
(assert (zerop (symbol-value (find-symbol "*THREADS*" "WOULDWORK"))))
(asdf:load-asd {json.dumps(str(project / 'declarative-analysis.asd'))})
(asdf:load-system "declarative-analysis")
(setf clds-example::*wouldwork-isolated-root* #p{json.dumps(str(runtime) + '/')})
{entry_form}
(format t "~&GRAMMAR-RUN-COMPLETED~%")
''')
        process = subprocess.Popen(
            [executable, '--noinform', '--no-sysinit', '--no-userinit',
             '--non-interactive', '--load', str(bootstrap)],
            stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
        try:
            output, _ = process.communicate(timeout=60)
        except BaseException:
            process.kill()
            process.communicate()
            raise
        if process.returncode or 'GRAMMAR-RUN-COMPLETED' not in output:
            raise SystemExit(output)
        # Keep user output legible while preserving diagnostics on failure.
        marker = '=== GRAMMAR CHECKS ===' if args.check else 'Configuration sheet:'
        start = output.find(marker)
        if not args.request:
            print(output[start:] if start >= 0 else output)
    if not args.request:
        print('Temporary Wouldwork runtime removed; child process exited.')


if __name__ == '__main__':
    main()
