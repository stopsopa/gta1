
#
# Engine script: runs one Windows build of GTA (gtawin.exe / gta_uk.exe)
# through Wine - no DOSBox, no ReRun. Not meant to be called by hand - the
# win-*.sh launchers next to this file call it with the right arguments.
#
# Usage:
#   /bin/bash _wine.sh <game_dir> <exe> [--window]
#
#   game_dir  folder that contains gtawin and gtadata side by side
#   exe       executable inside gtawin, e.g. gtawin.exe
#   --window  normal macOS window (movable, resizable, mouse stays free)
#             instead of borderless full screen
#
# Without --window the mode comes from env var GTA_DISPLAY (window | fullscreen,
# set with "xx display"), and is full screen when that is not set either.
#
# Needs Wine in PATH (brew install --cask wine-stable). Other binary can be
# forced with env var WINE_BIN.
#
# What it does before starting the game:
#   - uses its own Wine prefix in .wine-prefix next to this script
#     (created on first run, takes a minute; override with env var WINEPREFIX)
#   - imports the registry keys the game needs ("Please run Settings first"
#     otherwise) - only once per prefix, so changed controls are kept
#   - makes sure cnc-ddraw (ddraw.dll + ddraw.ini) sits next to the exe.
#     Without it the game shows a black screen on modern systems.
#   - display mode: writes fullscreen / devmode (and a first window size) to
#     ddraw.ini according to --window
#   - game speed: when env var GTA_SPEED is set (xx speed <value>), writes it
#     to ddraw.ini through speed.sh. Then shows the speed that will be used and
#     waits for Enter (Esc or Ctrl+C stops, so the value can be changed and the
#     launcher started again). No waiting when not run from a terminal.
#     ddraw.ini is only created when missing.
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

GAME_DIR="${1}"
EXE="${2}"
# display mode: argument --window wins, then env var GTA_DISPLAY (xx display), then full screen
MODE="fullscreen"
MODE_FROM="default, GTA_DISPLAY not set"
if [[ "${3}" == "--window" ]]; then
  MODE="window"
  MODE_FROM="argument --window"
elif [[ -n "${3}" ]]; then
  echo "${0} error: unknown argument ARG=>${3}<, allowed: --window"
  exit 1
elif [[ "${GTA_DISPLAY}" == "window" || "${GTA_DISPLAY}" == "fullscreen" ]]; then
  MODE="${GTA_DISPLAY}"
  MODE_FROM="env var GTA_DISPLAY=>${GTA_DISPLAY}<"
elif [[ -n "${GTA_DISPLAY}" ]]; then
  echo "${0} error: wrong env var GTA_DISPLAY=>${GTA_DISPLAY}<, allowed: window, fullscreen"
  exit 1
fi

# sets key=value in the [ddraw] section of given ini file (replaces existing line)
function set_ini {
  local FILE="${1}" KEY="${2}" VALUE="${3}" TMP
  TMP="$(mktemp)"
  awk -v key="${KEY}" -v value="${VALUE}" '
    index($0, key "=") == 1 { next }
    { print }
    /^\[ddraw\]/ { print key "=" value }
  ' "${FILE}" > "${TMP}"
  cat "${TMP}" > "${FILE}"
  rm -f "${TMP}"
}

if [[ -z "${GAME_DIR}" || -z "${EXE}" ]]; then
  echo "${0} error: usage: /bin/bash ${_0} <game_dir> <exe>"
  exit 1
fi

if [[ ! -d "${GAME_DIR}/" ]]; then
  echo "${0} error: game folder not found GAME_DIR=>${GAME_DIR}<, the game folder gta-classic is expected in ${_DIR}"
  exit 1
fi

GTAWIN="$(find -L "${GAME_DIR}" -maxdepth 1 -iname gtawin | head -n 1)"
if [[ -z "${GTAWIN}" || ! -f "${GTAWIN}/${EXE}" ]]; then
  echo "${0} error: executable not found EXE=>${EXE}< in gtawin folder of GAME_DIR=>${GAME_DIR}<"
  exit 1
