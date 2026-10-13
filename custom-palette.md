# Custom pastel palette + English patch — Pokémon TCG 2 (poketcg2)

Port of the pastel scheme from `C:\Users\kimbo\Documents\poketcg\custom-palette.md`
(read that first: target colors, mapping rules, protected content). Same rules
and choices; this file only records what's different here.

## Status (2026-10-13)

| Stage | What | Status |
|---|---|---|
| 1 | Toolchain + build | **Done.** RGBDS 1.0.4 via WSL (`build.sh`). No real Japanese ROM: `baserom.gbc` is a 2 MB `$FF` stand-in (see below). `compare` can't pass without the real ROM. |
| 2 | Map palettes | **Applied.** 117 sets (`PALETTE_000`–`077` from `MapGfx`), 2,807 `rgb` lines. |
| 3 | Text / textbox frame / duel icon palettes | **Applied.** 26 `rgb` lines in `src/gfx.asm`. |
| — | English patch | `build_en.sh` → `poketcg2_en.gbc`. |

Nothing tested in-game yet. Uncommitted.

## Build

- `build_en.sh` / `build_en.bat`: build `poketcg2.gbc`, apply the English fan
  translation (Artemis251 & Jazz, v1.1, `fromBase` IPS, from
  `Downloads\PokemonTCG2Translation-v1.1`) with `tools/ips_apply.py`, then
  `rgbfix -v` to fix the header/global checksums → `poketcg2_en.gbc` (4 MB).
- `build.sh` / `build.bat`: just `poketcg2.gbc` (Japanese, recolored).
- **baserom.gbc stand-in:** the linker overlays `baserom.gbc` (`-O`) to fill
  99,506 gap bytes, almost all at bank ends. The patch writes 472 `$00` and zero
  `$FF` bytes into those gaps, so the original filler is `$FF` and an all-`$FF`
  stand-in reproduces the base the patch expects. Replace it with the real ROM
  (SHA1 `a7e12bcc5f514e3aad8de570fd511aab0a308822`) if you ever get one.
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
- The half-width name fix doesn't apply: the base game is Japanese, and the
  patch has its own small-font hack.

## Stage 3 as applied

- `Pals_6f0b0` pal 0: white → cream 31,29,24; 21,21,16 → 26,24,27;
  10,10,8 → 17,15,24; black → 10,8,25.
- Frame options (light / mid / dark, color 0 → cream):
  red → pink 31,20,26 / 30,11,22 / 22,8,19; blue → water 15,25,31 / 6,20,28 /
  12,12,26; green → aqua-mint 18,28,28 / 9,22,22 / 13,16,28; gray → lilac
  26,24,27 / 17,15,24 / 10,8,25.
- `Pals_6f0d8`, `Pals_6f0f0`: white → cream only; black outlines kept
  ("Option 1" from poketcg).

Not done (poketcg2 equivalents not audited): link / printer / Card Pop scene
backgrounds, title/booster screens (Stage 4 was skipped in poketcg too).
