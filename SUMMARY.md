# GTA1 / GTA London on this Mac - what was done

## Short answer: ReRun, DOSBox, or what?

**The launchers here use neither ReRun nor (for the one that is confirmed working) DOSBox.**

| Launcher group | What actually runs the game | ReRun involved? | Status |
| --- | --- | --- | --- |
| `win-*.sh` | Windows build of the game (`gtawin.exe`) → **Homebrew Wine 11** + **cnc-ddraw** for graphics | no | `win-classic-gta1.sh` ran, you confirmed it is smooth |
| `max-wine-menu.sh` | MAX pack's bundled DOSBox (a Windows program) → Homebrew Wine | no | crashed with the pack's settings, now starts with `core=normal` - speed not judged yet |
| `dos-*.sh` | DOS build of the game → **native macOS DOSBox** (no Wine at all) | no | never run, DOSBox is not installed yet |

ReRun was used only for investigation:

- I read its logs, its guide and the strings in its binary to learn what it does for GTA.
- I launched the MAX pack **once** with the Wine that ReRun had downloaded
  (`~/Library/Application Support/ReRun/gta/engine`) to see whether the pack starts under Wine. It did.

Nothing in this directory depends on ReRun being installed.

## Why ReRun did not fit the MAX pack

- ReRun's GTA support is for the **Windows** version of the game (`GTAWIN.EXE`, or the
  Rockstar Classics `WINO\Grand Theft Auto.exe`). Its guide says the DOS version is not used.
- `gta-max/Grand Theft Auto.exe` is not the game. It is **DOSBox (SVN-Daum build, a Windows program)**
  that shows a menu and starts the **DOS** builds of GTA. ReRun picked it up only because the file
  name matches.
- So with ReRun you were running: DOS game → DOSBox for Windows → Wine → Rosetta → macOS.
  ReRun's own fixes (cnc-ddraw `ddraw.dll`/`ddraw.ini`, registry keys, the screen-mode byte in
  `PLAYER_A.DAT`) target the Windows game; DOSBox does not appear to use any of them.

## What is on disk (`/Users/szdz/Workspace/games`)

| Folder | Link here | Contents |
| --- | --- | --- |
| `GTA1-MAX (1)` | `gta-max` | MAX pack: DOS builds of GTA1, London 1969, London 1961 (24-bit, 8-bit, 3dfx each), music as `.ogg`, bundled Windows DOSBox |
| `Grand Theft Auto (1997)` | `gta-classic` | Classic release: DOS **and Windows** builds of GTA1 and London 1969, CD images (`GTA.cue`, `GTALONDON.cue`) for music |
| `Grand Theft Auto London 1969` | - | Same executables as the classic release (identical checksums) - a duplicate, no launchers made |
| other items | - | CD images and installers (`.bin/.cue`, `.mdf`, `.zip`, self-extracting `.exe`), GTA2 - not runnable installs, left alone |

## What was created in this directory

- `gta-max`, `gta-classic` - the two game folders. They started as symlinks made by a `link.sh`
  script; that script was removed, the folders are meant to be real directories here.
- `install.sh` - installs Rosetta 2, DOSBox Staging (`brew install dosbox-staging`) and Wine
  (`brew install --cask wine-stable`), skipping what is already present.
  Needs Homebrew, prints how to install it when it is missing.
- `_wine_find.sh` - finds the Wine binary for the launchers and for `install.sh`; when Wine is
  missing it prints what exactly is missing on the machine and how to install it.
- `_wine.sh` - engine for the Windows builds (details below).
- `_dosbox.sh` - engine for the DOS builds (details below).
- `win-classic-gta1.sh`, `win-classic-london69.sh` - Windows builds.
- `dos-max-{gta1,london69,london61}-{24bit,8bit,3dfx}.sh` - 9 DOS launchers for the MAX pack.
- `dos-classic-{gta1,london69}-{24bit,8bit,3dfx}.sh` - 6 DOS launchers for the classic release.
- `max-wine-menu.sh` - the MAX pack's own menu through Wine (what ReRun was doing, minus ReRun).
- `speed.sh` - writes the game speed cap into `ddraw.ini` (called by the `win-*` launchers).
- `xx.ts` - xx menu with all of the above, ordered from the highest chance to work to the lowest.
- `GAME_VERSIONS.md` - which games and builds are on this disk.
- `.wine-prefix/` - Wine prefix created on the first run of a `win-*` launcher (331 MB, ignored by git).

All launchers are called the same way, from any directory:

