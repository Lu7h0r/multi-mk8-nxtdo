#!/usr/bin/env bash
# Build "CTGP Deluxe": a standalone copy of Mario Kart 8 Deluxe 3.0.3 with CTGP-DX
# baked in, under its own title ID, so the original game can stay updated for online play.
#
# Everything comes from YOUR files: your own dump, your own keys, the CTGP-DX download.
# Nothing copyrighted ships with this repo.
set -euo pipefail

TITLE_ID="0100C7A5D0DE0000"   # fixed on purpose: every clone must share it for local wireless
TITLE_NAME="CTGP Deluxe"
EXPECTED_VERSION="3.0.3"
HERE="$(cd "$(dirname "$0")" && pwd)"

usage() {
  cat <<USAGE
Usage: $0 --base BASE.nsp --update UPDATE_3.0.3.nsp --ctgp CTGP_DIR --keys prod.keys [options]

Required:
  --base     MK8D base game dump (0100152000022000, v0), NSP with titlekey crypto removed
  --update   MK8D 3.0.3 update dump (0100152000022800, v1245184), same format
  --ctgp     CTGP-DX folder: either .../atmosphere/contents/0100152000022000 or the extracted zip root
  --keys     prod.keys dumped from YOUR console with Lockpick_RCM

Options:
  --icon FILE     256x256 JPEG to use as the home menu icon (default: the game's own icon)
  --work DIR      scratch directory (default: ./work) - needs ~50 GB free
  --out DIR       output directory for the NSP (default: ./out)
  --keep-work     do not delete the extracted files at the end
Tools: hactool and hacbrewpack must be in PATH or in ./tools (run scripts/setup-tools.sh).
USAGE
  exit 1
}

BASE= UPD= CTGP= KEYS= ICON= WORK="$PWD/work" OUT="$PWD/out" KEEP=0
while [ $# -gt 0 ]; do
  case "$1" in
    --base) BASE="$2"; shift 2 ;;
    --update) UPD="$2"; shift 2 ;;
    --ctgp) CTGP="$2"; shift 2 ;;
    --keys) KEYS="$2"; shift 2 ;;
    --icon) ICON="$2"; shift 2 ;;
    --work) WORK="$2"; shift 2 ;;
    --out) OUT="$2"; shift 2 ;;
    --keep-work) KEEP=1; shift ;;
    *) usage ;;
  esac
done
[ -n "$BASE" ] && [ -n "$UPD" ] && [ -n "$CTGP" ] && [ -n "$KEYS" ] || usage

die() { echo "ERROR: $*" >&2; exit 1; }
step() { echo; echo "==> $*"; }

find_tool() {
  if command -v "$1" >/dev/null 2>&1; then command -v "$1"
  elif [ -x "$HERE/../tools/$1" ]; then echo "$HERE/../tools/$1"
  else die "$1 not found (run scripts/setup-tools.sh)"; fi
}
HAC=$(find_tool hactool)
HBP=$(find_tool hacbrewpack)
command -v python3 >/dev/null || die "python3 is required"

# hactool prints key material in its WARN lines: never let stderr reach the terminal or a log.
hac() { "$HAC" -k "$KEYS" "$@" 2>/dev/null; }

step "Preflight"
for f in "$BASE" "$UPD" "$KEYS"; do [ -f "$f" ] || die "missing file: $f"; done
if [ -d "$CTGP/atmosphere/contents/0100152000022000" ]; then CTGP="$CTGP/atmosphere/contents/0100152000022000"; fi
[ -f "$CTGP/exefs/main.npdm" ] && [ -f "$CTGP/exefs/subsdk1" ] && [ -d "$CTGP/romfs" ] \
  || die "CTGP folder must contain exefs/main.npdm, exefs/subsdk1 and romfs/"
mkdir -p "$WORK" "$OUT"
free_gb=$(df -Pk "$WORK" | awk 'NR==2 {print int($4/1024/1024)}')
[ "$free_gb" -ge 50 ] || die "need ~50 GB free in $WORK, found ${free_gb} GB (hacbrewpack silently truncates when the disk fills)"
echo "free space: ${free_gb} GB"

