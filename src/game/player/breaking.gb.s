; Block Breaking --------------------------------------------------------------
; -----------------------------------------------------------------------------
break_horizontal_blocks_on_scroll:; a = side (0 = left, 1 = right)

    ; store side
    ld      d,a

    ; check player movement speed
    call    player_is_running
    ret     nz

    ; divide player y by 16 to get block
    ld      a,[playerY]
    sub     7
    swap    a
    and     $f
    ld      c,a; store y tile

    ; reset break delays
    xor     a
    ld      [playerMovementDelay],a
    ld      a,1
    ld      [playerBreakDelayed],a

    ; check side to break
    ld      a,d
    ld      b,0
    cp      1
    jr      z,_break_horizontal_blocks_left
    ld      b,9
    jr      _break_horizontal_blocks_right


break_horizontal_blocks:; a = block y, b = block x

    ld      c,a; move y tile into c

    ; divide by 8 and modulo 2 to figure out the left / right block
    ld      a,[playerX]
    srl     a
    srl     a
    srl     a
    and     %00000001

    cp      1
    jr      z,_break_horizontal_blocks_left

    cp      0
    jr      z,_break_horizontal_blocks_right
    ret

_break_horizontal_blocks_left:

    ; check if block can be broken
    push    bc
    sla     b; convert into 8x8 index
    sla     c; convert into 8x8 index
    call    map_get_tile_collision
    pop     bc
    cp      MAP_COLLISION_BREAKABLE
    ret     nz

    ; check if we need to set up the initial delay
    ld      a,[playerBreakDelayed]
    cp      1
    jr      nz,_break_horizontal_blocks_delay

    ; wait for delay to be over
    ld      a,[playerMovementDelay]
    cp      0
    ret     nz

    ; reset delay
    xor     a
    ld      [playerBreakDelayed],a

    ; break block
    ld      a,MAP_BLOCK_TILES_LEFT
    call    _destroy_breakable_block

    ret

_break_horizontal_blocks_right:
    ; check if block can be broken
    push    bc
    sla     b; convert into 8x8 index
    sla     c; convert into 8x8 index
    inc     b
    call    map_get_tile_collision
    pop     bc
    cp      MAP_COLLISION_BREAKABLE
    ret     nz

    ; check if we need to set up the initial delay
    ld      a,[playerBreakDelayed]
    cp      1
    jr      nz,_break_horizontal_blocks_delay

    ; wait for delay to be over
    ld      a,[playerMovementDelay]
    cp      0
    ret     nz

    ; reset delay
    xor     a
    ld      [playerBreakDelayed],a

    ; break block
    ld      a,MAP_BLOCK_TILES_RIGHT
    call    _destroy_breakable_block

    ret

_break_horizontal_blocks_delay:

    ld      a,3
    call    screen_shake

    ; sound
    ld      a,SOUND_EFFECT_PLAYER_POUND_BREAK
    call    sound_play_effect_two_wait

    ; align player y to
    ld      a,[playerY]
    and     %11111000
    ld      [playerY],a

    ld      a,1
    ld      [playerBreakDelayed],a

    ; check if we already added delay for this block row
    ; this is done so that when breaking two blocks at the time we only get
    ; 1 delay
    ld      a,[playerY];
    ld      c,a
    ld      a,[playerBreakBlockOffset]
    cp      c
    ret     z; if so exit

    ; otherwise set the block row to the current one
    ld      a,c
    ld      [playerBreakBlockOffset],a

    ld      a,4
    ld      [playerMovementDelay],a

    ret


break_vertical_blocks:; a = block x, c = block y

    ld      b,a; move x tile into b

    ; divide by 8 and modulo 2 to figure out the top / bottom block
    ld      a,[playerY]
    srl     a
    srl     a
    srl     a
    and     %00000001
    jr      z,.top

    cp      1
    jr      z,.bottom
    ret

.top:

    ; check if block can be broken
    push    bc
    sla     b; convert into 8x8 index
    sla     c; convert into 8x8 index
    call    map_get_tile_collision
    pop     bc
    cp      MAP_COLLISION_BREAKABLE
    ret     nz

    ; check if we need to set up the initial delay
    ld      a,[playerBreakDelayed]
    cp      1
    jr      nz,.delay

    ; wait for delay to be over
    ld      a,[playerGravityDelay]
    cp      0
    ret     nz

    ; reset delay
    xor     a
    ld      [playerBreakDelayed],a

    ; break block
    ld      a,MAP_BLOCK_TILES_TOP
    call    _destroy_breakable_block

    ret

.bottom:
    ; check if block can be broken
    push    bc
    sla     b; convert into 8x8 index
    sla     c; convert into 8x8 index
    inc     c
    call    map_get_tile_collision
    pop     bc
    cp      MAP_COLLISION_BREAKABLE
    ret     nz

    ; check if we need to set up the initial delay
    ld      a,[playerBreakDelayed]
    cp      1
    jr      nz,.delay

    ; wait for delay to be over
    ld      a,[playerGravityDelay]
    cp      0
    ret     nz

    ; reset delay
    xor     a
    ld      [playerBreakDelayed],a

    ; break block
    ld      a,MAP_BLOCK_TILES_BOTTOM
    call    _destroy_breakable_block

    ret

