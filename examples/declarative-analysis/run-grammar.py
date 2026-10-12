#!/usr/bin/env python3
# Copyright (c) 2026 Gwang Jin Kim. SPDX-License-Identifier: MIT.
"""Run the object/aspect grammar demo and real Wouldwork search in isolation.

python3 run-grammar.py           # user-facing grammar and generated proposals
python3 run-grammar.py --check   # grammar/state/metadata/search checks

Requires existing SBCL and Wouldwork with ocicl or Quicklisp dependencies. No background
process is left running; temporary source and ASDF output directories are removed.
"""
import argparse
from setup import lisp_string
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
                        default=(Path(__file__).resolve().parent / '.deps/wouldwork'
                                 if (Path(__file__).resolve().parent / '.deps/wouldwork/wouldwork.asd').is_file()
                                 else Path.home() / 'projects/cl/wouldwork'))
    dependency_options = parser.add_mutually_exclusive_group()
    dependency_options.add_argument('--dependency-setup', type=Path,
                        help='Worker-only dependency initializer (ocicl); overrides Quicklisp')
    dependency_options.add_argument('--quicklisp', type=Path,
                                    help='Explicit Quicklisp fallback instead of ocicl')
    parser.add_argument('--sbcl', default='sbcl')
    args = parser.parse_args()
    if bool(args.request) != bool(args.result) or (args.check and args.request):
        parser.error('--request and --result must be supplied together, without --check.')
    executable = shutil.which(args.sbcl)
    project = Path(__file__).resolve().parent
    source = args.wouldwork.expanduser().resolve()
    quicklisp = (args.quicklisp or Path.home() / 'quicklisp/setup.lisp').expanduser().resolve()
    local_setup = project / '.deps/dependencies.lisp'
    dependency_setup = (args.dependency_setup or
                        (local_setup if not args.quicklisp and local_setup.is_file() else None))
    if dependency_setup:
        dependency_setup = dependency_setup.expanduser().resolve()
    if executable is None or not (source / 'wouldwork.asd').is_file():
        parser.error('Specify existing SBCL and Wouldwork installations, or run setup.sh.')
    if not (dependency_setup or quicklisp).is_file():
        parser.error('Run setup.sh, or specify an existing dependency initializer/Quicklisp setup.')
    dependencies = (f'(load {lisp_string(str(dependency_setup))})' if dependency_setup else
                    f'(load {lisp_string(str(quicklisp))})\n'
                    '(ql:quickload \'(:alexandria :iterate :lparallel) :silent t)')
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
                      f'{lisp_string(str(args.request.resolve()))} '
                      f'{lisp_string(str(args.result.resolve()))})'
                      if args.request else f'(load {lisp_string(str(entry))})')
        bootstrap.write_text(f'''
(require :asdf)
(asdf:initialize-output-translations
 '(:output-translations (t {lisp_string(str(root / 'fasl') + '/')}) :ignore-inherited-configuration))
{dependencies}
(asdf:load-asd {lisp_string(str(runtime / 'wouldwork.asd'))})
(asdf:load-system :wouldwork)
(assert (zerop (symbol-value (find-symbol "*THREADS*" "WOULDWORK"))))
(asdf:load-asd {lisp_string(str(project / 'declarative-analysis.asd'))})
(asdf:load-system "declarative-analysis")
(setf clds-example::*wouldwork-isolated-root* #p{lisp_string(str(runtime) + '/')})
{entry_form}
(format t "~&GRAMMAR-RUN-COMPLETED~%")
''')
        process = subprocess.Popen(
            [executable, '--noinform', '--no-sysinit', '--no-userinit',
             '--non-interactive', '--load', str(bootstrap)],
            stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True,
            cwd=dependency_setup.parent if dependency_setup else None)
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
