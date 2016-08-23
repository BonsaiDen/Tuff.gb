_DataEntityDefinitions:
    ;       0[BG/FG] 1[PALETTE] 2-7[TILEROW]
    DB      %00000000 ; Save Spot Light
    DB      %01000001 ; Save Spot Dark
    DB      %11000010 ; Moving Glow
    DB      %00000011 ; Power up
    DB      %10000100 ; Gem
    DB      %00000101 ; Platform Top Block Half
    DB      %00000101 ; Platform Bottom Block Half


; Entity Handler Table --------------------------------------------------------
DataEntityLoadHandlerTable:
    DW      entity_handler_load_save_light
    DW      entity_handler_load_save_dark
    DW      entity_handler_load_glow
    DW      entity_handler_load_powerup
    DW      entity_handler_load_gem
    DW      entity_handler_load_platform_top
    DW      entity_handler_load_platform_bottom

DataEntityUpdateHandlerTable:
    DW      entity_handler_update_save
    DW      entity_handler_update_save
    DW      entity_handler_update_glow
    DW      entity_handler_update_powerup
    DW      entity_handler_update_gem
    DW      entity_handler_update_platform
    DW      entity_handler_update_platform


; Entity Logic Code Includes --------------------------------------------------
    INCLUDE "handler/save.gb.s"
    INCLUDE "handler/glow.gb.s"
    INCLUDE "handler/powerup.gb.s"
    INCLUDE "handler/gem.gb.s"
    INCLUDE "handler/platform.gb.s"

