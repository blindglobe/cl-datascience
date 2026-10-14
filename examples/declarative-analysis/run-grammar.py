#!/usr/bin/env python3
# Copyright (c) 2026 Gwang Jin Kim. SPDX-License-Identifier: MIT.
"""Run the grammar demo/checks with ASDF-resolved libraries and isolated Wouldwork.

No repository location or Quicklisp installation directory is assumed.
Python copies Wouldwork; ASDF discovers and loads the Common Lisp systems.
"""
import argparse
from pathlib import Path
import shutil
import tempfile
from setup import lisp_string, run


def discover(project, executable, args, temporary):
    """Ask SBCL/ASDF for sources; never evaluate the installed Wouldwork .asd."""
    initializer = args.dependency_setup or args.quicklisp
    local_loader = project / '.deps/load.lisp'
    initialization = (f'(load {lisp_string(initializer.expanduser().resolve())})' if initializer else
                      f'(load {lisp_string(local_loader)})' if local_loader.is_file() else '')
    override = (f'(setf clds-demo:*wouldwork-source* #p{lisp_string(str(args.wouldwork.expanduser().resolve()) + "/")})'
                if args.wouldwork else '')
    entry = temporary / 'discover.lisp'
    entry.write_text(f'''
(require :asdf)
(asdf:initialize-output-translations
 '(:output-translations (t {lisp_string(str(temporary / 'discovery-fasl') + '/')}) :ignore-inherited-configuration))
{initialization}
(asdf:load-asd {lisp_string(project / 'declarative-analysis.asd')})
(asdf:load-system "declarative-analysis")
{override}
(clds-demo::emit-worker-arguments)
''', encoding='utf-8')
    output = run([executable, '--noinform', '--no-sysinit', '--no-userinit', '--non-interactive',
                  '--load', str(entry)], capture=True, timeout=60)
    marker = 'CLDS-WORKER-ARGV\n'
    if marker not in output or 'CLDS-WORKER-ARGV-END\0' not in output:
        raise RuntimeError(f'ASDF source discovery did not complete:\n{output}')
    values = output.split(marker, 1)[1].split('\0CLDS-WORKER-ARGV-END', 1)[0].split('\0')
    source = Path(values[values.index('--wouldwork') + 1])
    directories = [Path(values[index + 1]) for index, value in enumerate(values)
                   if value == '--source-directory']
    return source, directories


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true')
    parser.add_argument('--request', type=Path)
    parser.add_argument('--result', type=Path)
    parser.add_argument('--wouldwork', type=Path, help='Explicit source override; otherwise locate with ASDF')
    parser.add_argument('--source-directory', type=Path, action='append',
                        help='Resolved ASDF library directory; normally supplied by the Lisp caller')
    initialization = parser.add_mutually_exclusive_group()
    initialization.add_argument('--dependency-setup', type=Path, help='Optional ASDF registry initializer')
    initialization.add_argument('--quicklisp', type=Path, help='Optional explicit Quicklisp initializer')
    parser.add_argument('--sbcl', default='sbcl')
    args = parser.parse_args()
    if bool(args.request) != bool(args.result) or (args.check and args.request):
        parser.error('--request and --result must be supplied together, without --check.')
    executable = shutil.which(args.sbcl)
    if not executable:
        parser.error('Install SBCL or pass --sbcl with its executable path.')
    project = Path(__file__).resolve().parent
    with tempfile.TemporaryDirectory(prefix='clds-grammar-runtime-') as temporary:
        root = Path(temporary)
        if args.source_directory and args.wouldwork:
            source = args.wouldwork.expanduser().resolve()
            directories = [path.expanduser().resolve() for path in args.source_directory]
        else:
            source, directories = discover(project, executable, args, root)
        if not (source / 'wouldwork.asd').is_file():
            parser.error('ASDF must locate a Wouldwork source checkout with wouldwork.asd.')
        runtime = root / 'wouldwork'
        runtime.mkdir()
        shutil.copyfile(source / 'wouldwork.asd', runtime / 'wouldwork.asd')
        shutil.copytree(source / 'src', runtime / 'src',
                        ignore=shutil.ignore_patterns('*.fasl', 'problem.lisp'))
        (runtime / '.clds-isolated-runtime').write_text('Temporary CLDS grammar runtime.\n')
        registry = ' '.join(f'(:directory {lisp_string(str(path) + "/")})' for path in directories)
        entry = project / ('tests/checks.lisp' if args.check else 'interface/grammar-demo.lisp')
        entry_form = (f'(clds-demo::run-planner-request {lisp_string(args.request.resolve())} '
                      f'{lisp_string(args.result.resolve())})' if args.request else
                      f'(load {lisp_string(entry)})')
        bootstrap = root / 'bootstrap.lisp'
        bootstrap.write_text(f'''
(require :asdf)
(asdf:initialize-output-translations
 '(:output-translations (t {lisp_string(str(root / 'fasl') + '/')}) :ignore-inherited-configuration))
(asdf:initialize-source-registry '(:source-registry {registry} :ignore-inherited-configuration))
(asdf:load-asd {lisp_string(runtime / 'wouldwork.asd')})
(asdf:load-system "wouldwork")
(assert (zerop (symbol-value (find-symbol "*THREADS*" "WOULDWORK"))))
(asdf:load-asd {lisp_string(project / 'declarative-analysis.asd')})
(asdf:load-system "declarative-analysis")
(setf clds-demo::*wouldwork-isolated-root* #p{lisp_string(str(runtime) + '/')})
{entry_form}
(format t "~&GRAMMAR-RUN-COMPLETED~%")
''', encoding='utf-8')
        output = run([executable, '--noinform', '--no-sysinit', '--no-userinit', '--non-interactive',
                      '--load', str(bootstrap)], capture=True, timeout=60)
        if 'GRAMMAR-RUN-COMPLETED' not in output:
            raise RuntimeError(output)
        if not args.request:
            marker = '=== GRAMMAR CHECKS ===' if args.check else 'Configuration sheet:'
            start = output.find(marker)
            print(output[start:] if start >= 0 else output)
    if not args.request:
        print('Temporary Wouldwork runtime removed; child process exited.')


if __name__ == '__main__':
    try:
        main()
    except (RuntimeError, OSError) as error:
        raise SystemExit(str(error))
