; Prints the player's name in half-width text, matching the English fan
; translation's half-width dialogue (the naming screen stores it full-width).
;
; Both sections are pinned to free space that the English IPS patch doesn't
; write to, and the only change to existing code is ProcessTextHeader.tx_ram1
; calling CopyNameForText instead of CopyPlayerNameOrTurnDuelistName (same
; size), so no other code or data moves and the patch still lines up.

SECTION "Half-Width Name Hook", ROM0[$3f88]

; like CopyPlayerNameOrTurnDuelistName, but converts the name to half-width
; returns hl = wStringBuffer
CopyNameForText::
	call CopyPlayerNameOrTurnDuelistName
	farcall ConvertNameToHalfWidth
	ld hl, wStringBuffer
	ret


SECTION "Half-Width Name", ROMX[$7900], BANK[$06]

; \1 = TX_FULLWIDTH0 char code, \2 = half-width char
; the naming screen precedes these codes with TX_HIRAGANA (or TX_KATAKANA)
MACRO halfwidth_name_char
	db TX_HIRAGANA, \1, \2
	db TX_KATAKANA, \1, \2
ENDM

; converts the full-width name at wStringBuffer to half-width text in place.
; full-width names are made of 2-byte pairs: TX_FULLWIDTH4 + letter/symbol,
; or TX_HIRAGANA/TX_KATAKANA + digit/symbol from the TX_FULLWIDTH0 set.
; lowercase letters become uppercase, since the translation's text is all caps.
; the name is left unchanged if it is already half-width or if any of its
; characters has no half-width equivalent (e.g. kana).
ConvertNameToHalfWidth::
	ld hl, wStringBuffer
	ld a, [hl]
	cp TX_HALFWIDTH
	ret z
	; first pass: make sure every character can be converted
.check_loop
	ld a, [hli]
	or a ; TX_END
	jr z, .convert
	ld b, a
	ld c, [hl]
	inc hl
	call GetHalfWidthNameChar
	ret c
	jr .check_loop

.convert
	; each 2-byte pair becomes 1 byte, written after a leading TX_HALFWIDTH.
	; the write pointer never passes the read pointer.
	ld hl, wStringBuffer
	ld de, wStringBuffer + 1
.convert_loop
	ld a, [hli]
	or a ; TX_END
	jr z, .done
	ld b, a
	ld c, [hl]
	inc hl
	call GetHalfWidthNameChar
	ld [de], a
	inc de
	jr .convert_loop
.done
	ld [de], a ; TX_END
	ld a, TX_HALFWIDTH
	ld [wStringBuffer], a
	ret

; input:
;   b = first byte of a full-width pair
;   c = second byte of a full-width pair
; output:
;   a = half-width character
;   carry set if there is no half-width equivalent
GetHalfWidthNameChar:
	ld a, b
	cp TX_FULLWIDTH4
	jr nz, .symbols
	; TX_FULLWIDTH4 $10-$29 = "A"-"Z", $2a-$43 = "a"-"z"
	ld a, c
	sub $10
	jr c, .symbols
	cp 26
	jr c, .letter
	sub 26
	cp 26
	jr nc, .symbols
.letter
	add 'A'
	ret ; nc

.symbols
	push hl
	ld hl, .Table
.loop
	ld a, [hli]
	or a
	jr z, .not_found
	cp b
	jr nz, .next
	ld a, [hl]
	cp c
	jr nz, .next
	inc hl
	ld a, [hl]
	pop hl
	or a ; nc
	ret
.next
	inc hl
	inc hl
	jr .loop
.not_found
	pop hl
	scf
	ret

.Table
; full-width pair, half-width char
	db TX_FULLWIDTH4, $5e, "&"
	; TX_FULLWIDTH0 set
	halfwidth_name_char $60, "0"
	halfwidth_name_char $61, "1"
	halfwidth_name_char $62, "2"
	halfwidth_name_char $63, "3"
	halfwidth_name_char $64, "4"
	halfwidth_name_char $65, "5"
	halfwidth_name_char $66, "6"
	halfwidth_name_char $67, "7"
	halfwidth_name_char $68, "8"
	halfwidth_name_char $69, "9"
	halfwidth_name_char $6a, "+"
	halfwidth_name_char $6b, "-"
	halfwidth_name_char $6e, "!"
	halfwidth_name_char $6f, "?"
	halfwidth_name_char $70, " "
	db 0 ; end
