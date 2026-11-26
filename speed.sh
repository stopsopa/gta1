
#
# Shows or sets the game speed limit of the WINDOWS builds (win-classic-*.sh).
#
# The Windows build draws through cnc-ddraw, and cnc-ddraw can cap how many
# game ticks per second the game is allowed to do - setting "maxgameticks" in
#   gta-classic/games/GTA/GTA/gtawin/ddraw.ini
# Lower value = slower game. This script only edits that one line.
# Both gtawin.exe (GTA1) and gta_uk.exe (London 1969) read the same file.
# The change applies the next time the game is started.
#
# It does nothing for the DOS launchers (dos-*.sh, max-wine-menu.sh).
#
# Normally not called by hand: "xx speed <value>" stores the value in env var
# GTA_SPEED of your terminal, and the win-*.sh launchers call this script with
# it right before starting the game.
#
# Usage (from any directory):
#   /bin/bash gta1_rerun/speed.sh          show current setting
#   /bin/bash gta1_rerun/speed.sh 30       cap at 30 ticks per second
#   /bin/bash gta1_rerun/speed.sh 25       cap at 25 (try 60 / 30 / 25 / 20 / 15)
#   /bin/bash gta1_rerun/speed.sh default  STANDARD: remove the line, the game keeps its own timing
#                                          (this is what cnc-ddraw ships for GTA - its built-in
#                                          preset for the game sets no speed cap)
#   /bin/bash gta1_rerun/speed.sh off      no cap at all (as fast as the game wants)
#   /bin/bash gta1_rerun/speed.sh screen   cap at the refresh rate of the screen
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

INI="${_DIR}/gta-classic/games/GTA/GTA/gtawin/ddraw.ini"

if [[ ! -f "${INI}" ]]; then
  echo "${0} error: ddraw.ini not found INI=>${INI}<, start the game once first: /bin/bash ${_DIR}/win-classic-gta1.sh"
  exit 1
fi

CURRENT="$(tr -d '\r' < "${INI}" | grep -E '^maxgameticks=' | head -n 1 | cut -d= -f2)"

ARG="${1}"

if [[ -z "${ARG}" ]]; then
  cat <<EEE

file    : ${INI}
current : maxgameticks=>${CURRENT}<   (empty = not set = standard)

values  : default standard - no line in the file, the game keeps its own timing
          1-1000  game ticks per second, lower = slower (try 60 / 30 / 25 / 20 / 15)
          off     no cap
          screen  cap at the refresh rate of the screen

set     : /bin/bash ${_DIR}/${_0} 30

EEE
  exit 0
fi

case "${ARG}" in
  default)
    VALUE=""
    ;;
  off)
    VALUE="-1"
    ;;
  screen)
    VALUE="-2"
    ;;
  *)
    if [[ ! "${ARG}" =~ ^[0-9]+$ ]] || (( ARG < 1 || ARG > 1000 )); then
      echo "${0} error: wrong value ARG=>${ARG}<, allowed: number 1-1000, default, off, screen"
      exit 1
    fi
    VALUE="${ARG}"
    ;;
esac

# drop the old line (if any) and put the new one right under the [ddraw] header
TMP="$(mktemp)"

awk -v value="${VALUE}" '
  /^maxgameticks=/ { next }
  { print }
  /^\[ddraw\]/ && value != "" { print "maxgameticks=" value }
' "${INI}" > "${TMP}"

if [[ -n "${VALUE}" && -z "$(grep -E '^maxgameticks=' "${TMP}")" ]]; then
  rm -f "${TMP}"
  echo "${0} error: no [ddraw] section found in INI=>${INI}<, nothing changed"
  exit 1
fi

cat "${TMP}" > "${INI}"
rm -f "${TMP}"

cat <<EEE

maxgameticks: >${CURRENT}< -> >${VALUE}<
file        : ${INI}

Restart the game to apply.

EEE
