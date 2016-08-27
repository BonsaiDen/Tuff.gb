SECTION "TitleLogic",ROM0

; Title Screen and Developer Logo Functions -----------------------------------
title_init:
    ld      a,30
    ld      [titleWaitCounter],a
    ld      a,GAME_MODE_INIT
    ld      [gameMode],a
    ret

title_update:

    ; actual title screen
    ld      a,[gameMode]
    cp      GAME_MODE_TITLE
    jp      z,.title_screen_logic

    ; allow to skip maker logo
    ld      a,[coreInputOn]
    and     BUTTON_START
    call    nz,.skip_maker_logo

    ; wait for transitions to complete before setting next state
    call    _title_wait
    ret     nc

    ; title state machine
    ld      a,[gameMode]
    cp      GAME_MODE_INIT
    jp      z,.setup_maker_logo

    cp      GAME_MODE_LOGO
    jp      z,.setup_title_fadein

    cp      GAME_MODE_FADE_IN
    jp      z,.setup_title_screen_fade_in

    cp      GAME_MODE_CONTINUE
    jp      z,.game_continue

    cp      GAME_MODE_START
    jp      z,.game_start
    ret

.setup_maker_logo:
    ld     hl,DataLogoImg
    call   tileset_draw_image

    ; setup fade in
    ld      a,GAME_MODE_LOGO
    ld      [gameMode],a
    ld      a,SCREEN_PALETTE_FADE_IN | SCREEN_PALETTE_LIGHT
    call    screen_animate

    ; show the logo for 80 frames
    ld      a,80
    ld      [titleWaitCounter],a

    ld      a,SOUND_EFFECT_GAME_LOGO
    call    sound_play_effect_one

    ret

.skip_maker_logo:
    ld      a,[gameMode]
    cp      GAME_MODE_LOGO
    ret     nz

.setup_title_fadein:
    ld      a,SCREEN_PALETTE_FADE_OUT | SCREEN_PALETTE_LIGHT
    call    screen_animate

    ld      a,GAME_MODE_FADE_IN
    ld      [gameMode],a

    ld      a,4
    ld      [titleWaitCounter],a
    ret

.setup_title_screen_fade_in:

    ; draw title background
    call    _title_draw_room
    call    _title_draw_cursor

    ; player
    ld      a,87
    ld      [playerX],a
    ld      a,96
    ld      [playerY],a

    ; fade over
    ld      a,SCREEN_PALETTE_FADE_IN | SCREEN_PALETTE_LIGHT
    call    screen_animate

    ld      a,GAME_MODE_TITLE
    ld      [gameMode],a

    ld      a,SOUND_EFFECT_GAME_MENU
    call    sound_play_effect_one

    ret

.title_screen_logic:

    ; handle selection of options
    call    _title_select_option
    call    _title_handle_button

    ; disable inputs
    xor     a
    ld      [coreInput],a
    ld      [coreInputOn],a
    ld      [coreInputOff],a

    ; move the player character around
    call    _title_screen_movement

    call    player_update
    call    sprite_update
    call    sound_update

    call    _title_animate_logo

    ret

.game_continue:
    call    game_continue
    jr      .game_fadeout

.game_start:
    call    game_start

.game_fadeout:
    call    _title_hide_logo
    ld      a,SCREEN_PALETTE_FADE_IN | SCREEN_PALETTE_LIGHT
    call    screen_animate
    ret


_title_wait:
    ld      a,[screenAnimation]
    cp      1
    ret     nc

    ld      a,[titleWaitCounter]
    dec     a
    ld      [titleWaitCounter],a
    cp      1
    ret

_title_screen_movement:

    ; clean up actual input state
    ld      a,[coreInput]
    and     BUTTON_START | BUTTON_SELECT
    ld      c,a

    ; check if we need a new player movement command
    ld      a,[titlePlayerTick]
    cp      0
    jp      nz,.move

    ; get new direction
    call    math_random
    and     %000001111
    ld      [titlePlayerDir],a

    ; new length of the movement
    call    math_random
    and     %00001111; at most 15 random frames
    add     10; plus a minimum of 10 frames
    ld      [titlePlayerTick],a

; continously move into the current target direction
.move:
    ld      a,[titlePlayerTick]
    dec     a
    ld      [titlePlayerTick],a

    ld      a,[titlePlayerDir]
    cp      0
    jr      z,.left

    cp      3
    jr      z,.right

    jp      .control

.left:

    ; don't leave the screen
    ld      a,[playerX]
    cp      16
    jr      c, .switch_to_right; x < 8

    ld      a,c
    or      BUTTON_LEFT
    ld      c,a
    jr      .control

.switch_to_right:
    ld      a,3
    ld      [titlePlayerDir],a

.right:

    ; don't leave the screen
    ld      a,[playerX]
    cp      144
    jp      nc, .switch_to_left; x > 152

    ld      a,c
    or      BUTTON_RIGHT
    ld      c,a
    jp      .control

.switch_to_left:
    xor     a
    ld      [titlePlayerDir],a
    jr      .left

.control:
    ld      a,c
    ld      [coreInput],a
    ret


