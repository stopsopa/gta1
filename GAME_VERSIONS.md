# Which versions of GTA are here

Everything in `/Users/szdz/Workspace/games` is the **first, top-down Grand Theft Auto**
(DMA Design, 1997) and its two London add-ons, plus an unused GTA2 CD image.
There is no single "version" - there are three games, each in several technical builds,
packaged in three different ways.

Facts below come from the files themselves (names, sizes, checksums, embedded strings, readmes).
Where something is my reading of the evidence rather than a fact, it is marked *(inferred)*.

## The three games

| Game | Released | What it is | Needs |
| --- | --- | --- | --- |
| **Grand Theft Auto** (GTA1) | 1997 | The original: Liberty City, San Andreas, Vice City | - |
| **GTA: London 1969** | 1999 | Mission pack: London map, new cars and missions | originally the GTA1 CD |
| **GTA: London 1961** | 1999 | Free add-on with a few more missions and a Manchester multiplayer map | London 1969 |

## The technical builds of each game

The original CD shipped the same game compiled several ways. The file name tells which one it is.

| Build | Executable | Runs on | Graphics |
| --- | --- | --- | --- |
| DOS 8-bit | `GTA8.EXE`, `gta8_uk.exe`, `gta8_61.exe` | DOS (DOSBox) | 256 colours, low resolution |
| DOS 24-bit | `GTA24.EXE`, `gta24_uk.exe`, `Gta24_61.exe` | DOS (DOSBox) | high colour through VESA |
| DOS 3dfx | `GTAFX.EXE`, `gtafx_uk.exe`, `Gtafx_61.exe` | DOS + 3dfx Voodoo card | Glide, filtered |
| Windows | `gtawin.exe` (GTA1), `gta_uk.exe` (London 1969) | Windows 95+ (Wine) | DirectDraw |

- `_uk` = London 1969, `_61` = London 1961, no suffix = GTA1.
- `K.EXE`, `k_uk.exe`, `K_61.exe` are the DOS setup / launcher programs of each game.
- All builds of one game share the same data folder (`gtadata`, London in `gtadata/uk`).
- There is **no Windows build of London 1961** anywhere on this disk.

## Package 1 - MAX pack (`gta-max`)

Folder: `games/GTA1-MAX (1)` (310 MB), unpacked from `GTA1-MAX (1).ZIP`.

- A fan-made bundle: "GRAND THEFT AUTO: MAX PACK", **version 1.3**, by Toshiba-3, 2016 (from its `README.TXT`).
- Contains **only DOS builds**: GTA1, London 1969 and London 1961, each as 24-bit, 8-bit and 3dfx
  (9 game executables).
- Its `Grand Theft Auto.exe` is **not the game** - it is DOSBox (SVN-Daum build, a Windows program)
  with a menu. The file is named that way so it can replace the game's exe in a Steam install.
- 3dfx support comes from nGlide 1.05 (`glide2x.dll`), per the readme.
- Music: the CD soundtracks converted to `.ogg` (`MUSIC/GTA` 10 tracks, `MUSIC/LONDON` 15 tracks).
- The executables are **modified** compared with the classic release: same names and mostly the same
  sizes, but different checksums. The readme says the base in-game resolution was set to 800x600x32
  and the UK setups / 8-bit modes were fixed, which fits *(inferred that this is what the changes are)*.
- London 1961's 8-bit mode is described by the pack itself as unofficial and incomplete.
- The pack's readme says its distribution is of questionable legality.

## Package 2 - classic release in a DOSBox wrapper (`gta-classic`)

Folder: `games/Grand Theft Auto (1997)` (1.5 GB), unpacked from `Grand Theft Auto (1997).exe`.

- The retail game files, **unmodified** *(inferred: checksums match the separate London 1969 install below)*,
  wrapped by someone with plain **DOSBox 0.74** and a `START THE GAME.bat`.
- The game folder is `games/GTA/GTA`, with **GTA1 and London 1969 installed together**:
  - `gtados` - DOS builds: 8-bit, 24-bit, 3dfx of both games (6 executables)
  - `gtawin` - **Windows builds**: `gtawin.exe` (GTA1) and `gta_uk.exe` (London 1969,
    carries a "1999 Rockstar Games" copyright string)
  - `gtadata` - shared data
- No London 1961 here.
- Music: full CD images `cd/GTA.BIN/.cue` (10 audio tracks) and `cd/GTALONDON.BIN/.cue` (15 audio tracks).
- The wrapper was only set up to start the DOS builds. The Windows builds were sitting there unused -
  `win-classic-gta1.sh` is what runs `gtawin.exe` from this folder, and it is the one confirmed working.

## Package 3 - duplicate install (`games/Grand Theft Auto London 1969`)

111 MB, unpacked from `gtalondon.zip` (files dated 2006).

- The same GTA1 + London 1969 install as package 2: every game executable has an **identical checksum**.
- Differences are only saves/settings (`PLAYER_A.DAT`, replays, video driver config).
- No CD images, so no music. No launchers were made for it.

## Other files in `games/` (not runnable as they are)

| File | What it is |
| --- | --- |
| `GTA1setup.exe` (32 MB, 2003), also inside `gta1.zip` | GTA1 installer; size and date fit Rockstar's free "Rockstar Classics" download *(inferred, not unpacked)* |
| `Grand Theft Auto/gta1cdaction.mdf/.mds` (817 MB) | GTA1 CD image |
| `GRAND_THEFT_AUTO_LONDON_1969/GTALONDON.bin/.cue` (673 MB) | London 1969 CD image |
| `GRAND_THEFT_AUTO_2/gta2.bin/.cue` (519 MB) | GTA2 CD image - a different game, not touched |
| `Grand Theft Auto.exe` (696 MB), `GRAND_THEFT_AUTO_LONDON_1969.exe`, `GRAND_THEFT_AUTO_2.exe` | self-extracting archives of the above *(inferred from names and sizes)* |

## Which launcher runs which version

| Launcher | Game | Build | From package |
| --- | --- | --- | --- |
| `win-classic-gta1.sh` | GTA1 | Windows | 2 |
| `win-classic-london69.sh` | London 1969 | Windows | 2 |
| `dos-classic-gta1-*.sh` | GTA1 | DOS 24-bit / 8-bit / 3dfx | 2 |
| `dos-classic-london69-*.sh` | London 1969 | DOS 24-bit / 8-bit / 3dfx | 2 |
| `dos-max-gta1-*.sh` | GTA1 | DOS 24-bit / 8-bit / 3dfx (modified) | 1 |
| `dos-max-london69-*.sh` | London 1969 | DOS 24-bit / 8-bit / 3dfx (modified) | 1 |
| `dos-max-london61-*.sh` | London 1961 | DOS 24-bit / 8-bit / 3dfx | 1 |
| `max-wine-menu.sh` | all three | DOS, through the pack's own DOSBox | 1 |

So: **London 1961 is only playable from the MAX pack**, and the **Windows builds exist only in the
classic release**.
