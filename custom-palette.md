# Custom pastel palette + English patch — Pokémon TCG 2 (poketcg2)

Port of the pastel scheme from `C:\Users\kimbo\Documents\poketcg\custom-palette.md`
(read that first: target colors, mapping rules, protected content). Same rules
and choices; this file only records what's different here.

## Status (2026-10-13)

| Stage | What | Status |
|---|---|---|
| 1 | Toolchain + build | **Done.** RGBDS 1.0.4 via WSL. `baserom.gbc` rebuilt from the English v1.0 ROM (see below). |
| 2 | Map palettes | **Applied.** 117 sets (`PALETTE_000`–`077` from `MapGfx`), 2,807 `rgb` lines. |
| 3 | Text / textbox frame / duel icon palettes | **Applied.** 26 `rgb` lines in `src/gfx.asm`. |
| — | English patch | `build_en.sh` → `poketcg2_en.gbc`. |

`poketcg2_en.gbc` (SHA1 `26d44a8436e19e17994178e6a77d6a1c0c58ba65`) is the
verified build. An earlier one made with an all-`$FF` stand-in base was broken
(blank card art) and has been replaced.

## Build

- `build_en.sh` / `build_en.bat`: build `poketcg2.gbc`, apply the English fan
  translation (Artemis251 & Jazz, v1.1, `fromBase` IPS, from
  `Downloads\PokemonTCG2Translation-v1.1`) with `tools/ips_apply.py`, then
  `rgbfix -v` to fix the header/global checksums → `poketcg2_en.gbc` (4 MB).
- `build.sh` / `build.bat`: just `poketcg2.gbc` (Japanese, recolored).
- **baserom.gbc is required:** the linker overlays it (`-O`). Besides 99,506
  gap bytes inside disassembled banks, **31 whole banks (496 KB) aren't
  disassembled at all** (`; not started` in `src/layout.link`): `$14 $15 $1c`,
  `$1d`–`$36` (all card art), `$49 $4a`. An all-`$FF` stand-in (tried
  2026-10-13) builds, but those parts
  come out blank, and the IPS patch can't restore them because it only stores
  changed bytes. `build_en.sh` refuses to run without a known `baserom.gbc`.
- **baserom.gbc from the English ROM (what's in use):** the first 2 MB of the
  English v1.1 ROM (`...[T-En by Artemis251 & Jazz v1.0] [n].gbc` +
  `fromV1.0.ips`), SHA1 `de0846fccc7b0ddb510c0648d483b00237be31a9`. Bytes the
  `fromBase` patch doesn't write are original; the 3,396 it does write (bank
  `$1c` font, `$32`, a few in `$00`/`$7f`) can't be recovered, but the patch
  rewrites them, so English builds are identical to ones from the Japanese
  ROM. Not valid for a Japanese-only build.
- **Verified 2026-10-13:** all 1,506,131 bytes built from source match the
  English ROM, and so does every byte the patch writes. The name hook/converter
  locations are `$FF` free space in the real ROM. `build_en.sh` output equals
  "English v1.1 ROM + only our changed bytes" exactly.
- **Patch vs palettes, verified:** the patch writes no palette byte (only the
  global checksum overlaps) and makes no copies of palette data. The final ROM
  differs from "unmodified build + patch" in exactly the 5,503 palette/checksum
  bytes.
- Start a new save; Japanese saves leave some text untranslated (patch README).

## How poketcg2 differs from poketcg

- Palettes are numbered (`PaletteXXX`). `src/data/map_gfx.asm` `MapGfx` gives
  each map's BG palette set (`PALETTE_000`–`077`; 000–002 live in `src/gfx.asm`,
  the rest in `src/data/palettes1.asm`) and an OBJ set (`PALETTE_161`–`166`,
  overworld sprites — **don't change**).
- Map sets have 6 palettes loaded into **BGP2–7**
  (`CopyCGBBGPalsFromSource_BeginWithPal2`). BGP0 (text) and BGP1 (textbox
  frame) always come from `Pals_6f0b0` via `SetFontAndTextBoxFrameColor`
  (`src/engine/bank01.asm`).
- `Pals_6f0b0`: pal 0 = text; pals 1–4 = the four frame colors chosen in
  Options (`sTextBoxFrameColor`). `Pals_6f0d8` = duel card-type icons (BGP2–4,
  `Func_6c12`); `Pals_6f0f0` = alternate set (`Func_6c1d`).
- Background is white 31,31,31 (poketcg: 28,28,24).
- Map tilemaps are compressed, so map previews weren't rendered.
- See "Half-width player name" below for the name fix (differs from poketcg).

## Stage 3 as applied

- `Pals_6f0b0` pal 0: white → cream 31,29,24; 21,21,16 → 26,24,27;
  10,10,8 → 17,15,24; black → 10,8,25.
- Frame options (light / mid / dark, color 0 → cream):
  red → pink 31,20,26 / 30,11,22 / 22,8,19; blue → water 15,25,31 / 6,20,28 /
  12,12,26; green → aqua-mint 18,28,28 / 9,22,22 / 13,16,28; gray → lilac
  26,24,27 / 17,15,24 / 10,8,25.
- `Pals_6f0d8`, `Pals_6f0f0`: white → cream only; black outlines kept
  ("Option 1" from poketcg).

## Half-width player name

The English patch's dialogue is half-width ASCII (`TX_HALFWIDTH`, all caps),
but the naming screen stores the name full-width, so `<RAMNAME>` printed it big
and spaced out. `src/engine/halfwidth_name.asm` converts it, like poketcg's fix
but placed so the IPS patch still lines up:
- `CopyNameForText` (ROM0, pinned at `$3f88`; the patch only uses
  `$3fd0-$3fdf` of that gap) is called from `ProcessTextHeader.tx_ram1`
  instead of `CopyPlayerNameOrTurnDuelistName` (same 3-byte `call`).
- `ConvertNameToHalfWidth` (pinned at `06:7900`, bank 6 free space the patch
  never touches) converts `TX_FULLWIDTH4` A–Z/a–z (lowercase → uppercase,
  since the translation is all caps), `&`, digits, `+ - ! ?` and space. Names
  with kana or other symbols stay full-width.
- Verified: the build differs from the previous one only in the hook, the
  converter, the 2 call-address bytes and the checksum, before and after
  patching.
- Naming screen: press SELECT to cycle hiragana → katakana → ABC → abc.

Not done (poketcg2 equivalents not audited): link / printer / Card Pop scene
backgrounds, title/booster screens (Stage 4 was skipped in poketcg too).
