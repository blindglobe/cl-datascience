# Copyright (c) 2026 Gwang Jin Kim. SPDX-License-Identifier: MIT.
"""Offline installer safety tests: python3 -m unittest discover -s tests -p 'test_*.py'."""
import importlib.util
import os
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch

PROJECT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('clds_setup', PROJECT / 'setup.py')
setup = importlib.util.module_from_spec(spec)
spec.loader.exec_module(setup)


class SetupChecks(unittest.TestCase):
    def test_reuse_exact_checkout_never_runs_mutating_git_commands(self):
        with tempfile.TemporaryDirectory() as temporary:
            destination = Path(temporary)
            (destination / '.git').mkdir()
            with patch.object(setup, 'run', side_effect=[setup.WOULDWORK_REVISION + '\n', '']) as run:
                setup.checkout(setup.WOULDWORK_URL, setup.WOULDWORK_REVISION, destination)
            self.assertEqual(2, run.call_count)
            self.assertEqual(['rev-parse', 'status'], [call.args[0][3] for call in run.call_args_list])

    def test_changed_checkout_is_refused_without_resetting_it(self):
        with tempfile.TemporaryDirectory() as temporary:
            destination = Path(temporary)
            (destination / '.git').mkdir()
            with patch.object(setup, 'run', side_effect=[setup.WOULDWORK_REVISION, ' M src/problem.lisp']):
                with self.assertRaisesRegex(RuntimeError, 'local changes'):
                    setup.checkout(setup.WOULDWORK_URL, setup.WOULDWORK_REVISION, destination)

    def test_unrelated_existing_directory_is_never_overwritten(self):
        with tempfile.TemporaryDirectory() as temporary:
            destination = Path(temporary)
            note = destination / 'personal.txt'
            note.write_text('keep me')
            with patch.object(setup, 'run') as run:
                with self.assertRaisesRegex(RuntimeError, 'Refusing to overwrite'):
                    setup.checkout(setup.WOULDWORK_URL, setup.WOULDWORK_REVISION, destination)
                run.assert_not_called()
            self.assertEqual('keep me', note.read_text())

    def test_failed_fetch_leaves_no_partial_checkout(self):
        with tempfile.TemporaryDirectory() as temporary:
            destination = Path(temporary) / 'wouldwork'
            with patch.object(setup, 'run', side_effect=RuntimeError('network unavailable')):
                with self.assertRaises(RuntimeError):
                    setup.checkout(setup.WOULDWORK_URL, setup.WOULDWORK_REVISION, destination)
            self.assertFalse(destination.exists())
            self.assertEqual([], list(Path(temporary).iterdir()))

    def test_old_or_broken_ocicl_is_rejected(self):
        with patch.object(setup, 'run', return_value='ocicl version: v2.3.4'):
            self.assertFalse(setup.usable_ocicl('ocicl'))
        with patch.object(setup, 'run', side_effect=RuntimeError('saved image mismatch')):
            self.assertFalse(setup.usable_ocicl('ocicl'))
        with patch.object(setup, 'run', return_value='ocicl version: v2.17.0'):
            self.assertTrue(setup.usable_ocicl('ocicl'))

    def test_paths_remain_literal_lisp_data(self):
        self.assertEqual('"a \\"quoted\\" path\\\\é"', setup.lisp_string('a "quoted" path\\é'))

    def test_reject_bad_options_before_any_os_installation(self):
        result = subprocess.run(['bash', str(PROJECT / 'setup.sh'), '--install-system', '--typo'],
                                capture_output=True, text=True)
        self.assertNotEqual(0, result.returncode)
        self.assertIn('Unknown option', result.stderr)

    def test_help_needs_no_installed_tools(self):
        # Bash itself is invoked by absolute path, and help must not run any installers.
        result = subprocess.run(['/bin/bash', str(PROJECT / 'setup.sh'), '--help'],
                                env=dict(os.environ, PATH='/nonexistent'), capture_output=True, text=True)
        self.assertEqual(0, result.returncode)
        self.assertIn('--install-system', result.stdout)

    def test_linux_apt_command_selection_without_touching_os(self):
        self.check_native_selection('Linux', 'apt-get', ['update', 'install -y sbcl python3 git curl tar ca-certificates'])

    def test_macos_brew_command_selection_without_touching_os(self):
        self.check_native_selection('Darwin', 'brew', ['install sbcl'])

    def check_native_selection(self, platform, manager, expected):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            log = root / 'commands.log'
            def executable(name, body):
                target = root / name
                target.write_text('#!/bin/bash\n' + body + '\n')
                target.chmod(0o755)
            executable('dirname', 'echo "' + str(PROJECT) + '"')
            executable('uname', f'echo {platform}')
            executable('id', 'echo 0')
            executable('python3', 'exit 0')  # Avoid running the Python installer.
            for name in ['git', 'curl', 'tar']:
                executable(name, 'exit 0')
            if platform == 'Linux':
                executable('sbcl', 'exit 0')
            executable(manager, f'echo "$*" >> "{log}"\n'
                       f'echo \'#!/bin/bash\' > "{root / "sbcl"}"\n'
                       f'/bin/chmod +x "{root / "sbcl"}"')
            result = subprocess.run(['/bin/bash', str(PROJECT / 'setup.sh'), '--install-system'],
                                    env=dict(os.environ, PATH=str(root)), capture_output=True, text=True)
            self.assertEqual(0, result.returncode, result.stderr)
            self.assertEqual(expected, log.read_text().splitlines())


if __name__ == '__main__':
    unittest.main()
