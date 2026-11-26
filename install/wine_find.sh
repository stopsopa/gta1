
#
# Finds the Wine binary for the launchers (_wine.sh, max-wine-menu.sh) and for
# install.sh. One place for the search and for the "how to install Wine" help,
# so every script prints the same instructions.
#
# Prints the path of the wine binary to stdout and exits with 0.
# When Wine is not found: prints what to install to stderr and exits with 1.
#
# Usage:
#   WINE_BIN="$(/bin/bash "${_DIR}/wine_find.sh")" || exit 1
#   /bin/bash install/wine_find.sh --quiet     same, but no help on stderr (install.sh uses it as a test)
#
# Search order:
#   1. env var WINE_BIN (when set, nothing else is tried)
#   2. wine in PATH
#   3. places where Homebrew used to put it (machines that installed it before
#      the cask was disabled)
#   4. "Wine Stable.app" in /Applications and ~/Applications - where
#      wine_install.sh puts it (it creates no symlink in PATH)
#

_SHELL="$(ps -p $$ -o comm=)"; # bash || sh || zsh
_SHELL="$(basename ${_SHELL//-/})"
case ${_SHELL} in
  zsh)
    _DIR="$( cd "$( dirname "${(%):-%x}" )" && pwd -P )"
    _0="$( basename "${(%):-%N}" )"
    _SCRIPT="${(%):-%N}"
    _BINARY="/bin/zsh"
    ;;
  sh)
    # be carefull this will not work when sourcing this file in sh shell
    # will though work when called /bin/sh my_script.sh from any shell
    _DIR="$( cd "$( dirname "${0}" )" && pwd -P )"
    _0="$( basename "${0}" )"
    _SCRIPT="${0}"
    _BINARY="/bin/sh"
    ;;
  *)
    _DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd -P )"
    _0="$( basename "${BASH_SOURCE[0]}" )"
    _SCRIPT="${BASH_SOURCE[0]}"
    _BINARY="/bin/bash"
    ;;
esac
_PWD="$(pwd)"

YELLOW=$'\033[33m'
RED=$'\033[31m'
RESET=$'\033[0m'

GIVEN="${WINE_BIN}"
FOUND=""

if [[ -n "${GIVEN}" ]]; then
  if [[ -x "${GIVEN}" ]]; then
    FOUND="${GIVEN}"
  fi
else
  for CANDIDATE in \
    "$(command -v wine)" \
    "/opt/homebrew/bin/wine" \
    "/usr/local/bin/wine" \
    "/Applications/Wine Stable.app/Contents/Resources/wine/bin/wine" \
    "${HOME}/Applications/Wine Stable.app/Contents/Resources/wine/bin/wine"
  do
    if [[ -n "${CANDIDATE}" && -x "${CANDIDATE}" ]]; then
      FOUND="${CANDIDATE}"
      break
    fi
  done
fi

if [[ -n "${FOUND}" ]]; then
  echo "${FOUND}"
  exit 0
fi

if [[ "${1}" == "--quiet" ]]; then
  exit 1
fi

# ---- not found: say exactly what is missing on this machine ----------------

BREW_BIN="$(command -v brew)"
if [[ -z "${BREW_BIN}" ]]; then
  for CANDIDATE in "/opt/homebrew/bin/brew" "/usr/local/bin/brew"; do
    if [[ -x "${CANDIDATE}" ]]; then
      BREW_BIN="${CANDIDATE}"
      break
    fi
  done
fi

if [[ -n "${BREW_BIN}" ]]; then
  BREW_STATE="found (${BREW_BIN})"
else
  BREW_STATE="${RED}MISSING${RESET}"
fi

ROSETTA_STATE="not needed (Intel Mac)"
if [[ "$(uname -m)" == "arm64" ]]; then
  if /usr/bin/pgrep -q oahd; then
    ROSETTA_STATE="found"
  else
    ROSETTA_STATE="${RED}MISSING${RESET}"
  fi
fi

cat >&2 <<EEE

${RED}${0} error: Wine not found WINE_BIN=>${GIVEN}<${RESET}

On this machine:
  Homebrew : ${BREW_STATE}
  Rosetta 2: ${ROSETTA_STATE}
  Wine     : ${RED}MISSING${RESET}

${YELLOW}Easiest way - one command installs everything that is missing
(Homebrew, Rosetta 2, DOSBox Staging, Wine):${RESET}

  /bin/bash "${_DIR}/install.sh"        (the same as: xx install)

By hand, in this order (skip what is marked "found" above):

  1. Homebrew - https://brew.sh
       /bin/bash -c "\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
     then open a NEW terminal (or do what the installer prints under "Next steps")

  2. Rosetta 2 - Apple silicon only, Wine is Intel code
       softwareupdate --install-rosetta --agree-to-license

  3. Wine - NOT with brew: "brew install --cask wine-stable" fails, Homebrew
     disabled that cask on 2026-09-01 (build not signed, fails Gatekeeper).
     This downloads the same build straight from its source, checks the
     sha256 and puts "Wine Stable.app" in /Applications:
       /bin/bash "${_DIR}/wine_install.sh"

  4. check, it should print the path of wine:
       /bin/bash "${_DIR}/wine_find.sh"

If macOS refuses to open Wine ("cannot be opened" / "unverified developer"):
System Settings -> Privacy & Security -> "Open Anyway", then run the launcher again.

Wine already installed somewhere else? Point env var WINE_BIN to it:
  export WINE_BIN="/path/to/bin/wine"

EEE

exit 1
