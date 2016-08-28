_DataEntityDefinitions:
    ;       TypeDef: 0[BG/FG] 1[PALETTE] 2-7[TILEROW]
    ;       DefaultFlags: 4-7[NO USABLE] 0-3[FLAGS]
    DB      %00_000000, %0000_0000 ; Save Spot Light
    DB      %01_000001, %0000_0000 ; Save Spot Dark
    DB      %11_000010, %0000_0000 ; Moving Glow
    DB      %00_000011, %0000_0111 ; Power up, flags = 1-8 for ability type
    DB      %10_000100, %0000_0000 ; Gem
    DB      %00_000101, %0000_0000 ; Platform Top Block Half
    DB      %00_000101, %0000_0000 ; Platform Bottom Block Half


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

