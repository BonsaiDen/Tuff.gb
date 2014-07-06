; Title Screen and Developer Logo Functions -----------------------------------
title_init:
    ld      a,30
    ld      [titleWaitCounter],a
    ld      a,GAME_MODE_INIT
    ld      [gameMode],a
    ret

title_update:
    ld      a,[gameMode]
    cp      GAME_MODE_TITLE
    jp      z,.title

    cp      GAME_MODE_INIT
    jp      z,.init

    cp      GAME_MODE_LOGO
    jp      z,.logo

    cp      GAME_MODE_FADE_IN
    jp      z,.fade_in

    cp      GAME_MODE_CONTINUE
    jp      z,.continue

    cp      GAME_MODE_START
    jp      z,.start

    ret

    ; Setup logo and fade in
.init:

    ; delay
    ld      a,[titleWaitCounter]
    dec     a
    ld      [titleWaitCounter],a
    cp      0
    ret     nz

    call    title_draw_logo

    ; setup fade in
    ld      a,GAME_MODE_LOGO
    ld      [gameMode],a
    call    screen_fade_in_light

    ; show the logo for 80 frames
    ld      a,80
    ld      [titleWaitCounter],a

    ld      a,SOUND_GAME_LOGO
    call    sound_play

    ret

; Show logo and fade out
.logo:

    ld      a,[screenFadeMode]
    cp      0
    ret     nz

    ; delay
    ld      a,[titleWaitCounter]
    dec     a
    ld      [titleWaitCounter],a
    cp      0
    ret     nz

    call    screen_fade_out_light
    ld      a,GAME_MODE_FADE_IN
    ld      [gameMode],a

    ld      a,4
    ld      [titleWaitCounter],a

    ret

; Setup title screen and fade in
.fade_in:

    ld      a,[screenFadeMode]
    cp      0
    ret     nz

    ; delay
    ld      a,[titleWaitCounter]
    dec     a
    ld      [titleWaitCounter],a
    cp      0
    ret     nz

    ; draw title background
    call    title_draw_room
    call    title_draw_cursor

    ; player
    ld      a,87
    ld      [playerX],a
    ld      a,96
    ld      [playerY],a

    ; fade over
    call    screen_fade_in_light
    ld      a,GAME_MODE_TITLE
    ld      [gameMode],a

    ld      a,SOUND_GAME_LOGO
    call    sound_stop

    ld      a,SOUND_GAME_MENU
    call    sound_play

    ret

; Title screen logic
.title:

    ; handle selection of options
    call    title_select_option
    call    title_handle_button
    
    ; disable inputs
    xor     a
    ld      [coreInput],a
    ld      [coreInputOn],a
    ld      [coreInputOff],a
    
    ; move the player character around
    call    title_screen_movement

    call    player_update
    call    sprite_animate_all
    call    sound_update

    call    title_animate_logo

    ret

; Fade out and continue a existing game
.continue:
    ld      a,[screenFadeMode]
    cp      0
    ret     nz

    ; delay
    ld      a,[titleWaitCounter]
    dec     a
    ld      [titleWaitCounter],a
    cp      0
    ret     nz

    call    title_hide_logo
    call    game_continue
    call    screen_fade_in_light

    ret

; Fade out and start a new game
.start:
    ld      a,[screenFadeMode]
    cp      0
    ret     nz

    ; delay
    ld      a,[titleWaitCounter]
    dec     a
    ld      [titleWaitCounter],a
    cp      0
    ret     nz

    call    title_hide_logo
    call    game_start
    call    screen_fade_in_light
    ret



title_screen_movement:

    ; clean up actual input state
    ld      a,[coreInput]
    and     BUTTON_START | BUTTON_SELECT
    ld      c,a

    ; check if we need a new player movement command
    ld      a,[titlePlayerTick]
    cp      0
    jp      nz,.move

    ; new length of the movement
    call    math_random
    and     %00001111; at most 15 random frames
    add     10; minimum of 10 frames
    ld      [titlePlayerTick],a

    ; get new direction
    call    math_random
    and     %000001111
    ld      [titlePlayerDir],a

; continously move into the current target direction
.move:
    ld      a,[titlePlayerTick]
    dec     a
    ld      [titlePlayerTick],a

    ld      a,[titlePlayerDir]
    cp      0
    jp      z,.left

    cp      3
    jp      z,.right

    jp      .control

.left:

    ; don't leave the screen
    ld      a,[playerX]
    cp      16
    jp      c, .switch_to_right; x < 8

    ld      a,c
    or      BUTTON_LEFT
    ld      c,a
    jp      .control

.switch_to_right:
    ld      a,3
    ld      [titlePlayerDir],a
    jp      .right

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
    jp      .left

.control:
    ld      a,c
    ld      [coreInput],a

    ret


title_draw_logo:

    ; load title screen graphics into vram
    ld      hl,DataLogoImg
    ld      de,$8800; start target for decode write
    call    core_decode_eom

    ; clear screen buffer
    ld      a,$00
    sub     128
    ld      hl,$9800
    ld      bc,512
    call    core_vram_set

    ; initial screen offset
    ld      hl,$9800 + 128
    ld      de,DataLogoLayout

    ; copy logo data into vram
    ld      b,8; 8 rows

