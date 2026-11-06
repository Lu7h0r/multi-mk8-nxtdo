# MK8D CTGP Clone

Play **CTGP Deluxe** and **online Mario Kart 8 Deluxe** on the same Switch, without toggling mods.

CTGP-DX 1.1.1 only runs on Mario Kart 8 Deluxe **3.0.3**, but online play (Nextendo Network) needs **4.0.1**. A console can only hold one update per title, so normally you have to pick one.

This repo builds a second, standalone app: **CTGP Deluxe**, which is MK8D 3.0.3 with CTGP-DX baked in, under its own title ID. The original game stays on the latest version for online play.

```
Home menu
├── Mario Kart 8 Deluxe   (0100152000022000)  4.0.1 + DLC  →  Nextendo online
└── CTGP Deluxe           (0100C7A5D0DE0000)  3.0.3 + CTGP →  custom tracks, local play
```

> **No game files, keys or CTGP files are included or will ever be.** You build the clone from your own dump of a game you own, with keys from your own console and the official CTGP-DX download. Do not share the resulting NSP.

## Requirements

| What | Where it comes from |
|---|---|
| Switch with CFW (Atmosphère) and sigpatches / sys-patch | your setup |
| Your MK8D **base** dump (`0100152000022000`, v0) | [nxdumptool](https://github.com/DarkMatterCore/nxdumptool) (rewrite) |
| Your MK8D **3.0.3 update** dump (`0100152000022800`, v1245184) | nxdumptool, *before* updating the game |
| `prod.keys` from your console | [Lockpick_RCM](https://github.com/shchmue/Lockpick_RCM) |
| CTGP-DX 1.1.1 | [ctgpdx.com](https://www.ctgpdx.com/) |
| A Mac or Linux PC (Windows: use WSL) with **~50 GB free** | |
| An installer on the Switch | DBI, Tinfoil, Awoo… |

## Steps

### 1. Dump keys and the game (on the Switch)

1. Run **Lockpick_RCM** → *Dump from EmuNAND* (or SysNAND, whichever you play on). Copy `sd:/switch/prod.keys` to your PC.
2. Open **nxdumptool** → *Dump installed SD card / eMMC content* → Mario Kart 8 Deluxe:
   - set **"nca/tik: remove titlekey crypto" = yes**
   - dump the **base application** (NSP)
   - dump the **update 3.0.3** (NSP)
   - output to SD or "usb host (pc)" with `nxdt_host.py`

> If your game is already on 4.0.1 you need a 3.0.3 dump from somewhere you legally obtained it. Dumping before updating is the easy path.

### 2. Get CTGP-DX

Download CTGP-DX from [ctgpdx.com](https://www.ctgpdx.com/) and extract it. You need the folder that contains `exefs/` and `romfs/` (`atmosphere/contents/0100152000022000`).

### 3. Build tools (once)

```bash
./scripts/setup-tools.sh        # builds hactool + hacBrewPack into ./tools
```

### 4. Build the clone

```bash
./scripts/build.sh \
  --base   "MK8D [0100152000022000][v0].nsp" \
  --update "MK8D [0100152000022800][v1245184].nsp" \
  --ctgp   ~/Downloads/CTGP-DX \
  --keys   ~/.switch/prod.keys \
  --icon   my-icon.jpg            # optional, 256x256 JPEG
```

It takes about 30 minutes and produces `out/CTGP-Deluxe_0100C7A5D0DE0000.nsp` (~17 GB).

Optional icon: `python3 scripts/make_badge_icon.py original_icon.jpg my-icon.jpg` adds a "CTGP" band to the game's icon (needs Pillow). You can also edit the cover any way you like.

### 5. Install

Install the NSP with DBI (e.g. *Install via DBIbackend* over USB). It shows up as **CTGP Deluxe**, next to the original game. You need ~17 GB free on the SD.

### 6. Update the original for online

Install the MK8D **4.0.1 update** (and Booster Course Pass DLC if you own it) on the original title. In-game/eShop updates fail on CFW with Nextendo (`2155-2000`), so install the update with DBI.

Then remove the old CTGP files from `atmosphere/contents/0100152000022000` so the original game runs vanilla online.

## Nextendo online checklist

| Error | Meaning | Fix |
|---|---|---|
| `2306-0819` | Game too old | Install 4.0.1 |
| `2155-2000` | Update download failed | Install the update with DBI |
| `2306-0807` | No Discord linked to your Nextendo account | Join the Nextendo Discord → verification channel → *Verify my account* → sign in at `verify.nextendo.network` |
| `2306-0808` | E-mail not confirmed | Confirm it on nextendo.network |
| `2123-0011` | Blank PRODINFO on emuMMC | `blank_prodinfo_emummc=0` in `exosphere.ini` |

The full list is on the [Nextendo wiki](https://wiki.nextendo.network/errors).

## Why the title ID is fixed

Everyone's clone uses `0100C7A5D0DE0000`. Local wireless only matches consoles that run the same title ID, so if two people pick different IDs they can't race each other in CTGP.

## Gotchas

- **Disk space.** hacBrewPack needs ~3× the romfs size (temp files + NCA + NSP). It does **not** fail cleanly when the disk fills: it reports success and writes a truncated NSP. `build.sh` checks for 50 GB, packs the NSP itself, and verifies the size.
- **Key leaks.** hactool prints key values in its `WARN` lines. `build.sh` discards hactool's stderr. Don't paste raw hactool output anywhere.
- **NPDM.** `hacbrewpack --titleid` only patches ACI0. `patch_npdm.py` also rewrites the ACID title ID range so the loader accepts the program.
- **Changing the icon** means a full rebuild and reinstall, because hacBrewPack randomizes the key area on every build.

## How it works

1. `hactool --basenca` merges the base program with the 3.0.3 update into plain exefs/romfs.
2. CTGP-DX's `main.npdm` and `subsdk1` (skyline) replace the exefs files, and its romfs overlays the game's.
3. `patch_npdm.py` sets the new title ID. hacBrewPack builds Program, Control and Meta NCAs (keygen 4, SDK 4.4.0.0).
4. `pack_nsp.py` writes a PFS0 (NSP) and checks its size.

## License

MIT for the scripts. Mario Kart 8 Deluxe belongs to Nintendo. CTGP-DX belongs to its authors. This project is not affiliated with either.
