
#
# Classic release: London 1969, 24-bit colour, music from the CD image - DOS build in native DOSBox (see _dosbox.sh). --window runs it in a window.
#
# Usage (from any directory):
#   /bin/bash gta1_rerun/dos-classic-london69-24bit.sh [--window]
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

/bin/bash "${_DIR}/_dosbox.sh" "${_DIR}/gta-classic/games/GTA/GTA" "GTA24_UK.EXE" "${_DIR}/gta-classic/games/GTA/cd/GTA.cue" "${_DIR}/gta-classic/games/GTA/cd/GTALONDON.cue" "${1}"
