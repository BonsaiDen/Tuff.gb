SECTION "MapLogic",ROM0


; Map -------------------------------------------------------------------------
map_init: ; a = base value for background tiles

    sub     128; add offset for tile buffer at $8800
    ld      hl,mapRoomTileBuffer
    ld      bc,512
    call    core_mem_set

    ; clear both screen buffers
    ld      hl,$9800
    ld      bc,1024
    call    core_mem_set

    ; clear both screen buffers
    ld      hl,$9c00
    ld      bc,1024
    call    core_mem_set

    ret


; Scrolling -------------------------------------------------------------------
map_scroll_left:
    ld      a,[mapRoomX]
    ld      [mapRoomLastX],a
    dec     a
    ld      b,a
    ld      a,[mapRoomY]
    ld      [mapRoomLastY],a
    ld      c,a
    call    map_load_room
    ret


map_scroll_right:
    ld      a,[mapRoomX]
    ld      [mapRoomLastX],a
    inc     a
    ld      b,a
    ld      a,[mapRoomY]
    ld      [mapRoomLastY],a
    ld      c,a
    call    map_load_room
    ret


map_scroll_down:
    ld      a,[mapRoomX]
    ld      [mapRoomLastX],a
    ld      b,a
    ld      a,[mapRoomY]
    ld      [mapRoomLastY],a
    inc     a
    ld      c,a
    call    map_load_room
    ret


map_scroll_up:
    ld      a,[mapRoomX]
    ld      [mapRoomLastX],a
    ld      b,a
    ld      a,[mapRoomY]
    ld      [mapRoomLastY],a
    dec     a
    ld      c,a
    call    map_load_room
    ret


; Map -------------------------------------------------------------------------
map_load_room: ; b = x, c = y

    push    hl
    push    de
    push    bc

    ; store new room coordinates
    ld      a,b
    ld      [mapRoomX],a
    ld      a,c
    ld      [mapRoomY],a

    ; bank switch
    di
    ld      hl,$2000
    ld      [hl],MAP_ROOM_DATA_BANK

    ; get room pointer offset into bc
    call    _map_load_room_pointer
    inc     hl; skip length byte

    ; store room flags here for later use
    ld      a,[hli]
    ld      [mapRoomHeaderFlags],a

    call    _map_load_animations
    call    _map_load_tile_map
    call    _map_load_entities

    ; unpack the tile data
    ld      de,mapRoomBlockBuffer
    ld      bc,mapRoomBlockBuffer + MAP_ROOM_SIZE
    call    core_decode

    ; bank switch
    ld      hl,$2000
    ld      [hl],$01
    ei

    ; setup block definitions
    call    _map_load_block_definitions

    ; unload entities
    call    entity_store ; first store them
    call    entity_reset 

    ; load room data into vram
    call    _map_load_room_data

    ; reset animation delays to keep everything in sync
    ld      hl,mapAnimationDelay
    xor     a
    ld      bc,TILE_ANIMATION_COUNT
    call    core_mem_set

    pop     bc
    pop     de
    pop     hl

    ret


