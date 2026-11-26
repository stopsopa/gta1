
#
# Engine script: runs one DOS build of GTA in a native macOS DOSBox
# (no Wine, no ReRun). Not meant to be called by hand - the dos-*.sh
# launchers next to this file call it with the right arguments.
#
# Usage:
#   /bin/bash _dosbox.sh <c_drive_dir> <exe> <cd1|-> <cd2|-> [--window]
#
#   c_drive_dir  host folder mounted as C: (must contain GTADOS and GTADATA)
#   exe          executable inside GTADOS, e.g. GTA24.EXE
#   cd1, cd2     CD images (.cue or the pack's CDAUDIO.DAT) mounted as D: and E:,
#                "-" to skip. They provide the radio music.
#   --window     run in a window instead of full screen
#
# Needs DOSBox Staging (preferred) or DOSBox-X:
#   brew install dosbox-staging
# Other binary can be forced with env var DOSBOX_BIN.
#
# 3dfx builds (*FX*.EXE) need the real Voodoo driver glide2x.ovl. It is taken
# from the MAX pack (gta-max/glide2x_emu.ovl) and put on the DOS PATH through
# a temporary G: drive, so no game folder is modified for that.
#
# The game itself writes into its own folder (GTADATA/PLAYER_A.DAT, swap file).
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

C_DIR="${1}"
EXE="${2}"
CD1="${3}"
CD2="${4}"
FULLSCREEN="true"
if [[ "${5}" == "--window" ]]; then
  FULLSCREEN="false"
fi

if [[ -z "${C_DIR}" || -z "${EXE}" ]]; then
  echo "${0} error: usage: /bin/bash ${_0} <c_drive_dir> <exe> <cd1|-> <cd2|-> [--window]"
  exit 1
fi

if [[ ! -d "${C_DIR}/" ]]; then
  echo "${0} error: game folder not found C_DIR=>${C_DIR}<, the game folders gta-max and gta-classic are expected in ${_DIR}"
  exit 1
fi

# GTADOS can be upper or lower case on disk
GTADOS="$(find -L "${C_DIR}" -maxdepth 1 -iname gtados | head -n 1)"
if [[ -z "${GTADOS}" || -z "$(find -L "${GTADOS}" -maxdepth 1 -iname "${EXE}")" ]]; then
  echo "${0} error: executable not found EXE=>${EXE}< in GTADOS folder of C_DIR=>${C_DIR}<"
  exit 1
fi

# ---- find DOSBox ----------------------------------------------------------

if [[ -z "${DOSBOX_BIN}" ]]; then
  for CANDIDATE in \
    "$(command -v dosbox)" \
    "$(command -v dosbox-staging)" \
    "/Applications/DOSBox Staging.app/Contents/MacOS/dosbox" \
    "$(command -v dosbox-x)" \
    "/Applications/dosbox-x.app/Contents/MacOS/dosbox-x"
  do
    if [[ -n "${CANDIDATE}" && -x "${CANDIDATE}" ]]; then
      DOSBOX_BIN="${CANDIDATE}"
      break
    fi
  done
fi

if [[ -z "${DOSBOX_BIN}" || ! -x "${DOSBOX_BIN}" ]]; then
  cat <<EEE

${0} error: DOSBox not found DOSBOX_BIN=>${DOSBOX_BIN}<

Install one (on this Mac, any terminal):

  brew install dosbox-staging

or point env var DOSBOX_BIN to an existing dosbox binary.

EEE
  exit 1
fi

# ---- temporary config -----------------------------------------------------

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

CONF="${TMP_DIR}/dosbox.conf"

# DOSBox-X and DOSBox Staging name the cpu speed setting differently
if [[ "$(basename "${DOSBOX_BIN}")" == "dosbox-x" ]]; then
  CPU_LINE="cycles=max"
else
  CPU_LINE="cpu_cycles_protected=max"
fi

cat > "${CONF}" <<EEE
[sdl]
fullscreen=${FULLSCREEN}

[dosbox]
machine=svga_s3
memsize=32

[cpu]
core=auto
${CPU_LINE}

[sblaster]
sbtype=sb16
sbbase=220
irq=7
dma=1
hdma=5

[autoexec]
@echo off
mount c "${C_DIR}"
EEE

if [[ -n "${CD1}" && "${CD1}" != "-" ]]; then
  if [[ ! -f "${CD1}" ]]; then
    echo "${0} error: CD image not found CD1=>${CD1}<"
    exit 1
  fi
  echo "imgmount d \"${CD1}\" -t cdrom" >> "${CONF}"
fi

if [[ -n "${CD2}" && "${CD2}" != "-" ]]; then
  if [[ ! -f "${CD2}" ]]; then
    echo "${0} error: CD image not found CD2=>${CD2}<"
    exit 1
  fi
  echo "imgmount e \"${CD2}\" -t cdrom" >> "${CONF}"
fi

# 3dfx build: provide the real Voodoo glide2x.ovl on the PATH
EXE_LOWER="$(echo "${EXE}" | tr '[:upper:]' '[:lower:]')"
if [[ "${EXE_LOWER}" == *fx* ]]; then
  GLIDE_SRC="${_DIR}/gta-max/glide2x_emu.ovl"
  if [[ ! -f "${GLIDE_SRC}" ]]; then
    echo "${0} error: 3dfx build needs the Voodoo driver, not found GLIDE_SRC=>${GLIDE_SRC}<, it comes with the MAX pack folder gta-max expected in ${_DIR}"
    exit 1
  fi
  mkdir -p "${TMP_DIR}/glide"
  cp "${GLIDE_SRC}" "${TMP_DIR}/glide/GLIDE2X.OVL"
  cat >> "${CONF}" <<EEE
mount g "${TMP_DIR}/glide"
set PATH=G:\\;Z:\\
EEE
fi

cat >> "${CONF}" <<EEE
c:
cd \\GTADOS
${EXE}
exit
EEE

cat <<EEE

DOSBox : ${DOSBOX_BIN}
C:     : ${C_DIR}
exe    : GTADOS\\${EXE}
CD D:  : ${CD1}
CD E:  : ${CD2}
full   : ${FULLSCREEN}   (Alt+Enter toggles full screen)

EEE

"${DOSBOX_BIN}" -conf "${CONF}"
