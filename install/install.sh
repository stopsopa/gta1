
#
# Installs everything the launchers in this directory need (on this Mac):
#   - Homebrew         (first, DOSBox Staging comes from it) - its official
#                      installer, asks for the macOS password. Also found
#                      when installed but not in PATH yet.
#   - Rosetta 2        (Wine and the Windows builds of GTA are Intel code)
#   - DOSBox Staging   (dos-*.sh launchers)       brew formula dosbox-staging
#   - Wine             (win-*.sh, max-wine-*.sh)  wine_install.sh (direct download,
#                      the brew cask wine-stable is disabled since 2026-09-01)
#
# Safe to run again - things already installed are skipped.
#
# Usage (from any directory):
#   /bin/bash install/install.sh        (the same as: xx install)
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

# ---- Homebrew --------------------------------------------------------------

# 1 = brew was not in PATH when this script started (reminder printed at the end)
BREW_NOT_IN_PATH="0"
BREW_URL="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"

# brew can be installed but not in PATH (fresh machine, brew shellenv not added
# to the shell profile) - then load it from its standard location
function brew_load {
  if [[ -n "$(command -v brew)" ]]; then
    return 0
  fi
  for CANDIDATE in "/opt/homebrew/bin/brew" "/usr/local/bin/brew"; do
    if [[ -x "${CANDIDATE}" ]]; then
      eval "$("${CANDIDATE}" shellenv)"
      BREW_NOT_IN_PATH="1"
      return 0
    fi
  done
  return 1
}

if brew_load; then
  echo "${GREEN}ok${RESET}       Homebrew ($(command -v brew))"
else
  cat <<EEE

${YELLOW}install${RESET}  Homebrew (https://brew.sh) - its official installer, it will ask
         for your macOS password and for Enter to confirm

EEE
  TMP_BREW="$(mktemp -d)"
  curl -fsSL -o "${TMP_BREW}/install.sh" "${BREW_URL}"
  CODE="${?}"
  if [[ "${CODE}" != "0" ]]; then
    rm -rf "${TMP_BREW}"
    echo "${0} error: downloading the Homebrew installer failed CODE=>${CODE}< BREW_URL=>${BREW_URL}<, check the internet connection"
    exit 1
  fi
  /bin/bash "${TMP_BREW}/install.sh"
  CODE="${?}"
  rm -rf "${TMP_BREW}"
  if [[ "${CODE}" != "0" ]] || ! brew_load; then
    cat <<EEE

${0} error: installing Homebrew failed CODE=>${CODE}< (brew not found in /opt/homebrew/bin, /usr/local/bin)

Install it by hand (https://brew.sh):

  /bin/bash -c "\$(curl -fsSL ${BREW_URL})"

and run this again:

  /bin/bash "${_DIR}/install.sh"

EEE
    exit 1
  fi
  BREW_NOT_IN_PATH="1"
  echo "${GREEN}ok${RESET}       Homebrew installed ($(command -v brew))"
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

WINE_FOUND="$(/bin/bash "${_DIR}/wine_find.sh" --quiet)"

if [[ -n "${WINE_FOUND}" ]]; then
  echo "${GREEN}ok${RESET}       Wine (${WINE_FOUND})"
else
  echo "${YELLOW}install${RESET}  Wine"
  # not with brew: cask wine-stable is disabled since 2026-09-01, see wine_install.sh
  /bin/bash "${_DIR}/wine_install.sh"
  CODE="${?}"
  if [[ "${CODE}" != "0" ]]; then
    echo "${0} error: wine_install.sh failed CODE=>${CODE}<"
    exit 1
  fi
  # prints the full instructions and stops when it is still not there
  WINE_FOUND="$(/bin/bash "${_DIR}/wine_find.sh")" || exit 1
fi

cat <<EEE

${GREEN}all installed${RESET} - launchers:

$(cd "${_DIR}/.." && ls dos-*.sh win-*.sh max-wine-*.sh 2>/dev/null | sed 's/^/  \/bin\/bash /')

EEE

if [[ "${BREW_NOT_IN_PATH}" == "1" ]]; then
  cat <<EEE
${YELLOW}Homebrew is not in PATH of your terminal${RESET} - the launchers here work without
it, but to use "brew" yourself add it once to your shell profile and open a new terminal:

  echo 'eval "\$($(command -v brew) shellenv)"' >> ~/.zprofile

EEE
fi
