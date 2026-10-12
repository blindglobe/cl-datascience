#!/usr/bin/env python3
# Copyright (c) 2026 Gwang Jin Kim. SPDX-License-Identifier: MIT.
"""Create a project-local ocicl environment without changing Lisp startup files."""
import argparse
import os
import re
from pathlib import Path
import shutil
import signal
import subprocess
import sys
import tempfile

WOULDWORK_URL = 'https://github.com/davypough/wouldwork.git'
WOULDWORK_REVISION = '1d4e764633365ff5f7c187b94e98c1f8f09ed2fd'
OCICL_URL = 'https://github.com/ocicl/ocicl.git'
OCICL_REVISION = '4bc19836278679dd4660fe949c5d516d3a5b4de4'  # v2.20.0


def lisp_string(value):
    """Quote a Common Lisp string, preserving literal backslashes and Unicode."""
    return '"' + str(value).replace('\\', '\\\\').replace('"', '\\"') + '"'


def run(command, *, cwd=None, env=None, timeout=600, capture=False):
    """Wait for foreground command; kill/reap its process group on failure/interrupt."""
    process = subprocess.Popen(command, cwd=cwd, env=env, start_new_session=True,
                               stdout=subprocess.PIPE if capture else None,
                               stderr=subprocess.STDOUT if capture else None, text=True)
    try:
        output, _ = process.communicate(timeout=timeout)
    except BaseException:
        try:
            os.killpg(process.pid, signal.SIGKILL)
        except ProcessLookupError:
            pass
        process.communicate()
        raise
    if process.returncode:
        raise RuntimeError(f'Command failed ({process.returncode}): {command[0]}\n{output or ""}')
    return output or ''


def checkout(url, revision, destination):
    """Create a pinned checkout; reuse exact existing revisions without resetting files."""
    if destination.exists():
        if not (destination / '.git').is_dir():
            raise RuntimeError(f'Refusing to overwrite existing directory: {destination}')
        actual = run(['git', '-C', str(destination), 'rev-parse', 'HEAD'], capture=True).strip()
        changes = run(['git', '-C', str(destination), 'status', '--porcelain',
                       '--untracked-files=no'], capture=True).strip()
        if actual != revision or changes:
            raise RuntimeError(f'{destination} has another revision or local changes; use a new --prefix.')
        return
    destination.parent.mkdir(parents=True, exist_ok=True)
    # A failed download never leaves a misleading partially initialized destination.
    with tempfile.TemporaryDirectory(prefix='clds-download-', dir=destination.parent) as temporary:
        tree = Path(temporary) / 'source'
        run(['git', 'init', '-q', str(tree)])
        run(['git', '-C', str(tree), 'remote', 'add', 'origin', url])
        run(['git', '-C', str(tree), 'fetch', '--depth', '1', 'origin', revision])
        run(['git', '-C', str(tree), 'checkout', '-q', '--detach', 'FETCH_HEAD'])
        tree.rename(destination)


def sbcl_script(sbcl, text, prefix, *, cwd=None, env=None):
    with tempfile.TemporaryDirectory(prefix='clds-bootstrap-', dir=prefix) as temporary:
        entry = Path(temporary) / 'bootstrap.lisp'
        header = f'''(require :asdf)
(asdf:initialize-output-translations
 '(:output-translations (t {lisp_string(str(prefix / 'cache') + '/')}) :ignore-inherited-configuration))
'''
        entry.write_text(header + text, encoding='utf-8')
        return run([sbcl, '--dynamic-space-size', '3072', '--noinform', '--no-sysinit',
                    '--no-userinit', '--non-interactive', '--load', str(entry)],
                   cwd=cwd, env=env)


def usable_ocicl(executable):
    try:
        output = run([str(executable), 'version'], capture=True, timeout=30)
        version = re.search(r'v?(\d+)\.(\d+)\.(\d+)', output)
        return bool(version and tuple(map(int, version.groups())) >= (2, 20, 0))
    except (OSError, RuntimeError, subprocess.TimeoutExpired):
        return False


def build_ocicl(prefix, sbcl, env):
    executable = prefix / 'tools/bin/ocicl'
    if executable.exists() and usable_ocicl(executable):
        return executable
    source = prefix / 'tools/ocicl-source'
    checkout(OCICL_URL, OCICL_REVISION, source)
    print('Building pinned ocicl locally with the current SBCL...', flush=True)
    sbcl_script(sbcl, f'''
(load {lisp_string(source / 'runtime/asdf.lisp')})
(asdf:initialize-output-translations
 '(:output-translations (t {lisp_string(str(prefix / 'cache') + '/')}) :ignore-inherited-configuration))
(asdf:initialize-source-registry
 '(:source-registry (:tree {lisp_string(str(source) + '/')}) :ignore-inherited-configuration))
(asdf:make "ocicl")
''', prefix, cwd=source, env=env)
    executable.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(source / 'ocicl', executable)
    executable.chmod(0o755)
    if not usable_ocicl(executable):
        raise RuntimeError('The newly built ocicl executable cannot start.')
    return executable


