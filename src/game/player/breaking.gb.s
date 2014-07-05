; Block Breaking --------------------------------------------------------------
; -----------------------------------------------------------------------------
break_horizontal_blocks:; a = block y, b = block x

    ld      c,a; move x tile into b

    ; divide by 8 and modulo 2 to figure out the left / right block
    ld      a,[playerX]
    srl     a
    srl     a
    srl     a
    and     %00000001

    cp      1
    jr      z,.left

    cp      0
    jr      z,.right
    ret

.left:

    ; check if block can be broken
    call    map_check_breakable_block_left
    cp      0
    ret     z

    ; check if we need to set up the initial delay
    ;ld      a,[playerBreakDelayed]
    ;cp      1
    ;jr      nz,.delay

    ;; wait for delay to be over
    ;ld      a,[playerMovementDelay]
    ;cp      0
    ;ret     nz

    ;; reset delay
    ;xor     a
    ;ld      [playerBreakDelayed],a

    ; break block
    call    map_destroy_breakable_block_left

    ld      a,SOUND_PLAYER_POUND_BREAK
    call    sound_play

    ret
    
.right:
    ; check if block can be broken
    call    map_check_breakable_block_right
    cp      0
    ret     z

    ; check if we need to set up the initial delay
    ;ld      a,[playerBreakDelayed]
    ;cp      1
    ;jr      nz,.delay

    ;; wait for delay to be over
    ;ld      a,[playerMovementDelay]
    ;cp      0
    ;ret     nz

    ;; reset delay
    ;xor     a
    ;ld      [playerBreakDelayed],a

    ; break block
    call    map_destroy_breakable_block_right

    ld      a,SOUND_PLAYER_POUND_BREAK
    call    sound_play

    ret

.delay:

    ld      a,3
    call    screen_shake

    ; sound
    ld      a,SOUND_PLAYER_POUND_BREAK
    call    sound_play

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

    cp      0
    jr      z,.top

    cp      1
    jr      z,.bottom
    ret

.top:

    ; check if block can be broken
    call    map_check_breakable_block_top
    cp      0
    ret     z

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
    call    map_destroy_breakable_block_top

    ld      a,SOUND_PLAYER_POUND_BREAK
    call    sound_play

    ret
    
.bottom:
    ; check if block can be broken
    call    map_check_breakable_block_bottom
    cp      0
    ret     z

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
    call    map_destroy_breakable_block_bottom

    ld      a,SOUND_PLAYER_POUND_BREAK
    call    sound_play

    ret

.delay:

    ld      a,3
    call    screen_shake

    ; sound
    ld      a,SOUND_PLAYER_POUND_BREAK
    call    sound_play

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


; Block Breaking Helper s------------------------------------------------------
map_check_breakable_block_left:
map_check_breakable_block_top:

    ; break the four 8x8 blocks
    push    bc
    sla     b; convert into 8x8 index
    sla     c; convert into 8x8 index

    ; check if we actually need to break them
    call    _map_get_tile_collision
    cp      5
    jr      nz,.no

    ld      a,1
    pop     bc
    ret

.no:
    xor     a
    pop     bc
    ret


map_check_breakable_block_bottom:

    ; break the four 8x8 blocks
    push    bc
    sla     b; convert into 8x8 index
    sla     c; convert into 8x8 index
    inc     c

    ; check if we actually need to break them
    call    _map_get_tile_collision
    cp      5
    jr      nz,.no

    ld      a,1
    pop     bc
    ret

.no:
    xor     a
    pop     bc
    ret

map_check_breakable_block_right:

    ; break the four 8x8 blocks
    push    bc
    sla     b; convert into 8x8 index
    sla     c; convert into 8x8 index
    inc     b

    ; check if we actually need to break them
    call    _map_get_tile_collision
    cp      5
    jr      nz,.no

    ld      a,1
    pop     bc
    ret

.no:
    xor     a
    pop     bc
    ret


map_destroy_breakable_block_top: ; b = block x, c = block y -> a = broken or not

    ; break the four 8x8 blocks
    push    bc
    
    ; get the 16x16 block tile
    call    map_get_block_value
    sla     b; convert into 8x8 index
    sla     c; convert into 8x8 index
    cp      MAP_BREAKABLE_BLOCK_LIGHT
    jr      z,.light

.dark:
    ld      a,$70
    call    _break_check_surrounding
    inc     b

    ld      a,$71
    call    _break_check_surrounding
    pop     bc
    ret

