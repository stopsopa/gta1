// github edit  : https://github.com/stopsopa/xx/edit/main/templates/xx.ts

// in order to run any xx command with custom export env var:
// (shopt -s expand_aliases; export ENVFILE=.env.ci; xx "docker up")

// 🚀 -
// ✅ -
// ⚙️  -
// 🗑️  -
// 🛑 -
// to call other xx commands from inside any xx command use:
//    shopt -s expand_aliases && source ~/.bashrc
// after that just do:
//   xx <command_name>
const S = "\\";
const GRAY = "\x1b[38;5;244m",
  BLACK = "\x1b[30m",
  RED = "\x1b[31m",
  GREEN = "\x1b[32m",
  YELLOW = "\x1b[33m",
  BLUE = "\x1b[34m",
  MAGENTA = "\x1b[35m",
  CYAN = "\x1b[36m",
  WHITE = "\x1b[37m",
  BOLD = "\x1b[1m",
  REVERSE = "\x1b[7m",
  RESET = "\x1b[0m";

const enter = `printf '\n${GREEN}Press Enter to continue (any other key exits)...${RESET}\n';old=$(stty -g);stty -icanon -echo
IFS= read -r -n1 k 2>/dev/null||IFS= read -r k;stty "$old"
[ -n "$k" ]&&exit 0;`;

const esc = `printf '\n${GREEN}Press any key to continue (Esc to exit)...${RESET}\n';old=$(stty -g);stty -icanon -echo
IFS= read -r -n1 k 2>/dev/null||IFS= read -r k;stty "$old"
[ "$k" = "$(printf '\\033')" ]&&exit 0;`;

type Command = {
  // required. Shell script, written to xx_generated.sh and executed with /bin/bash
  command: string;
  // default: name of the command. Shown under the menu for the selected row
  description?: string;
  // default: false = run straight away
  // true = ask "Run command?" first (XX_CONFIRM=false skips the question)
  confirm?: boolean;
  // default: false = executed with /bin/bash as a separate process
  // true = sourced in the current shell (cd, export, source venv/bin/activate stay after it ends)
  source?: boolean;
  // default: 0. Lower goes first: negative = top, positive = bottom
  // commands with the same order stay in the order of this file
  order?: number;
};

type Commands = Record<string, Command>;

type Ctx = {
  // arguments given after the name of the command: xx <name> [args]
  args: string[];
  // directory xx was called in
  cwd: string;
  // path of this file
  configPath: string;
};