; Core Map Draw Routine -------------------------------------------------------
map_draw_room:

    ; check if we need to draw the room data to screen ram
    ld      a,[mapRoomUpdateRequired]
    cp      1
    ret     nz

    ; mark as updated (disable interrupts so we don't call this during vblank)
    di
    xor     a
    ld      [mapRoomUpdateRequired],a
    ei

    ; load new entities
    call    entity_load

    ; switch between the two screen buffers to prevent flickering
    ld      a,[mapCurrentScreenBuffer]
    cp      1
    jr      z,.buffer_9c

.buffer_98:
    ld      de,$9800
    jr      .copy

.buffer_9c:
    ld      de,$9C00

.copy:
    ld      hl,mapRoomTileBuffer
    ld      bc,512
    call    core_vram_cpy

    ; flip buffer
    ld      a,[mapCurrentScreenBuffer]
    xor     1
    ld      [mapCurrentScreenBuffer],a

    ; adjust for or mask
    xor     1
    sla     a
    sla     a
    sla     a
    ld      b,a

    ; flip bg data used for screen
    ld      a,[rLCDC]
    and     LCDCF_BG_MASK
    or      b
    ld      [rLCDC],a

    ret


; Collision Detection ---------------------------------------------------------
map_get_collision: ; b = x pos, c = y pos (both without scroll offsets) -> a = 1 if collision, 0 = no collision

    ; check for the bottom end of the screen
    ; if we index into the ram beyond this area we will read invalid data
    ; so we assume that there is never any collision beyond y 128
    ld      a,c
    cp      128
    jr      nc,.off_screen ; reset collision flag and indicate no collision

    ; divide x by 8
    srl     b
    srl     b
    srl     b

    ; divide y by 8
    srl     c
    srl     c
    srl     c

    ; check type of collision
    call    _map_get_tile_collision
    cp      MAP_COLLISION_BLOCK; normal blocks
    jr      z,.collision
    cp      MAP_COLLISION_BREAKABLE; breakable
    jr      z,.collision

    ; everything that is not solid has no collision
.no_collision:
    ld      [mapCollisionFlag],a
    xor     a
    ret

.collision:
    ld      [mapCollisionFlag],a
    ld      a,1
    ret

.off_screen:
    xor     a
    ld      [mapCollisionFlag],a
    ret


; same as the nomral collision check
; and also treat everything except for 0 as collision
map_get_collision_simple: ; b = x pos, c = y pos (both without scroll offsets) -> a = 1 if collision, 0 = no collision
    push    bc

    ; check bottom screen border
    ld      a,c
    cp      127
    jr      nc,.collision 

    ; check top screen border
    xor     a
    cp      c
    jr      nc,.collision 

    ; check right screen border
    ld      a,b
    cp      159
    jr      nc,.collision 

    ; check left screen border
    xor     a
    cp      b
    jr      nc,.collision 

    ; divide x by 8
    srl     b
    srl     b
    srl     b

    ; divide y by 8
    srl     c
    srl     c
    srl     c

    ; check type of collision
    call    _map_get_tile_collision
    cp      0
    jr      nz,.collision
    pop     bc
    ret

.collision:
    pop     bc
    ld      a,1
    ret


; Animation -------------------------------------------------------------------
map_animate_tiles:

    ; store state
    push    hl
    push    de
    push    bc

    ; loop and animate tiles
    ld      d,0
    ld      hl,mapAnimationIndexes
.animate:

    ; check if animation is used
    ld      bc,mapAnimationUseMap
    ld      a,d
    add     a,c
    ld      c,a
    adc     a,b
    sub     c
    ld      b,a
    ld      a,[bc] ; check if current tile is animated on this screen
    cp      0
    jr      z,.next

    ; load current delay count for this animation
    ld      bc,mapAnimationDelay
    ld      a,d
    add     a,c
    ld      c,a
    adc     a,b
    sub     c
    ld      b,a
    ld      a,[bc] ; delay for the current tile
    cp      0 ; if we hit zero animate the tile
    jr      nz,.delay ; if not decrease delay count by one

    ; animate the tile -------------------------------------

    ; get the default delay value 
    push    bc; store delay point counter
    ld      bc,DataTileAnimation

    ; offset into tile animation data
    ld      a,d; base + d * 8 + 1
    sla     a
    sla     a
    sla     a
    inc     a

    ; add to bc
    add     a,c
    ld      c,a
    adc     a,b
    sub     c
    ld      b,a
    ld      a,[bc]
    pop     bc; restore delay count pointer

    ; set index count to default delay
    ld      [bc],a

    ; update current tile animation index
    ld      a,[hl]
    inc     a
    and     %00000011 ; modulo 4
    ld      [hl],a

    ; update tile vram -------------------------------------

    ; update vram  (hl = source, de = dest, bc = size (16))
    push    hl
    push    de

    ; store animation index value
    inc     a; offset into animation data
    inc     a
    ld      e,a 

    ; get base tile value of the animation (base + d * 8)
    ld      hl,DataTileAnimation
    ld      b,0
    ld      c,d
    sla     c
    sla     c
    sla     c
    add     hl,bc
    ld      a,[hl] 
    ld      d,a ; base tile value $00 - $ff

    ; get the current tile value of the animation into B (base + d * 8 + a + 2)
    ld      c,e 
    add     hl,bc
    ld      b,[hl] ; store current tile value $00 - $ff

    ; get the target address in vram into DE (multiply the base tile by 16 + $8800)
    ld      h,0
    ld      l,d
    add     hl,hl
    add     hl,hl
    add     hl,hl
    add     hl,hl
    ld      a,h
    add     a,$88; add screen vram base offset
    ld      d,a ; store into DE
    ld      e,l

    ; get the current animation address into HL 
    ; (multiply the current (tile - TILE_ANIMATION_BASE_OFFSET) by 16 + DataTileImg)
    ld      a,b; restore tile value
    ld      h,0
    ld      l,a
    add     hl,hl
    add     hl,hl
    add     hl,hl
    add     hl,hl
    ld      bc,mapTileAnimationBuffer
    add     hl,bc

    ; copy 16 bytes from the tile buffer into vram
    ld      b,16
    call    core_vram_cpy_low

    pop     de
    pop     hl
    jr      .next

.delay:
    dec     a
    ld      [bc],a

.next:
    ; end of vram update

    ; next animation
    inc     hl
    inc     d
    ld      a,d
    cp      TILE_ANIMATION_DATA_COUNT
    jr      nz,.animate
    ; end of loop

    ; restore state
    pop     bc
    pop     de
    pop     hl

    ret


; Breakable Blocks ------------------------------------------------------------
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


map_get_block_value: ; b = x, c = y -> a block value

    push    hl
    push    de

    ; y * 10
    ld      h,10
    ld      e,c
    call    math_mul8b

    ; add x
    ld      e,b
    ld      d,0
    add     hl,de

    ; add base offset
    ld      de,mapRoomBlockBuffer
    add     hl,de
    ld      a,[hl]

    pop     de
    pop     hl

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
    call    map_check_breakable_surrounding
    inc     b

    ld      a,$71
    call    map_check_breakable_surrounding
    pop     bc
    ret

.light:
    ld      a,MAP_BACKGROUND_TILE_LIGHT
    call    _map_set_tile_value; top left
    inc     b
    ld      a,MAP_BACKGROUND_TILE_LIGHT
    call    _map_set_tile_value; top right
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
    call    map_check_breakable_surrounding
    inc     b

    ld      a,$73
    call    map_check_breakable_surrounding
    pop     bc
    ret

.light:
    ld      a,MAP_BACKGROUND_TILE_LIGHT
    call    _map_set_tile_value; bottom left
    inc     b
    ld      a,MAP_BACKGROUND_TILE_LIGHT
    call    _map_set_tile_value; bottom right
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
    call    map_check_breakable_surrounding
    inc     c

    ld      a,$72
    call    map_check_breakable_surrounding
    pop     bc
    ret

.light:
    ld      a,MAP_BACKGROUND_TILE_LIGHT
    call    _map_set_tile_value; top left
    inc     c
    ld      a,MAP_BACKGROUND_TILE_LIGHT
    call    _map_set_tile_value; bottom left
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
    call    map_check_breakable_surrounding
    inc     c

    ld      a,$73
    call    map_check_breakable_surrounding
    pop     bc
    ret

.light:
    inc     b
    ld      a,MAP_BACKGROUND_TILE_LIGHT
    call    _map_set_tile_value; top left
    inc     c
    ld      a,MAP_BACKGROUND_TILE_LIGHT
    call    _map_set_tile_value; bottom left
    pop     bc
    ret


map_check_breakable_surrounding: ; b = tx, c = ty
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
    call    _map_set_tile_value; top left
    ret


; Fallable blocks -------------------------------------------------------------
map_check_fallable_blocks:

    ; check if there are any blocks on the current screen
    ld      a,[mapFallableBlockCount]
    cp      0
    ret     z

    ; setup loop counter
    xor     a
    ld      b,a

.loop:

    ; get offset
    ld      de,mapFallableBlocks
    ld      h,0
    ld      l,b
    add     hl,hl; x 2
    add     hl,hl; x 4
    add     hl,de; get offset address

    ; check if inactive
    jr      .check_active
.check_active:
    ld      a,[hli]
    and     %00000001
    cp      1
    jr      z,.active
            
    ; skip frame
    inc     hl

    ; load block x coordinate
    ld      a,[hli]
    ld      c,a

    ; load player coordinates and convert into blocks
    ld      a,[playerX]
    srl     a; divide by 16
    srl     a; divide by 16
    srl     a; divide by 16
    srl     a; divide by 16
    cp      c
    jr      z,.found_x

    ld      a,[playerX]
    add     PLAYER_HALF_WIDTH - 3
    srl     a; divide by 16
    srl     a; divide by 16
    srl     a; divide by 16
    srl     a; divide by 16
    cp      c
    jr      z,.found_x

    ld      a,[playerX]
    sub     PLAYER_HALF_WIDTH - 2
    srl     a; divide by 16
    srl     a; divide by 16
    srl     a; divide by 16
    srl     a; divide by 16
    cp      c
    jr      z,.found_x
    jr      .active

    ; load block y coordinate
.found_x:
    ld      a,[hl]
    ld      c,a

    ; check the block 2 pixel under the player
    ; TODO check if in upper half of block only ?
    ld      a,[playerY]
    add     1
    srl     a; divide by 16
    srl     a; divide by 16
    srl     a; divide by 16
    srl     a; divide by 16
    cp      c
    jr      nz,.active

    dec     hl
    dec     hl
    dec     hl

    ; if near set active
    ld      a,[hl]
    and     %00000010; reset everything but type
    or      %00000001; type / active flag
    ld      [hl],a

    ; check player movement speed
    ld      a,[playerSpeedRight]
    ld      b,a
    ld      a,[playerSpeedLeft]
    or      b
    and     %00000010
    jr      nz,.delayed

    ; setup instant fall and play sound
    call    _map_update_falling_block
    ld      a,SOUND_MAP_FALLING_BLOCK
    call    sound_play
    jr      .active

.delayed:
    ; setup drop delay
    ld      a,[hl]
    or      MAP_FALLABLE_BLOCK_DELAY << 4
    ld      [hl],a

    ; loop
.active:
    inc     b
    ld      a,[mapFallableBlockCount]
    cp      b
    jp      nz,.loop
    ret


map_update_falling_blocks:
    ld      a,[mapFallableBlockCount]
    cp      0
    ret     z

    ; setup loop counter
    xor     a
    ld      b,a

.loop:

    ; get offset
    ld      de,mapFallableBlocks
    ld      h,0
    ld      l,b
    add     hl,hl; x 2
    add     hl,hl; x 4
    add     hl,de; get offset address

    ; check if active
    ld      a,[hl]
    and     %00000001
    cp      1
    jr      nz,.inactive

    ; check for delay
    ld      a,[hl]
    swap    a
    and     %00001111
    cp      0
    jr      nz,.delayed

    call    _map_update_falling_block
    jr      .inactive

.delayed:
    ; decrease delay
    ld      a,[hl]
    swap    a
    dec     a
    swap    a
    ld      [hl],a
    and     %11110000
    jr      nz,.inactive

    ; play sound if the delay reached 0
    ld      a,SOUND_MAP_FALLING_BLOCK
    call    sound_play

    ; loop
.inactive:
    inc     b
    ld      a,[mapFallableBlockCount]
    cp      b
    jr      nz,.loop
    ret


_map_update_falling_block: ; b = index

    inc     hl; skip flags

    ; check frame count
    ld      a,[hl]
    cp      4
    ret     z

    ; next frame
    ld      a,[hl]
    inc     a
    ld      [hl],a

    ; store loop counter and frame pointer 
    push    bc
    push    hl

    ; skip frame count
    ld      a,[hl]
    ld      d,a; store frame count
    inc     hl

    ; load x / y coordinates
    ld      a,[hli]; load x
    ld      b,a
    ld      a,[hl]; load y
    ld      c,a
    sla     b; convert into 8x8 index
    sla     c; convert into 8x8 index

    ; check tile color
.light:
    ld      a,d
    cp      4
    jr      z,.done_light
    ld      a,MAP_FALLING_TILE_LIGHT
    add     d
    ld      e,a
    add     4
    jr      .set

.done_light:
    ld      a,MAP_BACKGROUND_TILE_LIGHT
    ld      e,a

.set:
    call    _map_set_tile_value
    inc     b
    ld      a,e
    call    _map_set_tile_value

    ; restore frame pointer
    pop     hl
    pop     bc

.done:
    ret


; Helpers ---------------------------------------------------------------------
_map_get_tile_collision:
    push    hl

    ; get offset into collision table
    call    _map_get_tile_value
    ld      hl,DataTileCol ; needs to be aligned at 256 bytes
    ld      l,a
    ld      a,[hl]

    pop     hl
    ret


_map_get_tile_value: ; b = tile x, c = tile y -> a = value
    ; gets the tile value from the room data buffer (not VRAM!)
    ; trashes hl and bc

    ld      a,b ; store x

    ; y * 32
    ld      h,0 
    ld      l,c

    add     hl,hl ; 2
    add     hl,hl ; 4
    add     hl,hl ; 8
    add     hl,hl ; 16
    add     hl,hl ; 32

    ; + mapRoomTileBuffer + x
    ld      b,mapRoomTileBuffer >> 8; high byte, needs to be aligned at 256 bytes
    ld      c,a ; restore x
    add     hl,bc

    ; load tile value from background buffer
    ld      a,[hl]
    sub     128 ; convert into 0-255 range

    ret


_map_set_tile_value: ; b = tile x, c = tile y, a = value
    ; sets the tile value in the both the room data buffer and the screen buffer

    push    de
    push    hl

    ; convert tile into -127-128 range and store into d
    add     128
    ld      d,a ; store tile value
    ld      e,b ; store xpos

    ; calculate base offset for the tile into either buffer
    ld      h,0 
    ld      l,c
    add     hl,hl ; x2
    add     hl,hl ; x4
    add     hl,hl ; x8
    add     hl,hl ; x16
    add     hl,hl ; x32

    ; set tile value in map buffer
    push    hl
    ld      a,d; temp store tile value
    ld      d,mapRoomTileBuffer >> 8; high byte, needs to be aligned at 256 bytes
    add     hl,de
    ld      [hl],a; set tile in map buffer
    pop     hl

    ; set tile value in screen buffer
    ld      d,a
    ld      a,[mapCurrentScreenBuffer]
    cp      0
    jp      z,.screen_9c
    ld      a,d; restore
    ld      d,$98
    jp      .set

.screen_9c:
    ld      a,d; restore
    ld      d,$9c

.set:
    add     hl,de
    ld      d,a; restore tile value

    ; wait for vram to be safe
    ld      a,[rSTAT]       ; <---+
    and     STATF_BUSY      ;     |
    jr      nz,@-4          ; ----+

    ; set tile value
    ld      a,d
    ld      [hl],a

    pop     hl
    pop     de

    ret


; Map Loading Helpers ---------------------------------------------------------
; -----------------------------------------------------------------------------
_map_load_room_pointer:; b = x, c = y -> bc = pointer to packed room data

    ; base pointer for the map
    ld      hl,DataMapMain

    ; id = x * (y * 16)
    sla     c; x2
    sla     c; x4
    sla     c; x8
    sla     c; x16
    ld      a,c
    add     b;
    ld      b,a

.next:
    ; check if we found the room we're looking for
    ret     z; compare against the result of add b / dec b

    ; else read length byte and skip room data
    ld      a,[hli]
    add     a,l
    ld      l,a
    adc     a,h
    sub     l
    ld      h,a

    ; check next room
    dec     b
    jr      .next
    ret


_map_load_animations:
    ld      a,[mapRoomHeaderFlags]
    and     %00000001
    ld      b,0; per default animations are off
    cp      1
    jr      nz,.skip_animation_byte

    ; load animation attribute byte
    ld      a,[hli]
    ld      b,a; store into b

.skip_animation_byte:

    ; set active animation data (b = animation attribute byte)
    ld      de,mapAnimationUseMap
    ld      c,TILE_ANIMATION_COUNT / 2; 8 bits to check

    ; each time we check bit 0 and flag two animations active
.next_animation_byte:
    xor     a
    bit     0,b
    jr      z,.set_animation_byte; if not set, set the value to 0
    ld      a,1; otherwise we load a 1

.set_animation_byte:
    ld      [de],a
    inc     de
    ld      [de],a
    inc     de
    srl     b; shift to next byte
    dec     c
    jr      nz,.next_animation_byte
    ret


_map_load_tile_map:

    ; load and setup the rooms tile block definition mapping
    ld      a,[mapRoomHeaderFlags]
    bit     1,a; check if this room has a custom tile block map
    ld      a,$0f; default mapping 
    jr      z,.skip_tile_map_byte
    ld      a,[hli]

.skip_tile_map_byte:
    ld      [mapRoomTileBlockMap],a; store mapping
    ret


_map_load_block_definitions:

    ; compare with old room mapping
    ld      a,[mapRoomTileLastBlockMap]
    ld      b,a

    ; check if the mapping changed
    ld      a,[mapRoomTileBlockMap]
    cp      b
    ret     z

    ld      [mapRoomTileLastBlockMap],a
    ld      c,a
    ld      b,0

    ; now setup the tile mappings into the corresponding ram section
    xor     a
.next:
    bit     0,c
    jr      z,.not_mapped; if not set, skip this mapping

    ; load the 4 8x8 tiles for the 64 corresponding blocks
    call    _map_load_tile_block
    inc     b

.not_mapped:
    srl     c; shift to next bit

    ; we check 8 bits we DO not expect more than 4 blocks to be active
    inc     a
    cp      8
    jr      nz,.next

    ret


_map_load_tile_block: ; a = origin block, b = target block
    push    af
    push    bc

    ; setup target location
    ld      h,0
    ld      l,b
    add     hl,hl; x64
    add     hl,hl
    add     hl,hl
    add     hl,hl
    add     hl,hl
    add     hl,hl
    ld      bc,mapBlockDefinitionBuffer
    add     hl,bc; add data location
    ld      b,h; move into bc
    ld      c,l

    ; setup origin
    ld      h,0
    ld      l,a
    add     hl,hl; x64
    add     hl,hl
    add     hl,hl
    add     hl,hl
    add     hl,hl
    add     hl,hl
    ld      de,DataBlockDef
    add     hl,de; add data location

    ; copy
	ld      d,64
.loop:
    ld	    a,[hl]
	ld	    [bc],a
    inc     h
    inc     b

    ld	    a,[hl]
	ld	    [bc],a
    inc     h
    inc     b

    ld	    a,[hl]
	ld	    [bc],a
    inc     h
    inc     b

    ld	    a,[hl]
	ld	    [bc],a

    dec     h
    dec     h
    dec     h
    dec     b
    dec     b
    dec     b

    inc     hl
	inc	    bc

.skip:
	dec	    d
	jr	    nz,.loop

    pop     bc
    pop     af
    ret
    

_map_load_entities:

    ; copy entity data after room tile buffer
    ld      a,[mapRoomHeaderFlags]; restore room flags
    swap    a
    and     %00001111
    ld      [mapRoomEntityCount],a
    ld      b,0
    ld      c,a
    sla     c ; each entity has two bytes so we multiple by two here
    ld      de,mapRoomBlockBuffer + MAP_ROOM_SIZE
    call    core_mem_cpy
    ret


_map_load_room_data:
    
    xor     a
    ld      [mapRoomUpdateRequired],a
    ld      [mapFallableBlockCount],a

    ; target is the screen buffer
    ld      hl,mapRoomTileBuffer

    ; we read from the unpacked room data
    ld      de,mapRoomBlockBuffer

    ; setup loop counts
    ld      b,8 ; row
    ld      c,0 ; col

.loop_y:

    ; y loop header
    ld      a,b
    cp      0
    jr      z,.done
    dec     b

    ; y loop body
    ld      c,10

.loop_x:

    ld      a,[de] ; fetch next 16x16 block
    inc     de

    dec     c ; reduce column counter

.draw_block:

    ; draw four 8x8 tiles via the block definitions from the 16x16 block
    push    hl
    push    de

    ; drawing ------------------------------------------
    push    bc; store row / col
    
    ld      d,a ; save block data
    ld      c,d ; low byte index into block definitions

    ; upper left
    ld      b,mapBlockDefinitionBuffer >> 8 ; block def row 0 offset
    ld      a,[bc] ; tile value
    ld      [hli],a ;  draw + 0

    ; upper right
    ld      b,mapBlockDefinitionBuffer >> 8 + 1 ; block def row 1 offset
    ld      a,[bc] ; tile value
    ld      [hl],a ; draw +1

    ; skip one screen buffer row
    ld      b,0
    ld      c,31
    add     hl,bc
    ld      c,d

    ; lower left
    ld      b,mapBlockDefinitionBuffer >> 8 + 2 ; block def row 2 offset
    ld      a,[bc] ; tile value
    ld      [hli],a ; draw + 32

    ; lower right
    ld      b,mapBlockDefinitionBuffer >> 8 + 3 ; block def row 2 offset
    ld      a,[bc] ; tile value
    ld      [hl],a ; draw + 33

    pop     bc; restore row / col

    ; check for falling blocks -------------------------
    ld      a,d
    cp      MAP_FALLABLE_BLOCK_LIGHT
    jr      nz,.normal_block

    ; get current index
    ld      a,[mapFallableBlockCount]
    cp      MAP_MAX_FALLABLE_BLOCKS
    jr      z,.normal_block; maximum index reached skip

    ld      de,mapFallableBlocks
    ld      h,0
    ld      l,a
    add     hl,hl; x 2
    add     hl,hl; x 4
    add     hl,de; get offset address
    
    ; store tile type (dark / light) and reset active
    ; TODO store correct value based on tile value
    ld      a,%00000010; 7 bytes type, 1 bytes active
    ld      [hli],a

    ; reset frames 
    xor     a;
    ld      [hli],a

    ; store x and y coordinates
    ld      a,9
    sub     c
    ld      [hli],a; x / col
    ld      a,7
    sub     b
    ld      [hli],a; y / row

    ; next index
    ld      a,[mapFallableBlockCount]
    inc     a
    ld      [mapFallableBlockCount],a


    ; drawing ------------------------------------------
.normal_block:
    pop     de
    pop     hl

    ; next x block (we skip two 8x8 tiles in the background buffer)
    inc     hl
    inc     hl

    ; x loop end
    ld      a,c
    cp      0
    jr      nz,.loop_x

    ; y loop end (skip one 16x16 screen data row)
    ld      a,44 ; 12 8x8 tiles left on this row + one full row of 32
    add     a,l
    ld      l,a
    adc     a,h
    sub     l
    ld      h,a

    jr      .loop_y


.done:
    ld      a,1
    ld      [mapRoomUpdateRequired],a
    ret