```sh
/bin/bash /Users/szdz/Workspace/__claude/gta1_rerun/win-classic-gta1.sh
/bin/bash /Users/szdz/Workspace/__claude/gta1_rerun/dos-max-gta1-24bit.sh --window
```

or from this directory through `xx`.

## How the Windows launchers work (`_wine.sh`)

1. Find `wine` in PATH (override: env var `WINE_BIN`).
2. Use a dedicated Wine prefix `.wine-prefix` next to the scripts (override: `WINEPREFIX`),
   so your default `~/.wine` is not touched.
3. Once per prefix, import the registry keys the game needs
   (`HKLM\Software\Wow6432Node\DMA Design\Grand Theft Auto`: language, path, installed flag, controls).
   Without them the game says "Please run Settings first". They are the values from the game's own
   `gta.reg`, moved to the `Wow6432Node` branch because the game is 32-bit.
4. Make sure **cnc-ddraw** (`ddraw.dll` + `ddraw.ini`) is next to the exe. The game draws through
   DirectDraw; cnc-ddraw replaces it with an OpenGL renderer and scales the picture to a borderless
   full-screen window. Without it the game gives a black screen.
   ReRun had already placed both files in `gta-classic/games/GTA/GTA/gtawin`, so the script reused
   them. If they are missing it copies `ddraw.dll` from `gta-max/cnc-ddraw` and writes the same `ddraw.ini`.
5. `cd` into `gtawin` (the game finds its data through `..\gtadata`) and start the exe with
   `WINEDLLOVERRIDES="ddraw=n,b"` so Wine loads cnc-ddraw instead of its own DirectDraw.

Display settings live in `gta-classic/games/GTA/GTA/gtawin/ddraw.ini`. The launcher sets the
display mode and game speed lines there on every start (see the next two sections).

One thing inherited from ReRun: when it ran this folder earlier it set the screen mode in
`gtadata/PLAYER_A.DAT` to 800x600 in 32-bit colour. My scripts do not change that file.

## Window mode, and how to hop out of the game and come back

Applies to the Windows builds (`win ...`).

### Window mode

```sh
xx 'win gta1 window 800x600+'          # or: /bin/bash win-classic-gta1.sh --window
xx 'win london69 window 800x600+'      # or: /bin/bash win-classic-london69.sh --window
```

Or choose it once per terminal, the same two-stage way as the speed:

```sh
xx display            # asks: window / fullscreen / unset   (or: xx display window)
xx 'win gta1 800x600+'
```

`xx display` stores the choice in env var `GTA_DISPLAY` of that terminal. The plain `win ...`
commands follow it (full screen when it is not set); the `win ... window` commands and the
`--window` argument always give a window.

- The game opens in a normal macOS window: drag it, resize it, click other windows.
- The mouse is **not captured** in this mode (cnc-ddraw `devmode=true`). GTA is played with the
  keyboard only, so nothing is lost.
- First time the window starts at 1600x1200 (the 800x600 picture doubled). After that cnc-ddraw
  remembers the size and position you leave it in.
- Without `--window` the launcher switches back to borderless full screen. The launcher rewrites
  these `ddraw.ini` lines on every start, so the mode always follows the command you ran:
  `fullscreen=true|false`, `devmode=false|true`, `windowed=true`.

### Hopping out of full screen and back

"Full screen" here is a borderless window stretched over the screen, not an exclusive video mode,
so macOS still treats the game as an ordinary app:

| Do this | Result |
| --- | --- |
| **Cmd+Tab** | switch to another app; Cmd+Tab again (pick the Wine app) to come back |
| **Mission Control** (Ctrl+Up, or three/four-finger swipe up) | pick another window or desktop |
| **Option+Enter** (Alt+Enter) | cnc-ddraw switches between full screen and window while playing |
| **Ctrl+Tab** | cnc-ddraw releases the mouse cursor if it is locked inside the game |

The last two are cnc-ddraw's own hotkeys, and under Wine the Mac **Option** key is **Alt**.
I have not been able to try any of these myself (I cannot see or control the game window), so treat
the table as "should work"; if Cmd+Tab does not get you out of full screen, use the window mode.

The game does not pause when you switch away. Pause it first (in GTA1 the pause key is usually
**P** or **Pause** - check the in-game controls).

## Game speed (two stages)

The Windows build can run faster than intended on a modern machine. cnc-ddraw can cap the number
of game ticks per second (`maxgameticks` in `ddraw.ini`); lower = slower.

