
#
# Links the game directories into this directory as "gta-max" and "gta-classic"
# (next to this script, no matter where the script is called from).
#
# Usage (from any directory):
#   /bin/bash gta1_rerun/link.sh
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

cd "${_DIR}"

# MAX pack: DOS builds of GTA1, London 1969 and London 1961 (+ bundled Windows DOSBox)
ln -shf "/Users/szdz/Workspace/games/GTA1-MAX (1)" "${_DIR}/gta-max"

# classic release: DOS and Windows builds of GTA1 and London 1969 (+ CD images)
ln -shf "/Users/szdz/Workspace/games/Grand Theft Auto (1997)" "${_DIR}/gta-classic"