.light:
    ld      a,MAP_BACKGROUND_TILE_LIGHT
    call    map_set_tile_value; top left
    inc     b
    ld      a,MAP_BACKGROUND_TILE_LIGHT
    call    map_set_tile_value; top right
    pop     bc
    ret


map_destroy_breakable_block_bottom: ; a = block x, c = block y -> a = broken or not

    ; break the four 8x8 blocks
    push    bc

    ; get the 16x16 block tile
    call    map_get_block_value
    sla     b; convert into 8x8 index
    sla     c; convert into 8x8 index
    inc     c; lower row
    cp      MAP_BREAKABLE_BLOCK_LIGHT
    jr      z,.light

.dark:
    ld      a,$72
    call    _break_check_surrounding
    inc     b

    ld      a,$73
    call    _break_check_surrounding
    pop     bc
    ret

.light:
    ld      a,MAP_BACKGROUND_TILE_LIGHT
    call    map_set_tile_value; bottom left
    inc     b
    ld      a,MAP_BACKGROUND_TILE_LIGHT
    call    map_set_tile_value; bottom right
    pop     bc
    ret


map_destroy_breakable_block_left: ; b = block x, c = block y -> a = broken or not

    ; break the four 8x8 blocks
    push    bc
    
    ; get the 16x16 block tile
    call    map_get_block_value
    sla     b; convert into 8x8 index
    sla     c; convert into 8x8 index
    cp      MAP_BREAKABLE_BLOCK_LIGHT
    jr      z,.light

.dark:
    ld      a,$70
    call    _break_check_surrounding
    inc     c

    ld      a,$72
    call    _break_check_surrounding
    pop     bc
    ret

.light:
    ld      a,MAP_BACKGROUND_TILE_LIGHT
    call    map_set_tile_value; top left
    inc     c
    ld      a,MAP_BACKGROUND_TILE_LIGHT
    call    map_set_tile_value; bottom left
    pop     bc
    ret


map_destroy_breakable_block_right: ; b = block x, c = block y -> a = broken or not

    ; break the four 8x8 blocks
    push    bc
    
    ; get the 16x16 block tile
    call    map_get_block_value
    sla     b; convert into 8x8 index
    sla     c; convert into 8x8 index
    cp      MAP_BREAKABLE_BLOCK_LIGHT
    jr      z,.light

.dark:
    inc     b
    ld      a,$71
    call    _break_check_surrounding
    inc     c

    ld      a,$73
    call    _break_check_surrounding
    pop     bc
    ret

.light:
    inc     b
    ld      a,MAP_BACKGROUND_TILE_LIGHT
    call    map_set_tile_value; top left
    inc     c
    ld      a,MAP_BACKGROUND_TILE_LIGHT
    call    map_set_tile_value; bottom left
    pop     bc
    ret


_break_check_surrounding: ; b = tx, c = ty
    push    hl
    push    af

.left:
    ld      a,b; ignore blocks < 0
    cp      0
    jr      z,.top
    push    bc
    dec     b
    call    _map_get_tile_value
    pop     bc
    
    cp      MAP_BACKGROUND_TILE_LIGHT
    jr      z,.found_left

.top:
    ld      a,c; ignore blocks < 0
    cp      0
    jr      z,.right
    push    bc
    dec     c
    call    _map_get_tile_value
    pop     bc

    cp      MAP_BACKGROUND_TILE_LIGHT
    jr      z,.found_top

.right:

    ld      a,b; ignore blocks > 20
    cp      20
    jr      z,.bottom
    push    bc
    inc     b
    call    _map_get_tile_value
    pop     bc

    cp      MAP_BACKGROUND_TILE_LIGHT
    jr      z,.found_right

.bottom:

    ld      a,b; ignore blocks > 8
    cp      8
    jr      z,.found_none
    push    bc
    inc     c
    call    _map_get_tile_value
    pop     bc

    cp      MAP_BACKGROUND_TILE_LIGHT
    jr      z,.found_bottom

.found_none:
    pop     af
    jr      .done

.found_left:
    pop     af
    ld      a,MAP_BACKGROUND_FADE_LEFT
    jr      .done

.found_top:
    pop     af
    ld      a,MAP_BACKGROUND_FADE_TOP
    jr      .done

.found_right:
    pop     af
    ld      a,MAP_BACKGROUND_FADE_RIGHT
    jr      .done

.found_bottom:
    pop     af
    ld      a,MAP_BACKGROUND_FADE_BOTTOM

.done:
    pop     hl
    call    map_set_tile_value; top left
    ret

