; Main Game Logic -------------------------------------------------------------
SECTION "GameLogic",ROM0


; Initialization --------------------------------------------------------------
game_init:

    ; setup background tile palette
    ld      a,%00000000
    ld      [corePaletteBG],a; load a into the memory pointed to by rBGP

    ; set sprite palette 0
    ld      a,%00000000  ; 3 = black      2 = light gray  1 = white  0 = transparent
    ld      [corePaletteSprite0],a 

    ; set sprite palette 1
    ld      a,%00000000  ; 3 = dark gray  2 = light gray  1 = white  0 = transparent
    ld      [corePaletteSprite1],a 

    ; Sound setup
    call    sound_enable

    ; Init game core
    ld      a,MAP_BACKGROUND_TILE_LIGHT
    call    map_init
    call    player_init

    ; If both start, select and up are pressed during power on go into debug mode
    ld      a,[coreInput]
    and     BUTTON_START | BUTTON_SELECT | BUTTON_UP
    cp      BUTTON_START | BUTTON_SELECT | BUTTON_UP
    jr      z,.debug
    
    ; Debug More or Release Mode
    ld      a,GAME_DEBUG_MODE
    cp      1
    jr      z,.debug

.release:
    call    title_init
    ret

.debug:
    call    screen_fade_in_light
    call    game_continue
    ret


; Setup Actual Game -----------------------------------------------------------
game_start:
    call    game_setup
    ld      a,1
    call    save_load_player
    ret


game_continue:
    call    game_setup
    call    save_load_from_sram
    ret


game_setup:

    ; load tile data and animations
    ld      hl,DataTileImg
    call    tileset_load
    ld      hl,DataTileAnimationImg
    call    tileset_load_animations

    ; Reset player
    call    player_init

    ; Hud
    call    game_draw_hud

    ld      a,GAME_MODE_PLAYING
    ld      [gameMode],a

    ret


; Main Loop -------------------------------------------------------------------
game_loop:

    ; disable everything during room updates
    ld      a,[mapRoomUpdateRequired]
    cp      0
    ret     nz

    ; check if we're on the title screen or not
    ld      a,[gameMode]
    cp      GAME_MODE_PLAYING

    ; game logic
    jr      z,.game

    ; title screen
    call    title_update

    ret

; Gameplay
.game:
    call    player_update
    call    entity_update
    call    sprite_animate_all
    call    map_check_fallable_blocks
    call    sound_update
    ret


; Timer -----------------------------------------------------------------------
game_timer:
    ld      a,[coreTimerCounter]
    and     %00000001
    jr      z,.tick; skip the timers below every other tick
    call    player_water_timer
    call    player_sleep_timer

.tick:
    call    map_update_falling_blocks
    call    map_animate_tiles
    call    screen_timer

    ret


; Hud -------------------------------------------------------------------------
game_draw_hud:
    ld      a,$bf - 128
    ld      hl,$9800 + 512
    ld      bc,20
    call    core_vram_set

    ld      a,$bf - 128
    ld      hl,$9c00 + 512
    ld      bc,20
    call    core_vram_set
    ret