step "Extracting dumps"
rm -rf "$WORK"/{base,upd,exefs,romfs,control,logo,nca,tmp,bak,hbp_nsp}
mkdir -p "$WORK"/{base,upd}
hac -t pfs0 --outdir="$WORK/base" "$BASE" >/dev/null
hac -t pfs0 --outdir="$WORK/upd" "$UPD" >/dev/null

nca_of_type() {
  for f in "$1"/*.nca; do
    t=$(hac -t nca "$f" | awk -F': *' '/Content Type/ {print $2; exit}')
    [ "$t" = "$2" ] && { echo "$f"; return; }
  done
}
BP=$(nca_of_type "$WORK/base" Program)
UP=$(nca_of_type "$WORK/upd" Program)
UC=$(nca_of_type "$WORK/upd" Control)
[ -n "$BP" ] && [ -n "$UP" ] && [ -n "$UC" ] || die "could not find program/control NCAs (are the dumps decrypted with your keys?)"

hac --romfsdir="$WORK/control" "$UC" >/dev/null
version=$(python3 -c "import sys;d=open(sys.argv[1],'rb').read();print(d[0x3060:0x3070].split(b'\0')[0].decode())" "$WORK/control/control.nacp")
[ "$version" = "$EXPECTED_VERSION" ] || die "update is version $version, CTGP-DX needs $EXPECTED_VERSION"
echo "update version: $version"

step "Merging base + update (this takes a while)"
hac --basenca="$BP" --exefsdir="$WORK/exefs" --romfsdir="$WORK/romfs" "$UP" >/dev/null
hac --section2dir="$WORK/logo" "$BP" >/dev/null || true
rm -rf "$WORK/base" "$WORK/upd"

step "Baking CTGP-DX in"
cp "$CTGP/exefs/main.npdm" "$WORK/exefs/main.npdm"
cp "$CTGP/exefs/subsdk1" "$WORK/exefs/subsdk1"
cp -R "$CTGP/romfs/." "$WORK/romfs/"
python3 "$HERE/patch_npdm.py" "$WORK/exefs/main.npdm" "$TITLE_ID"
if [ -n "$ICON" ]; then
  for f in "$WORK"/control/icon_*.dat; do cp "$ICON" "$f"; done
  echo "custom icon applied"
fi

step "Building NCAs with hacBrewPack (~20 min)"
mkdir -p "$WORK/hbp_nsp" && chmod 555 "$WORK/hbp_nsp"   # we pack the NSP ourselves; see README
( cd "$WORK" && "$HBP" -k "$KEYS" --titleid "$TITLE_ID" --titlename "$TITLE_NAME" \
    --keygeneration 4 --sdkversion 04040000 \
    --exefsdir exefs --romfsdir romfs --logodir logo --controldir control \
    --ncadir nca --nspdir hbp_nsp --tempdir tmp --backupdir bak --keepncadir 2>&1 \
  | grep -vE 'WARN|^Writing ' || true )
chmod 755 "$WORK/hbp_nsp"
rm -rf "$WORK/tmp" "$WORK/bak"
ls "$WORK"/nca/*.cnmt.nca >/dev/null 2>&1 || die "hacBrewPack did not produce NCAs"

step "Packing NSP"
NSP="$OUT/CTGP-Deluxe_${TITLE_ID}.nsp"
python3 "$HERE/pack_nsp.py" "$WORK/nca" "$NSP"

step "Verifying"
prog=$(for f in "$WORK"/nca/*.nca; do hac -t nca "$f" | grep -q 'Content Type: *Program' && echo "$f"; done | head -1)
hac -t nca "$prog" | grep -iq "Title ID: *${TITLE_ID}" || die "program NCA has the wrong title ID"
echo "title ID OK: $TITLE_ID"

[ "$KEEP" = 1 ] || rm -rf "$WORK"
echo
echo "Done: $NSP"
echo "Install it with DBI (Install via DBIbackend) or your installer of choice."
