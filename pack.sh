
#
# Chops files which are too big for git hosting (GitHub refuses files above 100mb)
# into chunks, and glues them back.
#
#   pack   - finds every file bigger than CHUNK (from .env next to this script,
#            the .git directory is skipped), adds each of them to .gitignore (once),
#            writes chunks [file].001 [file].002 ... next to the file and removes
#            the file. After pack there are only chunks.
#   unpack - finds every [file].001 and glues [file].001 [file].002 ... back into [file].
#            The chunks stay (git status stays clean: the chunks are there and the
#            files are in .gitignore). With --delete the chunks are removed.
#
# Usage (from any directory):
#   /bin/bash pack.sh pack
#   /bin/bash pack.sh unpack
#   /bin/bash pack.sh unpack --delete
#
# .env:
#   CHUNK=45mb      # units: b, kb, mb, gb (1kb = 1024b), no unit means bytes
#
# There is no manifest, the chunks are all there is. How unpack knows what to do:
#   - a group of chunks is: [file].001 and then every next number as long as it exists
#   - there have to be at least 2 chunks (pack never makes one), so a lone file which
#     just happens to be called something.001 is reported and left alone
#   - every chunk but the last has to have the size of .001, the last can't be bigger
#     and there can't be a chunk with a number after a gap (a missing chunk in the middle)
#   If any of this is not true for a group, the group is not touched and the script
#   ends with an error after processing the other groups.
#   What can NOT be detected: lost last chunk(s) - the remaining ones still look like
#   a complete group. git will not lose a file on its own, so it is accepted.
#
# When [file] and its chunks both exist (the state after unpack without --delete):
#   pack   - chunks are the same as the file: only the file is removed.
#            Not the same: the file wins, its chunks are written again
#            (pack is "file -> chunks", old chunks are in git anyway).
#   unpack - chunks are the same as the file: nothing to glue (--delete still removes
#            the chunks). Not the same: error, nothing is touched - remove the one
#            which is wrong.
#
# Both commands can be repeated: pack doesn't see chunks as big files (a chunk is not
# bigger than CHUNK), unpack with no chunks does nothing.
# Each command checks its result (size and cksum for pack, size for unpack) before
# it removes anything.
#
# WARNING: after unpack --delete git sees the chunks as deleted. Run pack before git add / commit.
# Changing CHUNK is fine while packed (unpack doesn't read it), new value is used by next pack.
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

ENV_FILE="${_DIR}/.env"
GITIGNORE="${_DIR}/.gitignore"
MAX_CHUNKS="999"

function usage {
  cat <<EEE

Usage:
  /bin/bash ${_SCRIPT} pack      # big files -> chunks [file].001 [file].002 ... (files removed)
  /bin/bash ${_SCRIPT} unpack    # chunks -> files (chunks stay)
  /bin/bash ${_SCRIPT} unpack --delete    # chunks -> files (chunks removed)

Size of the chunk: CHUNK in ${ENV_FILE} (e.g. CHUNK=45mb)

EEE
}

function size_of {
  wc -c < "${1}" | tr -d '[:space:]'
}

function chunk_name {
  printf '%s.%03d' "${1}" "${2}"
}

# prints all the chunks of ${1} (count ${2}) in order as one stream
function cat_chunks {
  local I="1"
  while [[ "${I}" -le "${2}" ]]; do
    cat "$(chunk_name "${1}" "${I}")" || return 1
    I="$((I + 1))"
  done
}

# prints how many chunks ${1} has, counting from .001 as long as the next number exists
function count_chunks {
  local COUNT="0"
  while [[ -f "$(chunk_name "${1}" "$((COUNT + 1))")" ]]; do
    COUNT="$((COUNT + 1))"
  done
  echo "${COUNT}"
}

# prints how many files look like a chunk of ${1}, gaps in numbering or not
function count_chunk_files {
  ls "${1}".[0-9][0-9][0-9] 2> /dev/null | wc -l | tr -d '[:space:]'
}

function remove_chunks {
  local I="1"
  while [[ "${I}" -le "${2}" ]]; do
    rm -f "$(chunk_name "${1}" "${I}")"
    I="$((I + 1))"
  done
}

