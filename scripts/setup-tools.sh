#!/usr/bin/env bash
# Build hactool and hacBrewPack from source into ./tools (macOS or Linux).
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p tools && cd tools
command -v make >/dev/null || { echo "Install a C toolchain first (Xcode CLT on macOS, build-essential on Linux)"; exit 1; }
[ -d hactool-src ] || git clone --depth 1 https://github.com/SciresM/hactool.git hactool-src
( cd hactool-src && cp -n config.mk.template config.mk && make -j4 && cp hactool ../hactool )
[ -d hacbrewpack-src ] || git clone --depth 1 https://github.com/rlaphoenix/hacBrewPack.git hacbrewpack-src
( cd hacbrewpack-src && cp -n config.mk.template config.mk 2>/dev/null || true; make -j4 && cp hacbrewpack ../hacbrewpack )
echo "tools ready: $(pwd)/hactool $(pwd)/hacbrewpack"
