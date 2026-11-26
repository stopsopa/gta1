
#
# Installs everything the launchers in this directory need (on this Mac):
#   - Rosetta 2        (Wine and the Windows builds of GTA are Intel code)
#   - DOSBox Staging   (dos-*.sh launchers)       brew formula dosbox-staging
#   - Wine             (win-*.sh, max-wine-*.sh)  _wine_install.sh (direct download,
#                      the brew cask wine-stable is disabled since 2026-09-01)
#
# Needs Homebrew (https://brew.sh) - it is the only thing this script does not
# install itself, it prints the command for it instead.
#
# Safe to run again - things already installed are skipped.
#
# Usage (from any directory):
#   /bin/bash install.sh        (the same as: xx install)
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

GREEN=$'\033[32m'
YELLOW=$'\033[33m'
RESET=$'\033[0m'

# brew can be installed but not in PATH yet (fresh machine, brew shellenv not
# added to the shell profile) - then use it from its standard location
if [[ -z "$(command -v brew)" ]]; then
  for CANDIDATE in "/opt/homebrew/bin/brew" "/usr/local/bin/brew"; do
    if [[ -x "${CANDIDATE}" ]]; then
      eval "$("${CANDIDATE}" shellenv)"
      break
    fi
  done
fi

if [[ -z "$(command -v brew)" ]]; then
  cat <<EEE

${0} error: Homebrew (brew) not found in PATH and not in /opt/homebrew/bin, /usr/local/bin

Install it first (https://brew.sh):

  /bin/bash -c "\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

then open a NEW terminal (or do what the installer prints under "Next steps")
and run this again:

  /bin/bash "${_DIR}/install.sh"

EEE
  exit 1
fi

# ---- Rosetta 2 (Apple silicon only) ---------------------------------------

if [[ "$(uname -m)" == "arm64" ]]; then
  if /usr/bin/pgrep -q oahd; then
    echo "${GREEN}ok${RESET}       Rosetta 2"
  else
    echo "${YELLOW}install${RESET}  Rosetta 2"
    softwareupdate --install-rosetta --agree-to-license
    CODE="${?}"
    if [[ "${CODE}" != "0" ]]; then
      echo "${0} error: installing Rosetta 2 failed CODE=>${CODE}<"
      exit 1
    fi
  fi
fi

# ---- DOSBox Staging -------------------------------------------------------

if [[ -n "$(command -v dosbox)" || -n "$(command -v dosbox-x)" ]]; then
  echo "${GREEN}ok${RESET}       DOSBox ($(command -v dosbox || command -v dosbox-x))"
else
  echo "${YELLOW}install${RESET}  DOSBox Staging"
  brew install dosbox-staging
  CODE="${?}"
  if [[ "${CODE}" != "0" ]]; then
    echo "${0} error: brew install dosbox-staging failed CODE=>${CODE}<"
    exit 1
  fi
fi

# ---- Wine -----------------------------------------------------------------

WINE_FOUND="$(/bin/bash "${_DIR}/_wine_find.sh" --quiet)"

if [[ -n "${WINE_FOUND}" ]]; then
  echo "${GREEN}ok${RESET}       Wine (${WINE_FOUND})"
else
  echo "${YELLOW}install${RESET}  Wine"
  # not with brew: cask wine-stable is disabled since 2026-09-01, see _wine_install.sh
  /bin/bash "${_DIR}/_wine_install.sh"
  CODE="${?}"
  if [[ "${CODE}" != "0" ]]; then
    echo "${0} error: _wine_install.sh failed CODE=>${CODE}<"
    exit 1
  fi
  # prints the full instructions and stops when it is still not there
  WINE_FOUND="$(/bin/bash "${_DIR}/_wine_find.sh")" || exit 1
fi

cat <<EEE

${GREEN}all installed${RESET} - launchers:

$(cd "${_DIR}" && ls dos-*.sh win-*.sh max-wine-*.sh 2>/dev/null | sed 's/^/  \/bin\/bash /')

EEE