# sets CHUNK_BYTES from CHUNK in .env
function read_chunk {
  if [[ ! -f "${ENV_FILE}" ]]; then
    echo "${0} error: file with CHUNK not found ENV_FILE=>${ENV_FILE}<"
    exit 1
  fi

  CHUNK="$(grep -E '^[[:space:]]*CHUNK=' "${ENV_FILE}" | tail -n 1 | cut -d= -f2- | tr -d "\"'[:space:]" | tr '[:upper:]' '[:lower:]')"

  local NUMBER="${CHUNK%%[a-z]*}"
  local UNIT="${CHUNK#"${NUMBER}"}"
  local MULTIPLIER=""

  case "${UNIT}" in
    ""|b) MULTIPLIER="1" ;;
    k|kb) MULTIPLIER="1024" ;;
    m|mb) MULTIPLIER="$((1024 * 1024))" ;;
    g|gb) MULTIPLIER="$((1024 * 1024 * 1024))" ;;
  esac

  if [[ -z "${MULTIPLIER}" || ! "${NUMBER}" =~ ^[1-9][0-9]*$ ]]; then
    echo "${0} error: can't understand CHUNK=>${CHUNK}< from ${ENV_FILE}, expected e.g. CHUNK=45mb (units: b, kb, mb, gb)"
    exit 1
  fi

  CHUNK_BYTES="$((NUMBER * MULTIPLIER))"
}

# adds /${1} to .gitignore, unless it is already there
function gitignore_add {
  # the leading / pins the entry to this exact path, special characters of gitignore are escaped
  local ENTRY="/$(printf '%s' "${1}" | sed 's/[][*?\\]/\\&/g')"

  if [[ -f "${GITIGNORE}" ]]; then
    if grep -Fxq -- "${ENTRY}" "${GITIGNORE}"; then
      return 0
    fi
    # no new line at the end of the file: add one, to not glue the entry to the last line
    if [[ -n "$(tail -c 1 "${GITIGNORE}")" ]]; then
      echo "" >> "${GITIGNORE}"
    fi
  fi

  echo "${ENTRY}" >> "${GITIGNORE}"
  echo "  .gitignore: added ${ENTRY}"
}

function pack_file {
  local FILE="${1}"
  local SIZE="$(size_of "${FILE}")"
  local COUNT="$(( (SIZE + CHUNK_BYTES - 1) / CHUNK_BYTES ))"

  if [[ "${COUNT}" -gt "${MAX_CHUNKS}" ]]; then
    echo "${0} error: FILE=>${FILE}< (${SIZE} bytes) would need ${COUNT} chunks, the limit is ${MAX_CHUNKS}, increase CHUNK=>${CHUNK}<"
    return 1
  fi

  local OLD_FILES="$(count_chunk_files "${FILE}")"

  if [[ "${OLD_FILES}" != "0" ]]; then
    # the state after unpack without --delete: the file and its chunks
    local OLD_COUNT="$(count_chunks "${FILE}")"

    if [[ "${OLD_COUNT}" = "${OLD_FILES}" && "$(cat_chunks "${FILE}" "${OLD_COUNT}" | cksum)" = "$(cksum < "${FILE}")" ]]; then
      echo "  ${FILE} (${SIZE} bytes): its ${OLD_COUNT} chunks are already there and the same, removing the file"
      rm "${FILE}"
      return "${?}"
    fi

    echo "  ${FILE}: existing chunks are not the same as the file, writing them again"
    rm -f "${FILE}".[0-9][0-9][0-9]
  fi

  echo "  ${FILE} (${SIZE} bytes) -> ${COUNT} chunks"

  local I="1"
  while [[ "${I}" -le "${COUNT}" ]]; do
    # bs = whole chunk: skip counts in chunks and one block is exactly one chunk
    if ! dd if="${FILE}" of="$(chunk_name "${FILE}" "${I}")" bs="${CHUNK_BYTES}" skip="$((I - 1))" count="1" 2> /dev/null; then
      remove_chunks "${FILE}" "${I}"
      echo "${0} error: writing chunk ${I} of FILE=>${FILE}< failed, chunks removed, the file is untouched"
      return 1
    fi
    I="$((I + 1))"
  done

  if [[ "$(cat_chunks "${FILE}" "${COUNT}" | cksum)" != "$(cksum < "${FILE}")" ]]; then
    remove_chunks "${FILE}" "${COUNT}"
    echo "${0} error: chunks of FILE=>${FILE}< glued together are not the same as the file, chunks removed, the file is untouched"
    return 1
  fi

  rm "${FILE}"
}

function pack {
  read_chunk

  cd "${_DIR}" || exit 1

  # chunks are never bigger than CHUNK, so they are not found here
  local LIST="$(find . -name .git -prune -o -type f -size +"${CHUNK_BYTES}"c -print | sed 's#^\./##' | sort)"

  if [[ -z "${LIST}" ]]; then
    echo "pack: no files bigger than CHUNK=>${CHUNK}< (${CHUNK_BYTES} bytes) in ${_DIR}"
    return 0
  fi

  echo "pack: CHUNK=>${CHUNK}< (${CHUNK_BYTES} bytes)"

  local FILE=""
  local FAILED="0"

  # IFS= : take the line as it is, file names can have spaces
  while IFS= read -r FILE; do
    gitignore_add "${FILE}"
  done <<< "${LIST}"

  while IFS= read -r FILE; do
    if ! pack_file "${FILE}"; then
      FAILED="1"
    fi
  done <<< "${LIST}"

  if [[ "${FAILED}" = "1" ]]; then
    echo "${0} error: pack: not everything was packed, see errors above"
    exit 1
  fi

  echo "pack: done"
}

