
#
# Classic release: GTA1 - Windows build (gtawin.exe) in Wine, no DOSBox (see _wine.sh).
#
# Usage (from any directory):
#   /bin/bash gta1_rerun/win-classic-gta1.sh             borderless full screen
#   /bin/bash gta1_rerun/win-classic-gta1.sh --window    normal window, mouse stays free
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

/bin/bash "${_DIR}/_wine.sh" "${_DIR}/gta-classic/games/GTA/GTA" "gtawin.exe" "${1}"