.loop_y:
    ld      c,8; 8 bytes per row
    inc     hl
    inc     hl
    inc     hl
    inc     hl
    inc     hl
    inc     hl


.loop_x:

    ; wait for vblank
    ld      a,[rSTAT]       ; <---+
    and     STATF_BUSY      ;     |
    jr      nz,@-4          ; ----+

    ld      a,[de]
    sub     128
    ld      [hl],a
    inc     de
    inc     hl

    ; loop
    dec     c
    jp      nz,.loop_x

    ; next line
    push    bc
    ld      bc,18
    add     hl,bc
    pop     bc

    dec     b
    jp      nz,.loop_y

    ret


title_draw_room:

    ; turn screen off for all the vram accessing
    call    core_screen_off

    ; force background buffer at $9800
    xor     a
    ld      [mapCurrentScreenBuffer],a

    ; clear screen buffer
    ld      a,$00
    sub     128
    ld      hl,$9800
    ld      bc,512
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
    call    title_draw_logo_sprite

    ; draw room
    ld      b,15
    ld      c,15
    call    map_load_room

    ; draw the room right away instead of waiting for the next vblank to draw it
    call    map_draw_room

    ; setup title text
    ld      hl,DataTitleLayout
    ld      de,$9800 + 488; "Start"
    ld      b,$04
    call    core_vram_cpy_low

    ; check for existing save data before displaying the continue option
    call    save_check_state
    ld      [titleCanContinue],a
    ld      [titleCursorPos],a
    cp      1
    ret     nz

    ld      hl,DataTitleLayout + 4
    ld      de,$9800 + 519; "Continue"
    ld      b,$06
    call    core_vram_cpy_low

    ; turn screen back on
    call    core_screen_on

    ret


title_draw_logo_sprite:
    xor     a
    ld      [titleSpriteOffsetIndex],a

    ld      de,spriteData + $48
    ld      hl,DataTitleSpriteLayout
    ld      bc,DATA_TITLE_SPRITE_COUNT * 4
    call    core_mem_cpy
    call    title_animate_logo

    ret


title_animate_logo:

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
    ld      de,spriteData + $48
    ld      hl,DataTitleSpriteLayoutYOffsets
    ld      b,DATA_TITLE_SPRITE_COUNT

.loop:
    ld      a,[hli]
    add     DATA_TITLE_SPRITE_Y
    add     c
    ld      [de],a
    inc     de
    inc     de
    inc     de
    inc     de
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


title_hide_logo:
    xor     a
    ld      hl,spriteData + $48
    ld      bc,DATA_TITLE_SPRITE_COUNT * 4
    call    core_mem_set
    ret


title_select_option:

    ld      a,[titleCanContinue]
    cp      0
    ret     z

    ld      a,[coreInputOn]
    and     BUTTON_UP
    cp      BUTTON_UP
    jr      z,.start

    ld      a,[coreInputOn]
    and     BUTTON_DOWN
    cp      BUTTON_DOWN
    jr      z,.continue
    ret

.start:
    ld      a,[titleCursorPos]
    cp      0
    ret     z

    xor     a
    ld      [titleCursorPos],a
    call    title_draw_cursor

    ld      a,SOUND_GAME_MENU_SELECT
    call    sound_play

    ret

.continue:
    ld      a,[titleCursorPos]
    cp      1
    ret     z

    ld      a,1
    ld      [titleCursorPos],a
    call    title_draw_cursor

    ld      a,SOUND_GAME_MENU_SELECT
    call    sound_stop

    ld      a,SOUND_GAME_MENU_SELECT
    call    sound_play

    ret


title_handle_button:

    ; Wait for start button press
    ld      a,[coreInputOn]
    and     BUTTON_START
    cp      BUTTON_START
    ret     nz

    ld      a,SOUND_GAME_SAVE_FLASH
    call    sound_play

    ld      a,10
    ld      [titleWaitCounter],a

    call    screen_fade_out_light

    ; check selected option
    ld      a,[titleCursorPos]
    cp      1
    jr      z,.continue

.start:
    ld      a,GAME_MODE_START
    ld      [gameMode],a
    ret

.continue:
    ld      a,GAME_MODE_CONTINUE
    ld      [gameMode],a
    ret


title_draw_cursor:

    ld      a,[titleCursorPos]
    cp      1
    jr      z,.continue

.start:
    ld      hl,$9800 + 487; "> Start"
    ld      bc,1
    ld      a,$1B
    call    core_vram_set

    ld      hl,$9800 + 518; " Continue"
    ld      bc,1
    ld      a,MAP_BACKGROUND_TILE_LIGHT
    sub     128
    call    core_vram_set
    ret

.continue:
    ld      hl,$9800 + 487; "Start"
    ld      bc,1
    ld      a,MAP_BACKGROUND_TILE_LIGHT
    sub     128
    call    core_vram_set

    ld      hl,$9800 + 518; "> Continue"
    ld      bc,1
    ld      a,$1A
    call    core_vram_set
    ret

