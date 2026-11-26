# GTA1 / GTA London on a Mac

Launchers for GTA1, London 1969 and London 1961 on macOS (Apple silicon).

Everything is started from one menu, made with [xx](https://github.com/stopsopa/xx): type `xx`, pick a row, press Enter.

Details of what runs what and why: [SUMMARY.md](SUMMARY.md), [GAME_VERSIONS.md](GAME_VERSIONS.md).

## 1. Install xx (once per computer)

You need `node` 22.18 or newer (check: `node -v`).

Full procedure: [README of xx](https://github.com/stopsopa/xx/blob/main/README.md#installation). Short version:

**a)** Open the [latest release of xx](https://github.com/stopsopa/xx/releases/latest), copy the block under the heading **`xx-darwin-arm64`** (macOS, Apple silicon) and run it in the terminal. It downloads two files (`xx-bin`, `xx.sh`) to a temporary directory and verifies them. Both lines of the verification have to end with `OK`.

**b)** In the same terminal (you are in the directory with the two files):

```sh
mkdir -p ~/.xx
mv xx-bin xx.sh ~/.xx/
chmod 755 ~/.xx/xx-bin
chmod 644 ~/.xx/xx.sh
```

**c)** Add xx to your shell. This is for zsh (default on macOS), run it once:

```sh
cat <<EEE >> ~/.zshrc

# xx - https://github.com/stopsopa/xx
export XX_BIN="~/.xx/xx-bin"
export XX_NODE_BINARY="$(node -e 'const p = process.execPath, h = require("os").homedir(); console.log(p.startsWith(h + "/") ? "~" + p.slice(h.length) : p)')"
export XX_NODE_OPTIONS=
alias xx='source ~/.xx/xx.sh'
EEE
```

For bash replace `~/.zshrc` with `~/.bashrc`.

**d)** Open a **new terminal** and check:

```sh
xx --version
```

## 2. Prepare this project (once after git clone)

```sh
cd /path/to/this/repository
xx unpack     # glues the CD images back together (they are stored in git in chunks)
xx install    # installs Rosetta, DOSBox Staging and Wine with brew, skips what is present
```

## 3. Play

In the directory of this repository type:

```sh
xx
```

The menu opens:

```
? Select command to run
❯ █   1 - speed
  ▋   2 - display
  ▍   3 - win gta1 800x600+
  ▎   4 - win london69 800x600+
  ▏   5 - win gta1 window 800x600+
  ▏   6 - win london69 window 800x600+
  ▏   7 - max wine menu
  ▏   8 - dos max gta1 24bit 800x600
  ▏   9 - dos classic gta1 24bit 800x600
  ▏  10 - dos max london69 24bit 800x600
  ▏  11 - dos max london61 24bit 800x600
  ▏  12 - dos classic london69 24bit 800x600
  ▏  13 - dos max gta1 8bit 640x480
  ▏  14 - dos classic gta1 8bit 640x480
  ▏  15 - dos max london69 8bit 640x480
  ▏  16 - dos classic london69 8bit 640x480
  ▏  17 - dos max london61 8bit 640x480
  ▏  18 - dos max gta1 3dfx 640x480
  ▏  19 - dos classic gta1 3dfx 640x480
  ▏  20 - dos max london69 3dfx 640x480
  ▏  21 - dos classic london69 3dfx 640x480
  ▏  22 - dos max london61 3dfx 640x480
  ▎  23 - install
  ▍  24 - pack
  ▋  25 - unpack
  █  26 - help

STEP 1: choose game speed for this terminal (sets env var GTA_SPEED). No arg = arrow-key menu. Or pass …
↑↓ navigate • ⏎ select • type to filter • esc exit
```

- `↑` `↓` move, `Enter` runs the selected row, `Esc` closes the menu.
- Typing filters the rows, by name or by number (type `london`, or `3`).
- The line under the list describes the selected row.

Without the menu: `xx 3` or `xx "win gta1 800x600+"` runs the row directly.

### Which row to pick

Games are ordered from the highest chance to work to the lowest. Start with row 3:

| Rows | What it is |
| --- | --- |
| `win ...` (3 - 6) | Windows build of the game through Wine. The one confirmed to work. |
| `max wine menu` (7) | menu of the MAX pack (GTA1 / London 1969 / London 1961) in its own DOSBox through Wine |
| `dos ...` (8 - 22) | DOS builds in native DOSBox, untested. All accept `--window`, e.g. `xx 8 --window` |
| `help` (26) | short description of this directory and link to the repository |

### Speed and display (rows 1 and 2)

These two don't start anything. They set a value for the current terminal, which is used by the game started **later in the same terminal**:

```sh
xx speed      # choose the speed of the game
xx display    # choose window or full screen
xx 3          # start the game with these settings
```

Each of them lists, above its own menu, which rows it affects. In short:

| | `speed` | `display` |
| --- | --- | --- |
| `win gta1 800x600+`, `win london69 800x600+` | yes | yes |
| `win gta1 window 800x600+`, `win london69 window 800x600+` | yes | no, always a window |
| `max wine menu` | no | no |
| `dos ...` | no | no, full screen unless `--window` is given |

### Before git commit

```sh
xx pack       # chops the big CD images into chunks, they are too big for GitHub in one piece
```

After that `xx unpack` is needed again before playing.
