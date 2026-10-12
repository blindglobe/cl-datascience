#!/usr/bin/env bash
# Copyright (c) 2026 Gwang Jin Kim. SPDX-License-Identifier: MIT.
set -euo pipefail
case "${BASH_SOURCE[0]}" in
  */*) setup_directory="${BASH_SOURCE[0]%/*}" ;;
  *) setup_directory=. ;;
esac
setup_directory="$(cd -- "$setup_directory" && pwd)"
install_system=0
setup_arguments=("$@")
while [[ $# -gt 0 ]]; do
  case "$1" in
    --install-system) install_system=1; shift ;;
    --test) shift ;;
    --prefix|--ocicl)
      if [[ $# -lt 2 ]]; then echo "Missing value for $1." >&2; exit 1; fi
      shift 2 ;;
    -h|--help)
      while IFS= read -r help_line; do printf '%s\n' "$help_line"; done <<'HELP'
Usage: bash setup.sh [--install-system] [--prefix DIR] [--ocicl PATH] [--test]

Installs locked Lisp dependencies and a pinned Wouldwork into .deps/ by default.
Uses a working ocicl on PATH, or builds a pinned ocicl locally with SBCL.
--install-system installs missing OS tools using Homebrew, apt, dnf, pacman,
                 or zypper. Homebrew must already be installed on macOS.
--prefix DIR     Use a different dependency directory; a loader is generated there.
--ocicl PATH     Use this ocicl executable (fail if it cannot start).
--test           Run the full Lisp package suite after setup.

Required OS tools: SBCL, Python 3.9+, git, curl, tar and CA certificates.
No shell/Lisp startup files are edited. No persistent processes are started.
HELP
      exit 0 ;;
    *) echo "Unknown option: $1. Use --help." >&2; exit 1 ;;
  esac
done

if [[ "$install_system" == 1 ]]; then
  case "$(uname -s)" in
    Darwin)
      if ! command -v brew >/dev/null 2>&1; then
        echo "Install Homebrew first: https://brew.sh/ (follow its PATH instructions)." >&2
        exit 1
      fi
      packages=()
      command -v sbcl >/dev/null 2>&1 || packages+=(sbcl)
      command -v python3 >/dev/null 2>&1 || packages+=(python)
      command -v git >/dev/null 2>&1 || packages+=(git)
      command -v curl >/dev/null 2>&1 || packages+=(curl)
      if [[ "${packages[*]-}" != "" ]]; then brew install "${packages[@]}"; fi
      ;;
    Linux)
      use_sudo=0
      if [[ "$(id -u)" != 0 ]]; then
        command -v sudo >/dev/null 2>&1 || { echo "OS installation needs sudo or root." >&2; exit 1; }
        use_sudo=1
      fi
      elevated() {
        if [[ "$use_sudo" == 1 ]]; then sudo "$@"; else "$@"; fi
      }
      if command -v apt-get >/dev/null 2>&1; then
        elevated apt-get update
        elevated apt-get install -y sbcl python3 git curl tar ca-certificates
      elif command -v dnf >/dev/null 2>&1; then
        elevated dnf install -y sbcl python3 git curl tar ca-certificates
      elif command -v pacman >/dev/null 2>&1; then
        elevated pacman -S --needed --noconfirm sbcl python git curl tar ca-certificates
      elif command -v zypper >/dev/null 2>&1; then
        elevated zypper --non-interactive install sbcl python3 git curl tar ca-certificates
      else
        echo "Install sbcl, python3, git, curl, tar and CA certificates with your distribution's package manager." >&2
        exit 1
      fi
      ;;
    *) echo "Supported hosts: macOS and Linux." >&2; exit 1 ;;
  esac
fi

for tool in python3 sbcl git curl tar; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "Missing $tool. Run with --install-system, or install the required tools manually." >&2
    exit 1
  fi
done
if [[ ${#setup_arguments[@]} -gt 0 ]]; then
  exec python3 "$setup_directory/setup.py" "${setup_arguments[@]}"
else
  exec python3 "$setup_directory/setup.py"
fi
