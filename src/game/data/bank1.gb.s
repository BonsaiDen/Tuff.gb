SECTION "Bank1 Data",ROMX,BANK[1]

; Shared Game Data ------------------------------------------------------------
DataBlockDef: 
    INCBIN  "../data/bin/blocks.def.bin" ; 4 rows of 256 bytes each
                                         ; 0 1 which contain the sub tiles for
                                         ; 2 3 each 16x16 block

DataTileCol: ; placed specifically @ 0x4400 for collision checks
    INCBIN  "../data/bin/tiles.col.bin"; 256 byte

DataTileImg:
    INCBIN  "../data/bin/tiles.bg.bin" 

DataTileAnimationImg:
    INCBIN  "../data/bin/animation.bg.bin" 


; Logo ------------------------------------------------------------------------
DataLogoImg:
    INCBIN  "../data/bin/logo.bg.bin" 

DataLogoLayout:
    DB      $00,$01,$02,$03, $04,$05,$06,$07
    DB      $10,$11,$12,$13, $14,$15,$16,$17
    DB      $08,$09,$0A,$0B, $0C,$0D,$00,$00
    DB      $18,$19,$1A,$1B, $1C,$00,$00,$00
    DB      $00,$00,$00,$0E, $0F,$00,$00,$00
    DB      $00,$00,$1D,$1E, $1F,$20,$00,$00
    DB      $21,$00,$00,$00, $22,$23,$00,$00
    DB      $24,$25,$26,$27, $28,$29,$2A,$2B


; Title Screen ----------------------------------------------------------------
DataTitleImg:
    INCBIN  "../data/bin/title.bg.bin" 

DataTitleLayout:
    DB      $10,$11,$12,$13
    DB      $14,$15,$16,$17,$18,$19

DataTitleSprite:
    INCBIN  "../data/bin/title.ch.bin" 

DataTitleSpriteLayout:

    ; Upper Part of T
    DB      0, 0 + DATA_TITLE_SPRITE_X,$60,$0F
    DB      0, 8 + DATA_TITLE_SPRITE_X,$62,$0F
    DB      0,16 + DATA_TITLE_SPRITE_X,$64,$0F
    DB      0,24 + DATA_TITLE_SPRITE_X,$66,$0F
    DB      0,32 + DATA_TITLE_SPRITE_X,$68,$0F
    DB      0,40 + DATA_TITLE_SPRITE_X,$6A,$0F

    ; Middle Part of T
    DB      0,12 + DATA_TITLE_SPRITE_X,$6C,$0F

    ; Lower Part of T
    DB      0,12 + DATA_TITLE_SPRITE_X,$76,$0F

    ; Left Half of U
    DB      0,22 + DATA_TITLE_SPRITE_X,$6E,$0F

    ; Right Half of U
    DB      0,36 + DATA_TITLE_SPRITE_X,$70,$0F

    ; Lower Parts of U
    DB      0,22 + DATA_TITLE_SPRITE_X,$78,$0F
    DB      0,30 + DATA_TITLE_SPRITE_X,$7A,$0F
    DB      0,36 + DATA_TITLE_SPRITE_X,$7C,$0F

    ; First F
    DB      0,46 + DATA_TITLE_SPRITE_X,$72,$0F
    DB      0,54 + DATA_TITLE_SPRITE_X,$74,$0F
    DB      0,46 + DATA_TITLE_SPRITE_X,$7E,$0F

    ; Second F
    DB      0,64 + DATA_TITLE_SPRITE_X,$72,$0F
    DB      0,72 + DATA_TITLE_SPRITE_X,$74,$0F
    DB      0,64 + DATA_TITLE_SPRITE_X,$7E,$0F

DataTitleSpriteLayoutAnimation:
    DB      0, 1, 1, 1, 2, 2, 2, 3, 3, 3, 4, 4, 4, 5, 5, 6
    DB      6, 5, 5, 4, 4, 4, 3, 3, 3, 2, 2, 2, 1, 1, 1, 0

DataTitleSpriteLayoutYOffsets:
    DB      8, 8, 8, 8, 8, 8,24,40,24,24,40,40,40,24,24,40,24,24,40


; Everything else -------------------------------------------------------------
DataPlayerImg:
    INCBIN  "../data/bin/player.ch.bin" 

DataEntityRows:
    INCBIN  "../data/bin/entities.ch.bin" 

DataSpriteAnimation:
    INCLUDE "game/data/animation/player.gb.s"
    INCLUDE "game/data/animation/entity.gb.s"

DataTileAnimation:
    INCLUDE "game/data/animation/tile.gb.s"

DataEntityDefinitions:
    INCLUDE "game/data/entities/entities.gb.s"

DataSoundDefinitions:
    INCLUDE "../data/bin/sounds.data.gb.s"

