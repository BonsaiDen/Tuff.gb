SECTION "SpriteRam",WRAM0[$C000]

; OAM Sprite Data Buffer ------------------------------------------------------
spriteData:     DS 160  ; Sprite data to be later copied into OAM during vblank


; Sprite Meta Data-------------------------------------------------------------
SECTION "SpriteRamMeta", WRAM0[$C100]

spriteMeta:     DS 160  ; 20 sprites, 6 bytes per sprite (each sprite is 2 hardware sprites)
                        ; [flags][frame][id][framesLeft] [tileOffset][unused][unused][unused]
                        ; flags: 000[direction][loop][animating][mirrored][enabled]