fi

# ---- find Wine ------------------------------------------------------------

if [[ -z "${WINE_BIN}" ]]; then
  WINE_BIN="$(command -v wine)"
fi

if [[ -z "${WINE_BIN}" || ! -x "${WINE_BIN}" ]]; then
  cat <<EEE

${0} error: Wine not found WINE_BIN=>${WINE_BIN}<

Install it (on this Mac, any terminal):

  brew install --cask wine-stable

or point env var WINE_BIN to an existing wine binary.

EEE
  exit 1
fi

if [[ -z "${WINEPREFIX}" ]]; then
  WINEPREFIX="${_DIR}/.wine-prefix"
fi
export WINEPREFIX
export WINEDEBUG="${WINEDEBUG:--all}"

# ---- cnc-ddraw next to the exe --------------------------------------------

if [[ ! -f "${GTAWIN}/ddraw.dll" ]]; then
  DDRAW_SRC="${_DIR}/gta-max/cnc-ddraw/cnc-ddraw/ddraw.dll"
  if [[ ! -f "${DDRAW_SRC}" ]]; then
    echo "${0} error: cnc-ddraw not found DDRAW_SRC=>${DDRAW_SRC}<, download ddraw.dll from https://github.com/FunkyFr3sh/cnc-ddraw/releases and put it in GTAWIN=>${GTAWIN}<"
    exit 1
  fi
  cp "${DDRAW_SRC}" "${GTAWIN}/ddraw.dll"
fi

if [[ ! -f "${GTAWIN}/ddraw.ini" ]]; then
  cat > "${GTAWIN}/ddraw.ini" <<EEE
[ddraw]
windowed=true
fullscreen=true
maintas=true
renderer=opengl
singlecpu=false
adjmouse=true
EEE
fi

# ---- registry (once per prefix) -------------------------------------------

MARKER="${WINEPREFIX}/.gta-registry-imported"

if [[ ! -f "${MARKER}" ]]; then

  cat <<EEE

Preparing Wine prefix (first run only, takes a minute): ${WINEPREFIX}

EEE

  mkdir -p "${WINEPREFIX}"

  REG="${WINEPREFIX}/gta.reg"

  # the game is 32-bit, so in a 64-bit prefix it reads the Wow6432Node branch
  cat > "${REG}" <<EEE
REGEDIT4

[HKEY_LOCAL_MACHINE\\Software\\Wow6432Node\\DMA Design\\Grand Theft Auto]
"Language"=dword:00000000
"Path"="."
"Installed"=dword:00000001

[HKEY_LOCAL_MACHINE\\Software\\Wow6432Node\\DMA Design\\Grand Theft Auto\\1.00.000]

[HKEY_LOCAL_MACHINE\\Software\\Wow6432Node\\DMA Design\\Grand Theft Auto\\Controls]
"Control 0"=dword:000000cb
"Control 1"=dword:000000cd
"Control 2"=dword:000000c8
"Control 3"=dword:000000d0
"Control 4"=dword:00000039
"Control 5"=dword:0000001c
"Control 6"=dword:0000001d
"Control 7"=dword:0000002d
"Control 8"=dword:0000002c
"Control 9"=dword:0000000f
EEE

  "${WINE_BIN}" regedit /S "${REG}"
  CODE="${?}"

  if [[ "${CODE}" != "0" ]]; then
    echo "${0} error: importing registry failed CODE=>${CODE}< REG=>${REG}< WINEPREFIX=>${WINEPREFIX}<"
    exit 1
  fi

  touch "${MARKER}"
fi

# ---- display mode ---------------------------------------------------------
# windowed=true stays in both modes:
#   fullscreen=true   borderless window stretched over the whole screen
#   fullscreen=false  normal window
# devmode=true means cnc-ddraw does not lock the mouse cursor inside the game
# (GTA is played with the keyboard only), so other windows can be clicked.

set_ini "${GTAWIN}/ddraw.ini" "windowed" "true"

