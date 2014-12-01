SECTION "SpriteRamOam",WRAM0[$C000]; must be at $C000 for DMA copy

; OAM Sprite Data Buffer ------------------------------------------------------
spriteOam:      DS 160  ; Sprite data to be later copied into OAM during vblank


; Sprite Meta Data-------------------------------------------------------------
SECTION "SpriteRamData", WRAM0[$CC00]; must be aligned at 256 bytes for spriteData

SPRITE_MAX      EQU 7
spriteData:     DS SPRITE_MAX * 9
spriteRowsUsed: DS 8

; 0: flags 7:enabled, 6:wasEnabled, 5:mirrored, 4:animationChanged, 3:unused, 2-0:palette
; 1: tileRow
; 2: animationFramesLeft
; 3: animationId
; 4: animationIndex
; 5: animationFrame
; 6: x
; 7: y
; 8: sprite index