1. **Choose the speed** - `xx speed`. It asks for a value (or pass it: `xx speed 25`).
   With no argument it shows an arrow-key menu (up/down or left/right, Enter, q/Esc cancels).
   Accepted: `default` (**standard**: no cap line at all, the game keeps its own timing - this is
   what cnc-ddraw's built-in preset for GTA does), a number 1-1000 (try 60 / 30 / 25 / 20 / 15),
   `off`, `screen`, `unset`. After every choice it prints `GTA_SPEED` and `GTA_DISPLAY`.
   The command is sourced into your shell and stores the value in env var `GTA_SPEED`
   of **that terminal**.
2. **Start the game** - any `win ...` command. The launcher writes `GTA_SPEED` into `ddraw.ini`
   (through `speed.sh`), prints the display mode and the speed that will be used and
   **waits for Enter**. Esc (or Ctrl+C) at that point stops it, so you can run `xx speed` again and
   start the same command once more.

- When `GTA_SPEED` is not set the launcher keeps whatever is already in `ddraw.ini`
  (currently 30), so the last chosen value sticks across terminals.
- The DOS launchers and `max wine menu` ignore `GTA_SPEED` and do not pause.
- The right value is a matter of feel - I do not know the game's exact original rate.

## How the DOS launchers work (`_dosbox.sh`)

1. Find a native DOSBox: `dosbox` (DOSBox Staging) or `dosbox-x` (override: `DOSBOX_BIN`).
   If none is found it prints the install command and exits.
2. Write a small temporary config: full screen (or window with `--window`), 32 MB RAM,
   maximum CPU speed, Sound Blaster 16 on the settings the game's `DIG.INI` expects.
3. Mount the game folder as `C:` and the music as CD drives:
   MAX pack - `MUSIC/GTA/CDAUDIO.DAT` or `MUSIC/LONDON/CDAUDIO.DAT`;
   classic release - `cd/GTA.cue` as `D:` and `cd/GTALONDON.cue` as `E:` (as its original config did).
4. For the 3dfx builds, copy the real Voodoo driver `gta-max/glide2x_emu.ovl` into a temporary
   folder as `GLIDE2X.OVL`, mount it as `G:` and put it on the DOS PATH, so DOSBox's emulated
   Voodoo card can be used. No game folder is modified for this.
5. `cd \GTADOS`, run the chosen exe, exit DOSBox when the game ends.

## What is verified and what is not

- **Verified:** `win-classic-gta1.sh` starts under Homebrew Wine, the registry import works,
  the game process ran without errors in the log, and you saw it running smooth.
- **Not run:** `win-classic-london69.sh` (same engine, different exe - it may ask for the CD).
- **`max-wine-menu.sh`:** with the pack's original settings it **crashed under Homebrew Wine 11**
  right after a game was chosen from the menu (you hit this; I reproduced it). Cause: `core=auto`
  in the pack's `dosbox.conf` switches DOSBox to its "dynamic" CPU core when a game starts, and
  that core does not survive under this Wine. The launcher now runs from a temporary copy of the
  config with `core=normal` (plain interpreter); with that the 24-bit GTA1 kept running in my test.
  The interpreter is the slower core, so whether it is fast enough to play is still to be seen.
  The pack's own `dosbox.conf` is not modified. Under ReRun's older Wine 10 the dynamic core worked.
- **Never run:** all `dos-*.sh`. Only a dry run with a stand-in binary to check the generated
  config and mounts. The DOSBox setting names were written from memory for DOSBox Staging, so
  expect small corrections on the first real run.
- **Least certain:** the 3dfx launchers - they depend on the emulated Voodoo card finding the
  driver through the PATH.
- I cannot take screenshots on this Mac, so I never saw the picture myself - only processes and logs.

## Order in the xx menu (highest chance first)

0. `speed` - not a game, step 1 of choosing the game speed
1. `win gta1` - confirmed
2. `win london69` - same engine as the confirmed one
   (+ `win ... window` variants of both)
3. `max wine menu` - exe known to start under Wine
4. `dos ... 24bit` - the default mode of the DOS builds
5. `dos ... 8bit` - needs the VESA driver path to behave in DOSBox
6. `dos ... 3dfx` - needs Voodoo emulation
7. `install`, `help`

## Side effects outside this directory

- `gta-classic/.../gtawin/ddraw.dll` and `ddraw.ini` - placed by ReRun, reused by the scripts.
- The games write their own saves/settings into their folders (`PLAYER_A.DAT`, swap files).
- An empty swap file my first test left in `gta-max/GTADOS` was removed.
- `/Users/szdz/Workspace/__claude/.gitignore` - rules that keep only config files from `gta-max`
  (inactive while `gta-max` is a symlink, git does not look inside symlinks) and ignore `.wine-prefix/`.