export default (setup: Commands, ctx: Ctx): Commands => {
  // games first, ordered from the highest chance to work to the lowest
  return {
    help: {
      command: `
set -e

cat <<EEE

  🐙 GitHub: $(git ls-remote --get-url origin | awk '{\$1=\$1};1' | tr -d '\\n' | sed -E 's/git@github\\.com:([^/]+)\\/(.+)\\.git/https:\\/\\/github.com\\/\\1\\/\\2/g')

  GTA1 / GTA London launchers for this Mac - details in SUMMARY.md

  game folders (next to this file):
    gta-max      MAX pack: DOS builds of GTA1, London 1969, London 1961
    gta-classic  classic release: DOS + Windows builds of GTA1, London 1969

  win ...        Windows build through Wine (cnc-ddraw for graphics)
  dos ...        DOS build in native DOSBox (xx install first)
  max wine menu  the pack's bundled Windows DOSBox through Wine

  display of the Windows build: gta-classic/games/GTA/GTA/gtawin/ddraw.ini
  Wine prefix:                  .wine-prefix (delete it to start clean)

EEE
`,
      description: `what is in this directory`,
    },
    [`speed`]: {
      command: `
# sourced in your shell (source: true), so no "exit" and no "set -e" here
__GTA_ARG="\${1}"
__GTA_OK="0"
if [ -z "\${__GTA_ARG}" ]; then
  cat <<EEE

  Speed is used ONLY by the Windows builds (Wine + cnc-ddraw):
    win gta1 800x600+
    win london69 800x600+
    win gta1 window 800x600+
    win london69 window 800x600+

  NOT affected (they ignore GTA_SPEED):
    max wine menu
    dos ...   (all DOSBox commands: 24bit, 8bit, 3dfx)
EEE
  # arrow-key menu, runs in its own bash process and prints the chosen value
  __GTA_ARG="\$(/bin/bash _menu.sh "Game speed of the Windows builds  (now: GTA_SPEED=>\${GTA_SPEED}<)" "\${GTA_SPEED}" \\
    "default::default - STANDARD: the game keeps its own timing (what cnc-ddraw ships for GTA)" \\
    "60::60 ticks per second  - fastest cap" \\
    "30::30 ticks per second" \\
    "25::25 ticks per second" \\
    "20::20 ticks per second" \\
    "15::15 ticks per second  - slowest" \\
    "off::off     - no cap at all" \\
    "screen::screen  - refresh rate of the screen" \\
    "custom::custom  - type any number 1-1000" \\
    "unset::unset   - forget the value, launchers keep what is in ddraw.ini")"
  if [ "\${__GTA_ARG}" = "custom" ]; then
    printf '  ticks per second (1-1000): '
    read -r __GTA_ARG
  fi
fi
if [ -z "\${__GTA_ARG}" ]; then
  echo "nothing changed, GTA_SPEED=>\${GTA_SPEED}<"
elif [ "\${__GTA_ARG}" = "unset" ]; then
  unset GTA_SPEED
  echo "GTA_SPEED unset"
else
  case "\${__GTA_ARG}" in
    default|off|screen)
      __GTA_OK="1"
      ;;
    *[!0-9]*)
      ;;
    *)
      if [ "\${__GTA_ARG}" -ge 1 ] && [ "\${__GTA_ARG}" -le 1000 ]; then
        __GTA_OK="1"
      fi
      ;;
  esac
  if [ "\${__GTA_OK}" = "1" ]; then
    export GTA_SPEED="\${__GTA_ARG}"
    echo "GTA_SPEED=>\${GTA_SPEED}<  - now start the game, e.g.: xx 'win gta1 800x600+'"
  else
    echo "xx speed error: wrong value >\${__GTA_ARG}<, allowed: number 1-1000, default, off, screen, unset"
  fi
fi
unset __GTA_ARG __GTA_OK
# always show what the launchers will see, set or not
cat <<EEE

  GTA_SPEED=>\${GTA_SPEED}<      (empty = not set, launchers keep what is in ddraw.ini)
  GTA_DISPLAY=>\${GTA_DISPLAY}<    (empty = not set, launchers use full screen)

EEE
`,
      description: `STEP 1: choose game speed for this terminal (sets env var GTA_SPEED). No arg = arrow-key menu. Or pass it: default (standard, game's own timing), number = ticks per second (lower = slower), off, screen, unset. STEP 2: run a "win ..." command, it shows the value and waits for Enter`,
      source: true,
    },
    [`display`]: {
      command: `
# sourced in your shell (source: true), so no "exit" and no "set -e" here
__GTA_ARG="\${1}"
if [ -z "\${__GTA_ARG}" ]; then
  cat <<EEE

  Display is used ONLY by these two Windows builds (Wine + cnc-ddraw):
    win gta1 800x600+
    win london69 800x600+

  NOT affected (they ignore GTA_DISPLAY):
    win gta1 window 800x600+      always window
    win london69 window 800x600+  always window
    max wine menu
    dos ...   (all DOSBox commands: 24bit, 8bit, 3dfx) - full screen, pass --window for a window
EEE
  # arrow-key menu, runs in its own bash process and prints the chosen value
  __GTA_ARG="\$(/bin/bash _menu.sh "Display of the Windows builds  (now: GTA_DISPLAY=>\${GTA_DISPLAY}<)" "\${GTA_DISPLAY}" \\
    "window::window      - normal macOS window: movable, resizable, mouse stays free" \\
    "fullscreen::fullscreen  - borderless full screen" \\
    "unset::unset       - forget the value, launchers use full screen")"
fi
case "\${__GTA_ARG}" in
  "")
    echo "nothing changed, GTA_DISPLAY=>\${GTA_DISPLAY}<"
    ;;
  w|window)
    export GTA_DISPLAY="window"
    echo "GTA_DISPLAY=>\${GTA_DISPLAY}<  - now start the game, e.g.: xx 'win gta1 800x600+'"
    ;;
  f|fullscreen)
    export GTA_DISPLAY="fullscreen"
    echo "GTA_DISPLAY=>\${GTA_DISPLAY}<  - now start the game, e.g.: xx 'win gta1 800x600+'"
    ;;
  unset)
    unset GTA_DISPLAY
    echo "GTA_DISPLAY unset"
    ;;
  *)
    echo "xx display error: wrong value >\${__GTA_ARG}<, allowed: window (w), fullscreen (f), unset"
    ;;
esac
unset __GTA_ARG
# always show what the launchers will see, set or not
cat <<EEE

  GTA_SPEED=>\${GTA_SPEED}<      (empty = not set, launchers keep what is in ddraw.ini)
  GTA_DISPLAY=>\${GTA_DISPLAY}<    (empty = not set, launchers use full screen)

EEE
`,
      description: `STEP 1: choose window or full screen for this terminal (sets env var GTA_DISPLAY). No arg = arrow-key menu. Or pass it: window (w), fullscreen (f), unset. STEP 2: run "win gta1" / "win london69", they show the mode and wait for Enter`,
      source: true,
    },
    [`win gta1 800x600+`]: {
      command: `
set -e
/bin/bash win-classic-gta1.sh
`,
      description: `Resolution: 800x600 32-bit now, F11 in game cycles modes, highest ceiling of all (cnc-ddraw can offer more, top not checked). GTA1, Windows build in Wine (no DOSBox). Tested: starts and runs smooth  [win-classic-gta1.sh]`,
    },
    [`win london69 800x600+`]: {
      command: `
set -e
/bin/bash win-classic-london69.sh
`,
      description: `Resolution: 800x600 32-bit now, F11 in game cycles modes, highest ceiling of all (cnc-ddraw can offer more, top not checked). London 1969, Windows build in Wine (no DOSBox). Same engine as win gta1, not run yet, may ask for the CD  [win-classic-london69.sh]`,
    },
    [`win gta1 window 800x600+`]: {
      command: `
set -e
/bin/bash win-classic-gta1.sh --window
`,
      description: `Always window, whatever "display" says. Same as "win gta1" but in a normal macOS window: movable, resizable, mouse stays free for other windows  [win-classic-gta1.sh --window]`,
    },
    [`win london69 window 800x600+`]: {
      command: `
set -e
/bin/bash win-classic-london69.sh --window
`,
      description: `Always window, whatever "display" says. Same as "win london69" but in a normal macOS window: movable, resizable, mouse stays free for other windows  [win-classic-london69.sh --window]`,
    },
    [`max wine menu`]: {
      command: `
set -e
/bin/bash max-wine-menu.sh
`,
      description: `Resolution: depends on menu choice - normal 800x600, 3dfx 800x600 (seen in the log). MAX pack menu (GTA1 / London 69 / London 61) in the pack's own Windows DOSBox through Wine. Runs with DOSBox core=normal (the pack's default core crashes under this Wine), may be slower  [max-wine-menu.sh]`,
    },
    [`dos max gta1 24bit 800x600`]: {
      command: `
set -e
/bin/bash dos-max-gta1-24bit.sh "\${@}"
`,
      description: `Resolution: 800x600 24-bit expected, F11 in game cycles VESA modes, ceiling around 1024x768 (not checked). MAX pack GTA1 24-bit in native DOSBox. Untested, needs install. Arg: --window  [dos-max-gta1-24bit.sh]`,
    },
    [`dos classic gta1 24bit 800x600`]: {
      command: `
set -e
/bin/bash dos-classic-gta1-24bit.sh "\${@}"
`,
      description: `Resolution: 800x600 24-bit expected, F11 in game cycles VESA modes, ceiling around 1024x768 (not checked). Classic GTA1 24-bit in native DOSBox, music from CD image. Untested, needs install. Arg: --window  [dos-classic-gta1-24bit.sh]`,
    },
    [`dos max london69 24bit 800x600`]: {
      command: `
set -e
/bin/bash dos-max-london69-24bit.sh "\${@}"
`,
      description: `Resolution: 800x600 24-bit expected, F11 in game cycles VESA modes, ceiling around 1024x768 (not checked). MAX pack London 1969 24-bit in native DOSBox. Untested. Arg: --window  [dos-max-london69-24bit.sh]`,
    },
    [`dos max london61 24bit 800x600`]: {
      command: `
set -e
/bin/bash dos-max-london61-24bit.sh "\${@}"
`,
      description: `Resolution: 800x600 24-bit expected, F11 in game cycles VESA modes, ceiling around 1024x768 (not checked). MAX pack London 1961 24-bit in native DOSBox. Untested. Arg: --window  [dos-max-london61-24bit.sh]`,
    },
    [`dos classic london69 24bit 800x600`]: {
      command: `
set -e
/bin/bash dos-classic-london69-24bit.sh "\${@}"
`,
      description: `Resolution: 800x600 24-bit expected, F11 in game cycles VESA modes, ceiling around 1024x768 (not checked). Classic London 1969 24-bit in native DOSBox, music from CD image. Untested. Arg: --window  [dos-classic-london69-24bit.sh]`,
    },
    [`dos max gta1 8bit 640x480`]: {
      command: `
set -e
/bin/bash dos-max-gta1-8bit.sh "\${@}"
`,
      description: `Resolution: 640x480 256 colours expected, the lowest of all (not checked). MAX pack GTA1 8-bit (low colour) in native DOSBox. Untested. Arg: --window  [dos-max-gta1-8bit.sh]`,
    },
    [`dos classic gta1 8bit 640x480`]: {
      command: `
set -e
/bin/bash dos-classic-gta1-8bit.sh "\${@}"
`,
      description: `Resolution: 640x480 256 colours expected, the lowest of all (not checked). Classic GTA1 8-bit in native DOSBox. Untested. Arg: --window  [dos-classic-gta1-8bit.sh]`,
    },
    [`dos max london69 8bit 640x480`]: {
      command: `
set -e
/bin/bash dos-max-london69-8bit.sh "\${@}"
`,
      description: `Resolution: 640x480 256 colours expected, the lowest of all (not checked). MAX pack London 1969 8-bit in native DOSBox. Untested. Arg: --window  [dos-max-london69-8bit.sh]`,
    },
    [`dos classic london69 8bit 640x480`]: {
      command: `
set -e
/bin/bash dos-classic-london69-8bit.sh "\${@}"
`,
      description: `Resolution: 640x480 256 colours expected, the lowest of all (not checked). Classic London 1969 8-bit in native DOSBox. Untested. Arg: --window  [dos-classic-london69-8bit.sh]`,
    },
    [`dos max london61 8bit 640x480`]: {
      command: `
set -e
/bin/bash dos-max-london61-8bit.sh "\${@}"
`,
      description: `Resolution: 640x480 256 colours expected, the lowest of all (not checked). MAX pack London 1961 8-bit in native DOSBox (unofficial, incomplete per pack readme). Untested. Arg: --window  [dos-max-london61-8bit.sh]`,
    },
    [`dos max gta1 3dfx 640x480`]: {
      command: `
set -e
/bin/bash dos-max-gta1-3dfx.sh "\${@}"
`,
      description: `Resolution: 640x480 expected (emulated Voodoo, at most 800x600), filtered picture but not more pixels (not checked). MAX pack GTA1 3dfx on DOSBox's emulated Voodoo. Least certain group. Arg: --window  [dos-max-gta1-3dfx.sh]`,
    },
    [`dos classic gta1 3dfx 640x480`]: {
      command: `
set -e
/bin/bash dos-classic-gta1-3dfx.sh "\${@}"
`,
      description: `Resolution: 640x480 expected (emulated Voodoo, at most 800x600), filtered picture but not more pixels (not checked). Classic GTA1 3dfx on emulated Voodoo. Least certain group. Arg: --window  [dos-classic-gta1-3dfx.sh]`,
    },
    [`dos max london69 3dfx 640x480`]: {
      command: `
set -e
/bin/bash dos-max-london69-3dfx.sh "\${@}"
`,
      description: `Resolution: 640x480 expected (emulated Voodoo, at most 800x600), filtered picture but not more pixels (not checked). MAX pack London 1969 3dfx on emulated Voodoo. Least certain group. Arg: --window  [dos-max-london69-3dfx.sh]`,
    },
    [`dos classic london69 3dfx 640x480`]: {
      command: `
set -e
/bin/bash dos-classic-london69-3dfx.sh "\${@}"
`,
      description: `Resolution: 640x480 expected (emulated Voodoo, at most 800x600), filtered picture but not more pixels (not checked). Classic London 1969 3dfx on emulated Voodoo. Least certain group. Arg: --window  [dos-classic-london69-3dfx.sh]`,
    },
    [`dos max london61 3dfx 640x480`]: {
      command: `
set -e
/bin/bash dos-max-london61-3dfx.sh "\${@}"
`,
      description: `Resolution: 640x480 expected (emulated Voodoo, at most 800x600), filtered picture but not more pixels (not checked). MAX pack London 1961 3dfx on emulated Voodoo. Least certain group. Arg: --window  [dos-max-london61-3dfx.sh]`,
    },
    [`install`]: {
      command: `
set -e
/bin/bash install.sh
`,
      description: `install Rosetta, DOSBox Staging and Wine with brew (skips what is present), [install.sh]`,
    },
    [`pack`]: {
      command: `
set -e
/bin/bash pack.sh pack
`,
      description: `Run before git add / commit. Files bigger than CHUNK from .env (the CD images) are chopped into [file].001 [file].002 ... next to them, added to .gitignore (once) and removed. Chunks already there and the same: only the file is removed. Can be repeated  [pack.sh pack]`,
    },
    [`unpack`]: {
      command: `
set -e
/bin/bash pack.sh unpack "\${@}"
`,
      description: `Run after git clone / pull, before playing. Glues [file].001 [file].002 ... back into [file], the chunks stay. Arg: --delete removes the chunks (git then sees them as deleted: xx pack before the next commit)  [pack.sh unpack]`,
    },
    ...setup,
  };
};
