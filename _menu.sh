
#
# Engine script: small arrow-key menu for the terminal.
# Draws the list on the terminal itself (/dev/tty), prints ONLY the chosen
# value to stdout - so it can be used like:
#
#   VALUE="$(/bin/bash _menu.sh "Game speed" "30" "60::60 ticks" "30::30 ticks" "off::no cap")"
#
# Usage:
#   /bin/bash _menu.sh <title> <current_value> <value::label> [<value::label> ...]
#
#   title          line printed above the list
#   current_value  option with this value is marked "(current)" and preselected
#   value::label   one option: what is printed to stdout :: what the user sees
#
# Keys: up/down or left/right arrows (also k/j) move, Enter confirms,
#       q or Esc cancels.
# Exit code: 0 = chosen (value on stdout), 1 = cancelled or no terminal.
#
# Used by "xx speed" and "xx display" (see xx.ts), which are sourced in the
# user's shell (bash or zsh) - that is why the key handling lives here, in a
# separate /bin/bash process, and not in the sourced code.
#

TITLE="${1}"
CURRENT="${2}"

if [[ "${#}" -lt 3 ]]; then
  echo "${0} error: usage: /bin/bash _menu.sh <title> <current_value> <value::label> [<value::label> ...]" >&2
  exit 1
fi

shift 2

if [[ ! -r /dev/tty || ! -w /dev/tty ]]; then
  echo "${0} error: no terminal available (/dev/tty), menu needs a keyboard" >&2
  exit 1
fi

VALUES=()
LABELS=()
SELECTED="0"
I="0"
for OPTION in "${@}"; do
  VALUES+=("${OPTION%%::*}")
  LABELS+=("${OPTION#*::}")
  if [[ "${OPTION%%::*}" == "${CURRENT}" ]]; then
    SELECTED="${I}"
  fi
  I="$((I + 1))"
done
COUNT="${#VALUES[@]}"

BOLD=$'\033[1m'
GREEN=$'\033[32m'
GRAY=$'\033[38;5;244m'
REVERSE=$'\033[7m'
RESET=$'\033[0m'

# everything visible goes to the terminal, stdout is reserved for the result
exec 3> /dev/tty

function cleanup {
  printf '\033[?25h' >&3 # show cursor again
}
trap cleanup EXIT
trap 'exit 1' INT TERM

printf '\033[?25l' >&3 # hide cursor

function draw {
  local I MARK NOTE
  for (( I = 0; I < COUNT; I++ )); do
    NOTE=""
    if [[ "${VALUES[${I}]}" == "${CURRENT}" ]]; then
      NOTE=" ${GRAY}(current)${RESET}"
    fi
    if [[ "${I}" == "${SELECTED}" ]]; then
      printf '\r\033[K  %s> %s%s%s%s\n' "${GREEN}" "${REVERSE}" " ${LABELS[${I}]} " "${RESET}" "${NOTE}" >&3
    else
      printf '\r\033[K     %s%s\n' "${LABELS[${I}]}" "${NOTE}" >&3
    fi
  done
}

printf '\n  %s%s%s\n  %s%s%s\n\n' "${BOLD}" "${TITLE}" "${RESET}" "${GRAY}" "arrows = move, Enter = confirm, q / Esc = cancel" "${RESET}" >&3

draw

while true; do
  KEY=""
  IFS= read -rsn1 KEY < /dev/tty

  case "${KEY}" in
    "")
      # Enter
      break
      ;;
    q|Q)
      printf '\n' >&3
      exit 1
      ;;
    k|K)
      SELECTED="$(( (SELECTED - 1 + COUNT) % COUNT ))"
      ;;
    j|J)
      SELECTED="$(( (SELECTED + 1) % COUNT ))"
      ;;
    $'\033')
      # arrow keys arrive as ESC [ A/B/C/D, lonely Esc has nothing after it
      REST=""
      IFS= read -rsn2 -t 1 REST < /dev/tty
      case "${REST}" in
        "[A"|"OA"|"[D"|"OD")
          SELECTED="$(( (SELECTED - 1 + COUNT) % COUNT ))"
          ;;
        "[B"|"OB"|"[C"|"OC")
          SELECTED="$(( (SELECTED + 1) % COUNT ))"
          ;;
        "")
          printf '\n' >&3
          exit 1
          ;;
      esac
      ;;
  esac

  # move back to the first row of the list and paint it again
  printf '\033[%sA' "${COUNT}" >&3
  draw
done

printf '\n' >&3

echo "${VALUES[${SELECTED}]}"
