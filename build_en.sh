#!/bin/bash
# Builds poketcg2.gbc with the pastel palettes, then applies the English fan
# translation (Artemis251 & Jazz, v1.1, "fromBase" IPS) to make poketcg2_en.gbc.
# Usage (from Windows): wsl -d Ubuntu --cd <repo> -- ./build_en.sh
# Override the patch location with EN_PATCH=/path/to/patch.ips.
#
# baserom.gbc: the linker fills unused gaps from it. Without the real Japanese
# ROM, a 2 MB file of $FF works: the original gaps are $FF filler (the patch
# never writes $FF into them).
set -e
cd "$(dirname "$0")"

RGBDS_DIR="${RGBDS_DIR:-/mnt/c/Users/kimbo/rgbds-1.0}"
EN_PATCH="${EN_PATCH:-/mnt/c/Users/kimbo/Downloads/PokemonTCG2Translation-v1.1/PokemonTCG2-FullTrans-v1.1-fromBase.ips}"

[ -f baserom.gbc ] || python3 -c "open('baserom.gbc', 'wb').write(b'\xff' * 0x200000)"
make -j"$(nproc)" poketcg2.gbc RGBDS="$RGBDS_DIR/"
python3 -I tools/ips_apply.py poketcg2.gbc "$EN_PATCH" poketcg2_en.gbc
# the palettes changed the ROM, so recompute the header and global checksums
"$RGBDS_DIR/rgbfix" -v poketcg2_en.gbc
echo "built poketcg2_en.gbc"