if [[ "${MODE}" == "window" ]]; then
  set_ini "${GTAWIN}/ddraw.ini" "fullscreen" "false"
  set_ini "${GTAWIN}/ddraw.ini" "devmode" "true"
  # first time only: start with a 2x window, later cnc-ddraw remembers the size you drag it to
  if [[ -z "$(tr -d '\r' < "${GTAWIN}/ddraw.ini" | grep -E '^width=')" ]]; then
    set_ini "${GTAWIN}/ddraw.ini" "width" "1600"
    set_ini "${GTAWIN}/ddraw.ini" "height" "1200"
  fi
  MODE_HUMAN="window (drag / resize it like any window, mouse is not captured)"
else
  set_ini "${GTAWIN}/ddraw.ini" "fullscreen" "true"
  set_ini "${GTAWIN}/ddraw.ini" "devmode" "false"
  MODE_HUMAN="full screen (borderless)"
fi

# ---- game speed (two stages: "xx speed <value>" sets GTA_SPEED, we apply it)

if [[ -n "${GTA_SPEED}" ]]; then
  /bin/bash "${_DIR}/speed.sh" "${GTA_SPEED}" > /dev/null
  CODE="${?}"
  if [[ "${CODE}" != "0" ]]; then
    echo "${0} error: applying game speed failed CODE=>${CODE}< GTA_SPEED=>${GTA_SPEED}<, allowed: number 1-1000, default, off, screen"
    exit 1
  fi
  SPEED_FROM="env var GTA_SPEED=>${GTA_SPEED}<"
else
  SPEED_FROM="GTA_SPEED not set, kept what is in ddraw.ini"
fi

TICKS="$(tr -d '\r' < "${GTAWIN}/ddraw.ini" | grep -E '^maxgameticks=' | head -n 1 | cut -d= -f2)"

case "${TICKS}" in
  "")  SPEED_HUMAN="standard - no cap line in ddraw.ini, the game keeps its own timing" ;;
  -1)  SPEED_HUMAN="no cap" ;;
  -2)  SPEED_HUMAN="refresh rate of the screen" ;;
  0)   SPEED_HUMAN="emulated 60hz" ;;
  *)   SPEED_HUMAN="${TICKS} ticks per second" ;;
esac

cat <<EEE

display    : ${MODE_HUMAN}
             (${MODE_FROM})
             leave the game without closing it: Cmd+Tab or Mission Control (Ctrl+Up),
             Alt(Option)+Enter switches window / full screen while playing

game speed : ${SPEED_HUMAN}
             (${SPEED_FROM})

to change  : stop here with Esc (or Ctrl+C), then
               xx speed 25        (try 60 / 30 / 25 / 20 / 15, lower = slower)
               xx display window  (or: xx display fullscreen)
             and start this command again
EEE

# wait for confirmation only when a human is at the keyboard
if [[ -t 0 ]]; then
  echo ""
  printf "Press Enter to start the game (Esc or Ctrl+C to stop)... "
  # one key at a time, without waiting for Enter: Enter starts, Esc stops, other keys are ignored
  while true; do
    KEY=""
    if ! IFS= read -r -s -n 1 KEY; then
      # end of input (Ctrl+D)
      echo ""
      echo "${0}: stopped, the game was not started"
      exit 0
    fi
    if [[ -z "${KEY}" ]]; then
      echo ""
      break
    fi
    if [[ "${KEY}" = $'\033' ]]; then
      echo ""
      echo "${0}: stopped with Esc, the game was not started"
      exit 0
    fi
  done
fi

# ---- run ------------------------------------------------------------------

cat <<EEE

Wine   : ${WINE_BIN}
prefix : ${WINEPREFIX}
exe    : ${GTAWIN}/${EXE}

EEE

# the game finds its data through ..\\gtadata, so it has to start in gtawin
cd "${GTAWIN}" || exit 1

WINEDLLOVERRIDES="ddraw=n,b;winemenubuilder.exe=" "${WINE_BIN}" "${EXE}"