function unpack_file {
  local FILE="${1}"
  local COUNT="$(count_chunks "${FILE}")"

  if [[ "${COUNT}" -lt "2" ]]; then
    echo "${0} error: FILE=>${FILE}.001< has no ${FILE}.002: not chunks made by pack, or the rest is lost. Left alone"
    return 1
  fi

  local FOUND="$(count_chunk_files "${FILE}")"

  if [[ "${FOUND}" != "${COUNT}" ]]; then
    echo "${0} error: chunks of FILE=>${FILE}< are numbered 001..$(printf '%03d' "${COUNT}") but there are ${FOUND} of them, a chunk in the middle is missing. Left alone"
    return 1
  fi

  local FIRST="$(size_of "${FILE}.001")"
  local TOTAL="0"
  local SIZE=""
  local I="1"
  while [[ "${I}" -le "${COUNT}" ]]; do
    SIZE="$(size_of "$(chunk_name "${FILE}" "${I}")")"
    if [[ "${I}" -lt "${COUNT}" && "${SIZE}" != "${FIRST}" ]] || [[ "${SIZE}" -gt "${FIRST}" || "${SIZE}" = "0" ]]; then
      echo "${0} error: chunk $(chunk_name "${FILE}" "${I}") has ${SIZE} bytes, not matching the first chunk (${FIRST} bytes): damaged or not chunks made by pack. Left alone"
      return 1
    fi
    TOTAL="$((TOTAL + SIZE))"
    I="$((I + 1))"
  done

  if [[ -e "${FILE}" ]]; then
    if [[ "$(size_of "${FILE}")" != "${TOTAL}" || "$(cat_chunks "${FILE}" "${COUNT}" | cksum)" != "$(cksum < "${FILE}")" ]]; then
      echo "${0} error: FILE=>${FILE}< exists and is not the same as its ${COUNT} chunks glued together, can't tell which one is current, remove the wrong one. Nothing touched"
      return 1
    fi
    echo "  ${FILE} (${TOTAL} bytes) is already there and the same as its ${COUNT} chunks"
  else
    echo "  ${COUNT} chunks -> ${FILE} (${TOTAL} bytes)"

    local TMP="${FILE}.unpack.tmp"

    if ! cat_chunks "${FILE}" "${COUNT}" > "${TMP}" || [[ "$(size_of "${TMP}")" != "${TOTAL}" ]]; then
      rm -f "${TMP}"
      echo "${0} error: gluing chunks of FILE=>${FILE}< failed, chunks are untouched"
      return 1
    fi

    mv "${TMP}" "${FILE}" || return 1
  fi

  if [[ "${DELETE}" = "1" ]]; then
    remove_chunks "${FILE}" "${COUNT}"
    echo "    ${COUNT} chunks removed"
  fi
}

function unpack {
  cd "${_DIR}" || exit 1

  local LIST="$(find . -name .git -prune -o -type f -name '*.001' -print | sed 's#^\./##' | sort)"

  if [[ -z "${LIST}" ]]; then
    echo "unpack: no chunks (*.001) in ${_DIR}"
    return 0
  fi

  if [[ "${DELETE}" = "1" ]]; then
    echo "unpack: (--delete: chunks will be removed)"
  else
    echo "unpack: (chunks stay, add --delete to remove them)"
  fi

  local FIRST_CHUNK=""
  local FAILED="0"

  while IFS= read -r FIRST_CHUNK; do
    if ! unpack_file "${FIRST_CHUNK%.001}"; then
      FAILED="1"
    fi
  done <<< "${LIST}"

  if [[ "${FAILED}" = "1" ]]; then
    echo "${0} error: unpack: not everything was unpacked, see errors above"
    exit 1
  fi

  echo "unpack: done"
}

case "${1}" in
  pack)
    pack
    ;;
  unpack)
    DELETE="0"
    case "${2}" in
      "") ;;
      --delete) DELETE="1" ;;
      *)
        usage
        echo "${0} error: unknown option of unpack =>${2}<, the only one is --delete"
        exit 1
        ;;
    esac
    unpack
    ;;
  *)
    usage
    echo "${0} error: first argument has to be 'pack' or 'unpack', given =>${1}<"
    exit 1
    ;;
esac