_title_draw_room:

    ; force background buffer at $9800
    xor     a
    ld      [mapCurrentScreenBuffer],a

    ; clear the last two rows of the screen buffer
    ld      d,$DF
    ld      hl,$9A00
    ld      bc,64
    call    core_vram_set

    ; setup title screen room graphics
    ld      hl,DataTileImg
    call    tileset_load

    ; load additional text graphics
    ld      hl,DataTitleImg
    ld      de,$9100; start target for decode write
    call    core_decode_eom

    ; load title screen logo sprites
    ld      hl,DataTitleSprite
    ld      de,$8600
    call    core_decode_eom

    ; setup title screen logo sprite
    call    _title_draw_logo_sprite

    ; draw the title room right away instead of waiting for the next vblank
    ld      b,15
    ld      c,15
    call    map_load_room
    call    map_draw_room

    ; draw "start" text
    ld      hl,DataTitleLayout
    ld      de,$9800 + 488; "Start" text position
    ld      b,$04
    call    core_vram_cpy_low

    ; check for existing save data before displaying the continue option
    call    save_check_state
    ld      [titleCanContinue],a
    ld      [titleCursorPos],a
    cp      0
    ret     z

    ; draw "continue" text
    ld      hl,DataTitleLayout + 4
    ld      de,$9800 + 519; "Continue" text position
    ld      b,$06
    call    core_vram_cpy_low
    ret


_title_draw_logo_sprite:
    xor     a
    ld      [titleSpriteOffsetIndex],a

    ld      de,spriteOam + $48
    ld      hl,DataTitleSpriteLayout
    ld      bc,DATA_TITLE_SPRITE_COUNT * 4
    call    core_mem_cpy
    call    _title_animate_logo

    ret


_title_animate_logo:

    ; load offset from sine table
    ld      hl,DataTitleSpriteLayoutAnimation
    ld      a,[titleSpriteOffsetIndex]
    ld      b,0
    ld      c,a
    add     hl,bc
    ld      a,[hl]
    sub     3
    ld      c,a; store offset into c

    ; setup sprite update loop
    ld      de,spriteOam + $48
    ld      hl,DataTitleSpriteLayoutYOffsets
    ld      b,DATA_TITLE_SPRITE_COUNT

.loop:
    ld      a,[hli]
    add     DATA_TITLE_SPRITE_Y
    add     c
    ld      [de],a
    inc     e
    inc     e
    inc     e
    inc     e
    dec     b
    jr      nz,.loop

    ; animate on every 3rd frame
    ld      a,[coreLoopCounter]
    and     %00000011
    cp      %00000011
    ret     nz

    ; update sine table index
    ld      a,[titleSpriteOffsetIndex]
    inc     a
    cp      32
    jr      nz,.no_reset
    xor     a

.no_reset:
    ld      [titleSpriteOffsetIndex],a
    ret


_title_hide_logo:
    xor     a
    ld      hl,spriteOam + $48
    ld      bc,DATA_TITLE_SPRITE_COUNT * 4
    call    core_mem_set
    ret


_title_select_option:

    ; continue option available?
    ld      a,[titleCanContinue]
    cp      0
    ret     z

    ; load current cursor position
    ld      a,[titleCursorPos]
    ld      b,a; store cursor pos

    ld      a,[coreInputOn]
    and     BUTTON_UP
    jr      nz,.cursor_move_start

    ld      a,[coreInputOn]
    and     BUTTON_DOWN
    jr      nz,.cursor_move_continue
    ret

.cursor_move_start:
    xor     a
    ld      [titleCursorPos],a
    jr      .switched

.cursor_move_continue:
    ld      a,1
    ld      [titleCursorPos],a

.switched:
    ; check if actually switched
    cp      b
    ret     z

    ; draw and play sound
    call    _title_draw_cursor
    ld      a,SOUND_EFFECT_GAME_MENU_SELECT
    call    sound_play_effect_one
    ret


_title_handle_button:

    ; Wait for START or A to be pressed
    ld      a,[coreInputOn]
    and     BUTTON_START | BUTTON_A
    cp      0
    ret     z

    ld      a,SOUND_EFFECT_GAME_SAVE_FLASH
    call    sound_play_effect_one

    ld      a,10
    ld      [titleWaitCounter],a

    ld      a,SCREEN_PALETTE_FADE_OUT | SCREEN_PALETTE_LIGHT
    call    screen_animate

    ; check selected option
    ld      a,[titleCursorPos]
    cp      0
    jr      nz,.button_continue

.button_start:
    ld      a,GAME_MODE_START
    ld      [gameMode],a
    ret

.button_continue:
    ld      a,GAME_MODE_CONTINUE
    ld      [gameMode],a
    ret


_title_draw_cursor:

    ld      hl,$9800 + 487; "Start" text location

    ; check cursor position
    ld      a,[titleCursorPos]
    cp      0
    jr      nz,.cursor_continue

.cursor_start:
    ; "> Start"
    ld      d,$1B
    call    core_vram_set_byte

    ; "  Continue"
    ld      d,MAP_BACKGROUND_TILE_LIGHT
    jr      .update_continue

.cursor_continue:
    ; "  Start"
    ld      d,MAP_BACKGROUND_TILE_LIGHT
    call    core_vram_set_byte

    ; "> Continue"
    ld      d,$1A

.update_continue:
    ld      hl,$9800 + 518
    call    core_vram_set_byte
    ret

