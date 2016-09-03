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

    ; mark palettes as changed
    ld      a,$01
    ld      [corePaletteChanged],a

    ; Sound setup
    call    sound_enable

    ; Init game core
    ld      a,MAP_BACKGROUND_TILE_LIGHT
    call    map_init
    call    player_init
    call    script_init

    ; If both start, select and up are pressed during power on go into debug mode
    ld      a,[coreInput]
    and     BUTTON_START | BUTTON_SELECT | BUTTON_UP
    cp      BUTTON_START | BUTTON_SELECT | BUTTON_UP
    jr      z,.debug

    ; Debug More or Release Mode
    ld      a,GAME_DEBUG_MODE
    cp      0
    jr      nz,.debug

.release:
    call    title_init
    ret

.debug:
    ld      a,SCREEN_PALETTE_FADE_IN | SCREEN_PALETTE_LIGHT
    call    screen_animate
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

    ; Reset cutscene logic (set cutscene number to 0)
    ;xor     a
    ;ld      a,1
    ;call    cutscene_init

    ; Reset player
    call    player_init

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
    jr      z,.logic

    ; title screen
    call    title_update
    call    sound_update

    ret

.logic:
    call    player_update
    call    game_scroll_x
    call    game_scroll_y
    call    entity_update
    call    sprite_update
    call    effect_update
    call    map_check_fallable_blocks
    call    sound_update
    ret

game_scroll_x:
    ld      a,[playerX]
    ld      c,80
    ld      d,(MAP_ROOM_EDGE_RIGHT + 1) - 80
    ld      e,(MAP_ROOM_EDGE_RIGHT + 1) - 80 + 16
    call    _game_limit_scroll
    ld      b,a
    ld      a,[screenScrollX]
    add     b
    ld      [coreScrollX],a
    ret

game_scroll_y:
    ld      a,[playerY]
    ld      c,72
    ld      d,(MAP_ROOM_EDGE_BOTTOM + 1) - 72
    ld      e,(MAP_ROOM_EDGE_BOTTOM + 1) + 16
    call    _game_limit_scroll
    ld      b,a
    ld      a,[screenScrollY]
    add     b
    ld      [coreScrollY],a
    ret

_game_limit_scroll:; a = scroll value, c = limit, d = compare, e = border -> a = limited value
    cp      c
    jr      c,.border_one
    cp      d
    jr      nc,.border_two
    sub     c
    ld      b,a
    xor     a
    sub     b
    ret

.border_one:
    xor     a
    ret

.border_two:
    ld      a,e
    ret


; Timer -----------------------------------------------------------------------
game_timer:

    ; skip the timers below every other tick
    ld      a,[coreTimerCounter]
    and     %00000001
    jr      z,.every_tick
    call    player_water_timer
    call    player_sleep_timer

.every_tick:
    call    map_update_falling_blocks
    call    map_animate_tiles
    call    screen_timer
    call    cutscene_timer

    ret

