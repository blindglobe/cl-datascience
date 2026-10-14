# SBCL, ocicl and ASDF setup

Copyright (c) 2026 Gwang Jin Kim. SPDX-License-Identifier: MIT.

The example and Wouldwork can live in any directories. **ASDF locates the
systems; ocicl installs Lisp libraries.** There is no assumed author-specific
home directory, repository layout, or Quicklisp installation location.
Both the REPL and isolated planner use SBCL.

## Install ocicl on macOS

Install [Homebrew](https://brew.sh/) first if needed, and follow its displayed
PATH instructions. Then run:

```sh
brew install sbcl ocicl python git
ocicl version
ocicl setup
```

`brew install ocicl` is the command documented by
[Homebrew](https://formulae.brew.sh/formula/ocicl). `ocicl setup` installs its
runtime and prints suggested SBCL startup configuration; see
[ocicl's Homebrew instructions](https://github.com/ocicl/ocicl#homebrew).
For this example, the generated ASDF registry handles source discovery, so
editing `~/.sbclrc` is optional.

## Install ocicl on Debian

Install the base tools:

```sh
sudo apt-get update
sudo apt-get install -y sbcl python3 git curl tar ca-certificates
```

For **Debian amd64/x86_64**, the official ocicl project provides an apt
repository. Register its signing key and repository, then install ocicl:

```sh
curl -fsSL https://ocicl.github.io/ocicl/deb-repo/ocicl-archive-keyring.gpg \
  | sudo tee /usr/share/keyrings/ocicl-archive-keyring.asc >/dev/null
printf '%s\n' \
  'deb [signed-by=/usr/share/keyrings/ocicl-archive-keyring.asc] https://ocicl.github.io/ocicl/deb-repo stable main' \
  | sudo tee /etc/apt/sources.list.d/ocicl.list >/dev/null
sudo apt-get update
sudo apt-get install -y ocicl
ocicl version
ocicl setup
```

These follow the [official ocicl Debian/Ubuntu instructions](https://github.com/ocicl/ocicl#linux-packages).
`stable` above names the ocicl repository channel, not a Debian release codename.

For Debian arm64, or if you prefer not to add the apt repository, the example's
setup script builds pinned ocicl 2.20.0 locally when a compatible ocicl is not
available. Install the base tools above, then run the example setup below.
The source build uses your installed SBCL and the dependencies bundled in the
pinned official source tree. No additional ocicl system repository is needed.

## Get and set up the example

Clone the example branch into any directory you choose:

```sh
git clone --branch example/declarative-analysis-mini-package \
  https://github.com/gwangjinkim/cl-datascience.git
cd cl-datascience
bash examples/declarative-analysis/setup.sh --test
```

The script restores the committed `ocicl.csv`, including Wouldwork, through ocicl,
and writes an ASDF source-registry initializer. It reuses a working ocicl 2.20.0+
or builds pinned 2.20.0 locally. Quicklisp is not required.

If OS tools are missing, pass `--install-system` to install them using Homebrew
on macOS or apt on Debian. Homebrew must already be available. Linux dnf,
pacman and zypper command selection is also supported.

```sh
bash examples/declarative-analysis/setup.sh --install-system --test
```

Network access to GitHub and ocicl's OCI registry is needed for downloads.
The ocicl source build reserves 3 GiB of SBCL dynamic address space and can take
several minutes. Python 3.9+ is required for setup and the isolated launcher.

## Install Wouldwork through ocicl

The setup script's `ocicl install` restores **both Wouldwork and its libraries**
from `ocicl.csv`. There is no separate manual clone step for Wouldwork.

To install the tested Wouldwork revision yourself, change to your chosen ocicl
project directory and run:

```sh
ocicl install 'git+https://github.com/davypough/wouldwork.git@1d4e764633365ff5f7c187b94e98c1f8f09ed2fd'
```

Ocicl 2.20.0 supports this [Git-source installation syntax](https://github.com/ocicl/ocicl#installing-systems-from-git).
It fetches the source, resolves dependencies and records the exact commit in
`ocicl.csv`, alongside registry artifacts for the libraries. The example's
committed lockfile already records that installation; `ocicl install` with no
arguments restores it. The pin selects the version tested with this adapter.

ASDF finds the resulting `wouldwork.asd` through normal source discovery or
ocicl's ASDF hook. It does not need to know an author-specific repository path.
The example intentionally loads Wouldwork only in its temporary worker, since
reading the installed `.asd` can initialize working files in its source tree.

## Put the repositories wherever you want

Use a separate dependency directory, and optionally reuse a Wouldwork checkout
in another location:

```sh
bash examples/declarative-analysis/setup.sh \
  --prefix /your/chosen/dependency-directory \
  --wouldwork-source /your/chosen/wouldwork-directory \
  --test
```

The paths are choices supplied by the installer, not fixed runtime defaults.
`--wouldwork-source` reuses a directory containing `wouldwork.asd`; it does not
reset, pull, or modify that checkout. Without it, ocicl installs the pinned Wouldwork entry from the lockfile into
its managed source tree in the selected dependency directory.

The generated loader registers relative directories with ASDF and calls
`asdf:load-system`. It does not embed absolute author paths or set a fixed
Wouldwork runtime directory. It supports moving the whole installation while
preserving the relative layout; if repositories are moved independently,
update their ASDF registration or rerun setup to refresh that registration.

If ASDF already knows your systems and libraries, use it directly:

```lisp
(require :asdf)
(asdf:load-system "declarative-analysis")
(defparameter experiment (clds-demo:demo))
(clds-demo:propose experiment :analysis)
(format t "~A" (clds-demo:report experiment))
```

If necessary, register directories in the current SBCL session. Substitute your
own locations; ASDF's normal persistent source-registry configuration also works:

```lisp
(asdf:initialize-source-registry
 '(:source-registry
   (:directory "/your/cl-datascience/examples/declarative-analysis/")
   (:directory "/your/wouldwork/")
   (:tree "/your/installed/lisp-libraries/")
   :inherit-configuration))
```

If you already use ocicl or Quicklisp, their ASDF discovery hooks can supply the
library locations. The runtime resolves the transitive library dependency plan
through ASDF and passes those actual source directories to the clean worker.
No dependency-manager startup file is assumed or required by that worker.

## Load the generated setup

The script prints its generated loader path. With the default dependency directory:

```sh
sbcl --load examples/declarative-analysis/.deps/load.lisp
```

At the prompt:

```lisp
(in-package :clds-demo)
(configure *example-study* :goal :design :assumptions)
(propose *example-study* :analysis)
(format t "~A" (report *example-study*))
(asdf:test-system "declarative-analysis")
```

`examples/try-declarative-analysis.lisp` also reads the default generated ASDF
registry when present. Loading the grammar itself needs only SBCL and ASDF.
The planner libraries are needed when proposals or full tests are requested.

## What is installed, and where?

Default dependency directory: `examples/declarative-analysis/.deps/`.
Use `--prefix` to change it.

| Component | Location |
|---|---|
| SBCL, Python, Git, curl, tar, certificates | Homebrew prefix or Linux package directories |
| ocicl executable | Existing PATH executable, or selected prefix's `tools/bin/ocicl` |
| Local ocicl build sources, when needed | Selected prefix's `tools/ocicl-source/` |
| ocicl setup/configuration | Selected prefix's `ocicl-data/ocicl/` |
| Downloaded Lisp libraries | Selected prefix's `ocicl/` |
| Installed dependency lock | Selected prefix's `ocicl.csv` |
| Wouldwork source | ASDF resolves its ocicl-managed source tree; an explicitly reused checkout may live anywhere |
| Setup/test compilation cache | Selected prefix's `cache/` |
| Generated loader and ASDF registry | Selected prefix's `load.lisp` and `dependencies.lisp` |

The ocicl lockfile pins Wouldwork to commit `1d4e764633365ff5f7c187b94e98c1f8f09ed2fd`.
An explicitly supplied existing checkout can have another version; the adapter
must be compatible with that version. ASDF chooses the source it actually
registers. `clds-demo:*wouldwork-source*` is an optional explicit override for
special cases; its normal default is NIL, meaning ASDF discovery.

Reading Wouldwork's `.asd` can initialize writable working files. The runtime
uses `asdf:locate-system` to find that definition without evaluating it, then
loads only an isolated temporary copy. Workers use the caller's SBCL executable
and an ASDF registry made from the resolved library directories. They do not
load the caller's Lisp startup file or download packages while searching.

Commit `ocicl.csv`, not `.deps/` or downloaded trees. No shell/Lisp startup files
are edited automatically. No persistent planner, server or watcher is started.
Setup waits for commands and cleans temporary bootstrap/download directories on
failure. Completed downloads and installed OS packages remain reusable.

## Reruns, tests and standalone runner

Reruns reuse locked libraries and unchanged pinned sources, and refuse to reset
tracked changes or overwrite unrelated nonempty directories. Use a fresh prefix
if the installed lock differs from the current checkout. `--ocicl /path/to/ocicl`
selects a compatible executable explicitly. Otherwise an unusable or old ocicl
triggers a local build, including saved-image mismatches after an SBCL upgrade.

`--test` runs 11 offline installer checks and 37 Lisp checks (29 domain checks
and 8 package checks). These test actual Wouldwork search, configuration state,
ASDF source lookup and worker isolation; they do not qualify numerical inference.

```sh
python3 -m unittest discover -s examples/declarative-analysis/tests -p 'test_*.py'
python3 examples/declarative-analysis/run-grammar.py --check
```

The standalone runner discovers sources through SBCL/ASDF, using the default
generated loader when present. With a custom setup, pass
`--dependency-setup /your/ASDF-registry-initializer.lisp`. An explicit
`--quicklisp /your/Quicklisp-setup.lisp` can initialize an existing Quicklisp
ASDF environment. There is no guessed Quicklisp path. An already-running Lisp
session can use its in-memory ASDF registry directly through `propose`.

Verification: all 48 checks passed on macOS with actual ocicl 2.20.0
installation of Wouldwork from the lockfile. The full Lisp suite also passed with
the example, Wouldwork and
libraries in separate arbitrary directories, followed by a real proposal after
moving the generated setup. Installer checks cover mocked Homebrew/apt command
selection. Debian installation instructions were checked against upstream docs;
end-to-end Debian installation has not been run here.
