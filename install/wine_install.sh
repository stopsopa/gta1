
#
# Installs Wine ("Wine Stable.app") without Homebrew.
#
# Why not brew: the cask wine-stable was disabled in Homebrew on 2026-09-01
# ("does not pass the macOS Gatekeeper check" - the build is not signed by an
# Apple developer id), so "brew install --cask wine-stable" fails on every new
# machine. That cask was only downloading the archive below, so this script
# does the same by hand:
#   - downloads the official WineHQ macOS build (packaged by Gcenx, the same
#     file the cask was pointing to) - 11.0_1, the version these launchers
#     were tested with
#   - checks its sha256 (the value the cask had)
#   - unpacks "Wine Stable.app" to /Applications (or ~/Applications when
#     /Applications is not writable)
#   - removes the quarantine flag, so macOS does not block the unsigned app
#
# No symlink in PATH is created - wine_find.sh knows where the app is.
# Safe to run again - does nothing when the app is already there.
#
# Usage (from any directory):
#   /bin/bash install/wine_install.sh
#
# Other build can be forced with env vars WINE_URL and WINE_SHA256.
#

RED=$'\033[31m'
GREEN=$'\033[32m'
YELLOW=$'\033[33m'
RESET=$'\033[0m'

if [[ -z "${WINE_URL}" ]]; then
  WINE_URL="https://github.com/Gcenx/macOS_Wine_builds/releases/download/11.0_1/wine-stable-11.0_1-osx64.tar.xz"
  WINE_SHA256="b50dc50ec7f41d58b115a6b685d4d1315ba3c797bd3aa0f49213f2703cb82388"
fi

APP="Wine Stable.app"
BIN_IN_APP="Contents/Resources/wine/bin/wine"

for CANDIDATE in "/Applications" "${HOME}/Applications"; do
  if [[ -x "${CANDIDATE}/${APP}/${BIN_IN_APP}" ]]; then
    echo "${GREEN}ok${RESET}       Wine already installed (${CANDIDATE}/${APP})"
    exit 0
  fi
done

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "${0} error: this installs the macOS build of Wine, but this system is OS=>$(uname -s)<"
  exit 1
fi

TARGET_DIR="/Applications"
if [[ ! -w "${TARGET_DIR}" ]]; then
  TARGET_DIR="${HOME}/Applications"
  mkdir -p "${TARGET_DIR}"
fi

if [[ -e "${TARGET_DIR}/${APP}" ]]; then
  echo "${0} error: incomplete Wine found, no wine binary inside APP=>${TARGET_DIR}/${APP}<, remove that folder and run this again"
  exit 1
fi

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

cat <<EEE

${YELLOW}download${RESET} Wine (about 200 MB)
  from: ${WINE_URL}
  to  : ${TARGET_DIR}/${APP}

EEE

curl -fL --progress-bar -o "${TMP_DIR}/wine.tar.xz" "${WINE_URL}"
CODE="${?}"
if [[ "${CODE}" != "0" ]]; then
  echo "${0} error: download failed CODE=>${CODE}< WINE_URL=>${WINE_URL}<"
  exit 1
fi

if [[ -n "${WINE_SHA256}" ]]; then
  SUM="$(shasum -a 256 "${TMP_DIR}/wine.tar.xz" | cut -d' ' -f1)"
  if [[ "${SUM}" != "${WINE_SHA256}" ]]; then
    echo "${0} error: checksum of the downloaded file is wrong SUM=>${SUM}< expected WINE_SHA256=>${WINE_SHA256}<, nothing installed"
    exit 1
  fi
  echo "${GREEN}ok${RESET}       sha256 matches"
else
  echo "${YELLOW}warning${RESET}  WINE_SHA256 is empty, the download is not verified"
fi

mkdir "${TMP_DIR}/unpacked"
tar -xf "${TMP_DIR}/wine.tar.xz" -C "${TMP_DIR}/unpacked"
CODE="${?}"
if [[ "${CODE}" != "0" ]]; then
  echo "${0} error: unpacking failed CODE=>${CODE}< FILE=>${TMP_DIR}/wine.tar.xz<"
  exit 1
fi

if [[ ! -x "${TMP_DIR}/unpacked/${APP}/${BIN_IN_APP}" ]]; then
  echo "${0} error: archive does not contain the expected app APP=>${APP}< (found: $(ls "${TMP_DIR}/unpacked" | tr '\n' ' '))"
  exit 1
fi

# curl does not set it, but make sure: with this flag macOS refuses an unsigned app
xattr -dr com.apple.quarantine "${TMP_DIR}/unpacked/${APP}" 2> /dev/null

mv "${TMP_DIR}/unpacked/${APP}" "${TARGET_DIR}/${APP}"
CODE="${?}"
if [[ "${CODE}" != "0" ]]; then
  echo "${0} error: could not move the app to TARGET_DIR=>${TARGET_DIR}< CODE=>${CODE}<"
  exit 1
fi

VERSION="$("${TARGET_DIR}/${APP}/${BIN_IN_APP}" --version 2> /dev/null)"
if [[ -z "${VERSION}" ]]; then
  cat <<EEE

${RED}${0} error: Wine was unpacked but does not start BIN=>${TARGET_DIR}/${APP}/${BIN_IN_APP}<${RESET}

Most likely one of:
  - Rosetta 2 is missing (Apple silicon):  softwareupdate --install-rosetta --agree-to-license
  - macOS blocked it: System Settings -> Privacy & Security -> "Open Anyway"

EEE
  exit 1
fi

echo "${GREEN}ok${RESET}       Wine installed: ${VERSION} (${TARGET_DIR}/${APP})"