.delay:

    ld      a,3
    call    screen_shake

    ; sound
    ld      a,SOUND_EFFECT_PLAYER_POUND_BREAK
    call    sound_play_effect_two_wait

    ; align player y to
    ld      a,[playerY]
    and     %11111000
    ld      [playerY],a

    ld      a,1
    ld      [playerBreakDelayed],a

    ; check if we already added delay for this block row
    ; this is done so that when breaking two blocks at the time we only get
    ; 1 delay
    ld      a,[playerY];
    ld      c,a
    ld      a,[playerBreakBlockOffset]
    cp      c
    ret     z; if so exit

    ; otherwise set the block row to the current one
    ld      a,c
    ld      [playerBreakBlockOffset],a

    ld      a,4
    ld      [playerGravityDelay],a

    ret


; Block Breaking Helpers-------------------------------------------------------
MapBreakableBlockGroupOffsets:
    ; top
    DB      0, 0, $70, 0; +x, +y, tile
    DB      1, 0, $71, 0

    ; left
    DB      0, 0, $70, 0
    DB      0, 1, $72, 0

    ; bottom
    DB      0, 1, $72, 0
    DB      1, 0, $73, 0

    ; right
    DB      1, 0, $71, 0
    DB      0, 1, $73, 0

_destroy_breakable_block:; a = block group to break
    push    hl
    push    de
    push    bc

    ; offset into data table
    ld      h,0
    ld      l,a
    sla     l
    sla     l
    sla     l
    ld      de,MapBreakableBlockGroupOffsets
    add     hl,de

    ; get the 16x16 block tile for checking the new background of the tile
    call    map_get_block_value
    ld      e,a; store block id
    sla     b; convert into 8x8 index
    sla     c; convert into 8x8 index

    ; update both blocks
    ld      d,2
.loop:
    ; add offsets
    ld      a,[hli]
    add     b
    ld      b,a

    ld      a,[hli]
    add     c
    ld      c,a

    ; block destroy gfx
    push    hl
    push    de
    push    bc

    inc     b
    sla     b
    sla     b
    sla     b

    inc     c
    sla     c
    sla     c
    sla     c

    ; switch ypos / xpos
    ld      a,c
    ld      c,b
    ld      b,a
    ld      a,EFFECT_DUST_CLOUD_FAST
    call    effect_create

    pop     bc
    pop     de
    pop     hl

    ; check the desired background color of the breakable block
    ; if the background is dark we need to load the base dark tile value
    ld      a,e
    cp      MAP_BREAKABLE_BLOCK_LIGHT
    jr      z,.light

.dark:
    ld      a,[hli]; load the base background value
    push    hl
    call    _break_check_surrounding; check for transitions and modify accordingly
    pop     hl
    jr      .next

.light:
    ld      a,MAP_BACKGROUND_TILE_LIGHT
    inc     hl; skip the tile value

.next:
    inc     hl; skip the padding
    call    map_set_tile_value; set background tile
    dec     d
    jr      nz,.loop

    pop     bc
    pop     de
    pop     hl

    ; for the next 4 frames, prevent the player from loosing speed so they
    ; don't get stuck in the middle of broken blocks
    ld      a,4
    ld      [playerBreakContinue],a

    ret


_break_check_surrounding: ; b = tx, c = ty, a = base tile value
    ld      e,a

.left:
    ld      a,b; ignore blocks < 0
    cp      0
    jr      z,.top
    push    bc
    dec     b
    call    map_get_tile_value
    pop     bc

    cp      MAP_BACKGROUND_TILE_LIGHT
    jr      z,.found_left

.top:
    ld      a,c; ignore blocks < 0
    cp      0
    jr      z,.right
    push    bc
    dec     c
    call    map_get_tile_value
    pop     bc

    cp      MAP_BACKGROUND_TILE_LIGHT
    jr      z,.found_top

.right:
    ld      a,b; ignore blocks > 20
    cp      20
    jr      z,.bottom
    push    bc
    inc     b
    call    map_get_tile_value
    pop     bc

    cp      MAP_BACKGROUND_TILE_LIGHT
    jr      z,.found_right

.bottom:
    ld      a,c; ignore blocks > 8
    cp      16
    jr      z,.found_none
    push    bc
    inc     c
    call    map_get_tile_value
    pop     bc

    cp      MAP_BACKGROUND_TILE_LIGHT
    jr      z,.found_bottom

.found_none:
    ld      a,e; restore base tile
    ret

.found_left:
    ld      a,MAP_BACKGROUND_FADE_LEFT
    ret

.found_top:
    ld      a,MAP_BACKGROUND_FADE_TOP
    ret

.found_right:
    ld      a,MAP_BACKGROUND_FADE_RIGHT
    ret

.found_bottom:
    ld      a,MAP_BACKGROUND_FADE_BOTTOM
    ret

