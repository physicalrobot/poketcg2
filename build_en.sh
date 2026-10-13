#!/bin/bash
# Builds poketcg2.gbc with the pastel palettes, then applies the English fan
# translation (Artemis251 & Jazz, v1.1, "fromBase" IPS) to make poketcg2_en.gbc.
# Usage (from Windows): wsl -d Ubuntu --cd <repo> -- ./build_en.sh
# Override the patch location with EN_PATCH=/path/to/patch.ips.
#
# Needs baserom.gbc: the disassembly doesn't cover everything yet (e.g. all
# card art, banks $1d-$36), and the linker copies those parts from it.
# Either of these works for the English build:
#   - the Japanese ROM (sha1 BASEROM_SHA1_JP)
#   - the first 2 MB of the English v1.1 ROM (sha1 BASEROM_SHA1_EN), made with:
#       python3 tools/ips_apply.py <English v1.0 ROM> <...-fromV1.0.ips> en_v11.gbc
#       head -c 2097152 en_v11.gbc > baserom.gbc
#     Bytes the English patch doesn't write are still the original ones, and
#     the patch rewrites the rest, so the result is the same as with the
#     Japanese ROM. (Don't use it for a Japanese-only build: about 3 KB of it,
#     mostly the font in bank $1c, is English.)
set -e
cd "$(dirname "$0")"

RGBDS_DIR="${RGBDS_DIR:-/mnt/c/Users/kimbo/rgbds-1.0}"
EN_PATCH="${EN_PATCH:-/mnt/c/Users/kimbo/Downloads/PokemonTCG2Translation-v1.1/PokemonTCG2-FullTrans-v1.1-fromBase.ips}"
BASEROM_SHA1_JP=a7e12bcc5f514e3aad8de570fd511aab0a308822
BASEROM_SHA1_EN=de0846fccc7b0ddb510c0648d483b00237be31a9

case "$(sha1sum baserom.gbc 2>/dev/null | cut -c1-40)" in
	"$BASEROM_SHA1_JP" | "$BASEROM_SHA1_EN") ;;
	*)
		echo "error: baserom.gbc must be the Japanese Pokemon Card GB2 ROM or the" >&2
		echo "first 2 MB of the English v1.1 ROM (see the comment in this script)" >&2
		exit 1
		;;
esac
# make doesn't track baserom.gbc, so always relink
rm -f poketcg2.gbc
make -j"$(nproc)" poketcg2.gbc RGBDS="$RGBDS_DIR/"
python3 -I tools/ips_apply.py poketcg2.gbc "$EN_PATCH" poketcg2_en.gbc
# the palettes changed the ROM, so recompute the header and global checksums
"$RGBDS_DIR/rgbfix" -v poketcg2_en.gbc
echo "built poketcg2_en.gbc"