def dependency_setup(project, prefix, wouldwork):
    """Register installed sources with ASDF, using paths relative to this file."""
    project_relative = os.path.relpath(project, prefix) + '/'
    wouldwork_entry = (f'(list :directory (merge-pathnames {lisp_string(os.path.relpath(wouldwork, prefix) + "/")} base))'
                       if wouldwork else '')
    return f''' ;;; Generated ASDF registry. No installed Wouldwork definition is loaded.
(require :asdf)
(let ((base (uiop:pathname-directory-pathname *load-truename*)))
  (asdf:initialize-source-registry
   (list :source-registry
         (list :directory (merge-pathnames {lisp_string(project_relative)} base))
         {wouldwork_entry}
         (list :tree (merge-pathnames "ocicl/" base))
         :inherit-configuration)))
'''


def configure_loader(project, prefix, wouldwork=None):
    registry = prefix / 'dependencies.lisp'
    registry.write_text(dependency_setup(project, prefix, wouldwork), encoding='utf-8')
    loader = prefix / 'load.lisp'
    loader.write_text(''' ;;; Generated CLDS loader; all source lookup uses ASDF.
(require :asdf)
(load (merge-pathnames "dependencies.lisp"
                       (uiop:pathname-directory-pathname *load-truename*)))
(asdf:load-system "declarative-analysis")
(setf clds-demo:*example-study* (clds-demo:demo))
''', encoding='utf-8')
    return loader


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--install-system', action='store_true', help='Handled by setup.sh')
    parser.add_argument('--prefix', type=Path)
    parser.add_argument('--ocicl', type=Path)
    parser.add_argument('--wouldwork-source', type=Path,
                        help='Reuse an existing Wouldwork source directory anywhere; no clone/reset')
    parser.add_argument('--test', action='store_true')
    args = parser.parse_args()
    if sys.version_info < (3, 9):
        parser.error('Python 3.9 or newer is required.')
    project = Path(__file__).resolve().parent
    prefix = (args.prefix or project / '.deps').expanduser().resolve()
    sbcl = shutil.which('sbcl')
    if not sbcl or not shutil.which('git'):
        parser.error('Install SBCL and git first, or use setup.sh --install-system.')
    marker = prefix / '.clds-setup'
    if prefix.exists() and not marker.exists() and any(prefix.iterdir()):
        parser.error('Dependency directory is nonempty and not owned by this setup; use a new --prefix.')
    prefix.mkdir(parents=True, exist_ok=True)
    if marker.exists() and marker.read_text() != 'CLDS setup environment v1\n':
        parser.error('Unknown setup marker; refusing to overwrite this environment.')
    marker.write_text('CLDS setup environment v1\n')
    env = dict(os.environ, XDG_DATA_HOME=str(prefix / 'ocicl-data'), OCICL_LOCAL_ONLY='1')
    env.pop('OCICL_SYSTEMS_DIR', None)  # Force all downloaded trees into this prefix.
    selected = args.ocicl.expanduser().resolve() if args.ocicl else shutil.which('ocicl')
    if selected and usable_ocicl(selected):
        ocicl = selected
    elif args.ocicl:
        parser.error('The specified ocicl cannot start or is older than 2.20.0. Rebuild it against your current SBCL.')
    else:
        ocicl = build_ocicl(prefix, sbcl, env)
    print(f'Dependency directory: {prefix}', flush=True)
    run([str(ocicl), 'setup'], cwd=prefix, env=env)
    manifest = prefix / 'ocicl.csv'
    if manifest.exists() and manifest.read_text() != (project / 'ocicl.csv').read_text():
        parser.error('Dependency lock differs from this checkout; use a new --prefix to install it.')
    if not manifest.exists():
        shutil.copyfile(project / 'ocicl.csv', manifest)
    run([str(ocicl), 'install'], cwd=prefix, env=env)
    wouldwork = args.wouldwork_source.expanduser().resolve() if args.wouldwork_source else None
    if args.wouldwork_source:
        if not (wouldwork / 'wouldwork.asd').is_file():
            parser.error('--wouldwork-source must contain wouldwork.asd.')
    loader = configure_loader(project, prefix, wouldwork)
    # Verify dependency loading before reporting success, even without the full suite.
    sbcl_script(sbcl, f'(load {lisp_string(loader)})\n(clds-demo::worker-arguments)\n', prefix,
                cwd=prefix, env=env)
    if args.test:
        run([sys.executable, '-m', 'unittest', 'discover', '-s', str(project / 'tests'),
             '-p', 'test_*.py'], cwd=prefix, env=env)
        sbcl_script(sbcl, f'''
(require :asdf)
(asdf:initialize-output-translations
 '(:output-translations (t {lisp_string(str(prefix / 'cache') + '/')}) :ignore-inherited-configuration))
(load {lisp_string(loader)})
(asdf:test-system "declarative-analysis")
''', prefix, cwd=prefix, env=env)
    print(f'\nSetup complete. In SBCL: (load {lisp_string(loader)})')
    print('(clds-demo:propose clds-demo:*example-study* :analysis)')
    print('(format t "~A" (clds-demo:report clds-demo:*example-study*))')


if __name__ == '__main__':
    try:
        main()
    except (RuntimeError, OSError, subprocess.TimeoutExpired) as error:
        raise SystemExit(f'Setup failed: {error}')
