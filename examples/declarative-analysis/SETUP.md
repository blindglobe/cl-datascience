# Fresh-machine setup with ocicl

Copyright (c) 2026 Gwang Jin Kim. SPDX-License-Identifier: MIT.

Use **SBCL + ocicl** for this example. Quicklisp is optional. Ocicl downloads
project-local ASDF systems and restores the versions recorded in `ocicl.csv`;
see the [official ocicl documentation](https://github.com/ocicl/ocicl#installing-systems).
Wouldwork is fetched separately at a pinned Git commit because its initializer
writes working files. Searches always use temporary copies of that checkout.

## Get the example

Obtain a checkout or archive containing `examples/declarative-analysis/`.
The example currently lives on branch `example/declarative-analysis-mini-package`.
Once that branch is published on the fork, clone it with:

```sh
git clone --branch example/declarative-analysis-mini-package \
  https://github.com/gwangjinkim/cl-datascience.git
cd cl-datascience
```

Git is needed to clone a repository. A repository archive can be unpacked first
if Git is not installed; the setup script can then install Git with the other
OS tools. A branch existing only on the maintainer's machine must be shared or
pushed before someone else can clone it.

## macOS

Install [Homebrew](https://brew.sh/) first if it is not already available,
and follow its displayed instructions to put `brew` on PATH. Its installer may
also request Apple's command-line developer tools.

From the repository root:

```sh
bash examples/declarative-analysis/setup.sh --install-system --test
```

The script uses Homebrew to install missing SBCL, Python 3, Git and curl.
It reuses ocicl **2.17.0 or newer** when a working executable is on PATH;
otherwise it builds pinned ocicl 2.17.0 locally with your SBCL. You may prefer
to install ocicl through Homebrew yourself:

```sh
brew install sbcl python git ocicl
bash examples/declarative-analysis/setup.sh --test
```

The script runs ocicl's mandatory setup under its own dependency directory;
you do not need to add anything to `~/.sbclrc`. The Homebrew and ocicl procedures
follow their [installation documentation](https://github.com/ocicl/ocicl#homebrew).

## Linux

From the repository root, use the same command:

```sh
bash examples/declarative-analysis/setup.sh --install-system --test
```

It supports `apt-get` (Debian/Ubuntu), `dnf` (Fedora and related distributions),
`pacman` (Arch), or `zypper` (openSUSE). OS package installation uses sudo when
needed and installs SBCL, Python 3, Git, curl, tar and CA certificates. It builds
ocicl locally if no compatible executable is installed, avoiding the need to
add an ocicl package repository. The source build uses the dependencies bundled
in the official pinned ocicl source tree.

For a distribution without those package managers, install the required OS
tools with your distribution's package manager, then run:

```sh
bash examples/declarative-analysis/setup.sh --test
```

The source build targets the machine's native architecture; it is not an
x86-only downloaded executable. Python 3.9+ is required. The ocicl build reserves
3 GiB of SBCL dynamic address space, matching upstream's default; the build can
take several minutes. Network access to GitHub and the ocicl OCI registry is
needed during setup. Registry certificates remain verified.

## What is installed, and where?

Default dependency directory: `examples/declarative-analysis/.deps/`.

| Component | Location | Purpose |
|---|---|---|
| SBCL, Python, Git, curl, tar, certificates | Homebrew prefix or Linux system package directories | OS tools, installed only with `--install-system` |
| ocicl executable | Existing PATH executable, or `.deps/tools/bin/ocicl` | Lisp dependency manager |
| Local ocicl build sources | `.deps/tools/ocicl-source/` when needed | Pinned official source tree |
| ocicl runtime/configuration | `.deps/ocicl-data/ocicl/` | Worker-only ASDF dependency support |
| Lisp libraries | `.deps/ocicl/` | Alexandria, Iterate, Lparallel and transitive dependencies |
| Installed dependency lock | `.deps/ocicl.csv` | Copy of the committed `ocicl.csv` |
| Wouldwork source | `.deps/wouldwork/` | Commit `1d4e764633365ff5f7c187b94e98c1f8f09ed2fd` |
| Setup/build compilation cache | `.deps/cache/` | Compiled Lisp files during setup/tests |
| Generated loader | `.deps/load.lisp` | Load the example and configure worker paths |
| Dependency initializer | `.deps/dependencies.lisp` | Loaded only by isolated workers |

`.deps/` is ignored by Git. Commit `ocicl.csv`, not downloaded source trees.
Proposal workers put their compilation output and Wouldwork working files in
separate temporary directories, which are removed when each request ends.
Ordinary REPL compilation follows the user's ASDF cache settings.

No shell or Lisp startup files are edited. No server, watcher, scheduled task,
or persistent planner is started. The installer waits for commands and cleans
up temporary bootstrap/download directories on failure. Previously installed
OS packages and completed downloads stay available after an interrupted setup.

## Load and try

After default setup, from the repository root:

```sh
sbcl --load examples/declarative-analysis/.deps/load.lisp
```

At the Lisp prompt:

```lisp
(in-package :clds-demo)
(configure *example-study* :goal :design :assumptions)
(propose *example-study* :analysis)
(format t "~A" (report *example-study*))
(asdf:test-system "declarative-analysis")
```

The shorter `examples/try-declarative-analysis.lisp` also discovers the default
`.deps/` environment automatically. Loading the example itself needs only SBCL;
proposing analyses needs a completed dependency setup.

## Reruns, custom directories and tests

Rerunning setup reuses locked library versions and unchanged pinned checkouts.
It refuses to reset tracked changes or replace a nonempty unrelated directory.
If the installed lock differs from the current checkout, use a fresh prefix to
install the new lock. Nothing runs `ocicl latest` or pulls a newer Wouldwork.

```sh
bash examples/declarative-analysis/setup.sh \
  --prefix "$HOME/.local/share/clds-demo" --test
```

The script prints the absolute generated loader path. Load that file for a
custom prefix. `--ocicl /absolute/path/to/ocicl` selects a compatible existing
executable explicitly; if it is broken or too old, setup stops with an error.
Without that option, setup builds a local copy when necessary, including when
a system ocicl saved image no longer matches an updated SBCL.

`--test` runs the offline installer tests and the full Lisp suite. The Lisp suite
checks actual Wouldwork search, grammar/state behavior and worker isolation; it
does not qualify numerical statistical inference. To run just installer checks:

```sh
python3 -m unittest discover -s examples/declarative-analysis/tests -p 'test_*.py'
```

Verification during development: actual ocicl source build, fresh dependency
installation and all 34 Lisp checks passed on macOS, including a custom prefix
with spaces and Unicode. The 10 installer checks include mocked Homebrew and
apt command selection. End-to-end installation on Linux has not been run here.

## Optional Quicklisp fallback

An existing Quicklisp setup and Wouldwork checkout still work. Explicitly pass
`--quicklisp /path/to/setup.lisp` to `run-grammar.py`, or set
`clds-demo:*dependency-setup*` to NIL and `clds-demo:*quicklisp-setup*` to its path.
The fallback needs Alexandria, Iterate and Lparallel installed through Quicklisp.
A new machine using the ocicl setup does not need Quicklisp.
