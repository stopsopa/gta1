
#
# Installs everything the launchers in this directory need (on this Mac):
#   - Rosetta 2        (Wine and the Windows builds of GTA are Intel code)
#   - DOSBox Staging   (dos-*.sh launchers)       brew formula dosbox-staging
#   - Wine             (win-*.sh, max-wine-*.sh)  brew cask wine-stable
# and then creates the links to the game folders (link.sh).
#
# Safe to run again - things already installed are skipped.
#
# Usage (from any directory):
#   /bin/bash gta1_rerun/install.sh
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

if [[ -z "$(command -v brew)" ]]; then
  echo "${0} error: Homebrew (brew) not found in PATH, install it first from https://brew.sh"
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

if [[ -n "$(command -v wine)" ]]; then
  echo "${GREEN}ok${RESET}       Wine ($(command -v wine))"
else
  echo "${YELLOW}install${RESET}  Wine"
  brew install --cask wine-stable
  CODE="${?}"
  if [[ "${CODE}" != "0" ]]; then
    echo "${0} error: brew install --cask wine-stable failed CODE=>${CODE}<"
    exit 1
  fi
fi

# ---- links to the game folders --------------------------------------------

/bin/bash "${_DIR}/link.sh"
CODE="${?}"
if [[ "${CODE}" != "0" ]]; then
  echo "${0} error: link.sh failed CODE=>${CODE}<"
  exit 1
fi

cat <<EEE

${GREEN}all installed${RESET} - launchers:

$(cd "${_DIR}" && ls dos-*.sh win-*.sh max-wine-*.sh 2>/dev/null | sed 's/^/  \/bin\/bash /')

EEE
