
#
# MAX pack: its own menu (GTA1 / London 1969 / London 1961, normal and 3dfx)
# running in the DOSBox that is bundled with the pack. That DOSBox is a Windows
# program ("Grand Theft Auto.exe"), so it runs through Wine - this is what
# ReRun was doing. Slower route than the dos-max-*.sh launchers (DOS inside
# DOSBox inside Wine), but needs no native DOSBox.
# Display settings: gta-max/dosbox.conf ([sdl] fullscreen=...).
# The menu's own options "Direct3D" / "Restore" rewrite gta-max/dosbox.conf and
# take effect on the next start through this script.
#
# Usage (from any directory):
#   /bin/bash gta1_rerun/max-wine-menu.sh
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

if [[ ! -f "${_DIR}/gta-max/Grand Theft Auto.exe" ]]; then
  echo "${0} error: MAX pack not found GAME=>${_DIR}/gta-max/Grand Theft Auto.exe<, the MAX pack folder gta-max is expected in ${_DIR}"
  exit 1
fi

if [[ -z "${WINE_BIN}" ]]; then
  WINE_BIN="$(command -v wine)"
fi

if [[ -z "${WINE_BIN}" || ! -x "${WINE_BIN}" ]]; then
  echo "${0} error: Wine not found WINE_BIN=>${WINE_BIN}<, run first: /bin/bash ${_DIR}/install.sh"
  exit 1
fi

if [[ -z "${WINEPREFIX}" ]]; then
  WINEPREFIX="${_DIR}/.wine-prefix"
fi
export WINEPREFIX
export WINEDEBUG="${WINEDEBUG:--all}"

# The pack's dosbox.conf has core=auto, which makes DOSBox use its "dynamic"
# CPU core (it generates machine code on the fly) the moment a game starts.
# Under Homebrew Wine 11 on Apple silicon that crashes right after choosing
# a game from the menu. core=normal (plain interpreter) does not crash, so we
# run from a temporary copy of the config with that one line changed - the
# pack's own dosbox.conf is left untouched.
# Other core can be tried with env var GTA_DOSBOX_CORE (normal | simple | dynamic | auto).
CORE="${GTA_DOSBOX_CORE:-normal}"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

sed -e "s/^core=.*/core=${CORE}/" "${_DIR}/gta-max/dosbox.conf" > "${TMP_DIR}/dosbox.conf"

if [[ -z "$(grep -E "^core=${CORE}" "${TMP_DIR}/dosbox.conf")" ]]; then
  echo "${0} error: could not set core=>${CORE}< in a copy of ${_DIR}/gta-max/dosbox.conf (no core= line found)"
  exit 1
fi

# DOSBox mounts "." as C:, so it has to start in the pack's folder
cd "${_DIR}/gta-max" || exit 1

CONF_WIN="$("${WINE_BIN}" winepath -w "${TMP_DIR}/dosbox.conf" 2> /dev/null | tr -d '\r')"

if [[ -z "${CONF_WIN}" ]]; then
  echo "${0} error: could not translate config path for Wine CONF=>${TMP_DIR}/dosbox.conf<"
  exit 1
fi

cat <<EEE

DOSBox CPU core: ${CORE}   (config: temporary copy of gta-max/dosbox.conf)

EEE

WINEDLLOVERRIDES="winemenubuilder.exe=" "${WINE_BIN}" "Grand Theft Auto.exe" -conf "${CONF_WIN}"
