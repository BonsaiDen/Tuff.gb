_DataEntityDefinitions:
    ;       0[BG/FG] 1[PALETTE] 2-7[TILEROW] 
    DB      %00000000,$00,$00,$00, $00,$00,$00,$00 ; Save Spot Light
    DB      %01000001,$00,$00,$00, $00,$00,$00,$00 ; Save Spot Dark
    DB      %11000010,$00,$00,$00, $00,$00,$00,$00 ; Moving Glow
    DB      %00000011,$00,$00,$00, $00,$00,$00,$00 ; Power up


; Entity Handler Table --------------------------------------------------------
DataEntityLoadHandlerTable:
    jp      entity_handler_load_save_light ; 3 byte
    nop     ; alignment

    jp      entity_handler_load_save_dark
    nop

    jp      entity_handler_load_glow
    nop

    jp      entity_handler_load_powerup
    nop

            
DataEntityUpdateHandlerTable:
    jp      entity_handler_update_save
    nop

    jp      entity_handler_update_save
    nop

    jp      entity_handler_update_glow
    nop

    jp      entity_handler_update_powerup
    nop


; Entity Logic Code Includes --------------------------------------------------
    INCLUDE "handler/save.gb.s"
    INCLUDE "handler/glow.gb.s"
    INCLUDE "handler/powerup.gb.s"

