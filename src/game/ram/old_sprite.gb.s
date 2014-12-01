SECTION "SpriteRam",WRAM0[$C000]; must be at $C000 for DMA copy

; OAM Sprite Data Buffer ------------------------------------------------------
spriteData:     DS 160  ; Sprite data to be later copied into OAM during vblank


; Sprite Meta Data-------------------------------------------------------------
SECTION "SpriteRamMeta", WRAM0[$CC00]; must be aligned at 256 bytes for spriteData

spriteMeta:     DS 160  ; 20 sprites, 6 bytes per sprite (each sprite is 2 hardware sprites)
                        ; [flags][frame][id][framesLeft] [tileOffset][unused][unused][unused]
                        ; flags: 000[direction][loop][animating][mirrored][enabled]

