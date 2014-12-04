SECTION "SpriteLogic",ROM0

; Update all Sprites ----------------------------------------------------------
new_sprite_update:

    ; update sprite row information
    call    _new_sprite_update_tile_rows

    ; initial sprite pointer
    ld      a,0
    call    _get_new_sprite_pointer

    ; unrolled sprite update loop
    call    _new_sprite_update
    inc     l
    call    _new_sprite_update
    inc     l
    call    _new_sprite_update
    inc     l
    call    _new_sprite_update
    inc     l
    call    _new_sprite_update

    ret


new_sprite_enable: ; a = sprite id
    push    hl
    call    _get_new_sprite_pointer

    ; check if sprite is already enabled
    bit     7,[hl]
    jr      nz,.done

    ; set enabled
    set     7,[hl]

    ; unset wasEnabled
    res     6,[hl]

    ; skip flags
    inc     l

    ; unset tile row
    ld      a,$ff
    ld      [hli],a

    ; unset animations frames left
    ld      [hli],a

    ; unset animation id
    ld      [hli],a

    ; reset animation index
    xor     a
    ld      [hli],a

    ; reset animation frame
    ld      [hli],a

.done:
    pop     hl
    ret

new_sprite_disable: ; a = sprite id
    push    hl
    call    _get_new_sprite_pointer

    ; check if sprite is actually enabled
    bit     7,[hl]
    jr      z,.done

    ; unset enabled
    res     7,[hl]

    ; set wasEnabled
    set     6,[hl]
    inc     l

    ; mark the sprite's tile row as "was used"
    ld      a,[hl]
    call    _new_sprite_tile_row_set_was_used

.done:
    pop     hl
    ret

new_sprite_set_animation:; a = sprite id, b = animation id
    push    hl
    call    _get_new_sprite_pointer

    ; mark as changed
    set     4,[hl]
    inc     l
    inc     l

    ; reset frames left
    xor     a
    ld      [hli],a

    ; set animation id
    ld      [hl],b
    inc     l
    
    ; reset animation index
    ld      [hli],a

    ; reset animation frame
    ld      [hl],a

    pop     hl
    ret

new_sprite_set_palette:; a = sprite id, b = palette index
    push    hl
    call    _get_new_sprite_pointer

    ; load flags
    ld      a,[hl]
    and     %11110000; mask of palette bits
    or      b; or with palette index (bits 2-0)
    ld      [hl],a

    pop     hl
    ret

new_sprite_set_mirrored:; a = sprite id
    push    hl
    call    _get_new_sprite_pointer

    ; set mirrored flag
    set     5,[hl]

    pop     hl
    ret

new_sprite_unset_mirrored:; a = sprite id 
    push    hl
    call    _get_new_sprite_pointer

    ; unset mirrored flag
    res     5,[hl]

    pop     hl
    ret

new_sprite_set_hardware_index:; a = sprite id, b = hardware sprite index
    push    hl
    call    _get_new_sprite_pointer
    ld      a,l
    add     8
    ld      l,a
    ld      [hl],b
    pop     hl
    ret

new_sprite_set_position:; a = sprite id, b = x, c = y
    push    hl
    call    _get_new_sprite_pointer
    set     3,[hl]
    ld      a,l
    add     6
    ld      l,a
    ld      [hl],b
    inc     l
    ld      [hl],c
    pop     hl
    ret


; Update a Single Sprite (using 2 8x16 hardware sprites) ----------------------
_new_sprite_update: ; hl = sprite data pointer

    ; load flags
    ld      a,[hli]

    ; check if the sprite is enabled
    bit     7,a
    jp      z,.disabled

    ; store flags
    ld      c,a

    ; check if animation changed
    and     %00010000
    jr      z,.animate

.update_animation_tiles:

    ; check if there is a tile row available to use
    ld      a,[coreSpriteRow]
    cp      $ff
    jp      z,.skip ; if not wait until the next frame

    ; check if the sprite was using a tile row in the first place
    ld      a,[hl]
    cp      $ff
    jr      z,.no_row_used

    ; mark the old row as "was used"
    call    _new_sprite_tile_row_set_was_used; a is the tile row index

.no_row_used:

    ; store sprite pointer
    push    hl

    ; update the sprite's tile row
    ld      a,[coreSpriteRow]
    ld      b,a; copy into b for sprite loading
    ld      [hli],a

    ; mark the new row as used
    call    _new_sprite_tile_row_set_used; a is the tile row index

    inc     l; skip frames left

    ; load tile row data into vram
    ld      a,[hl]; load animation id

    ; store flags
    push    bc
    call    _new_sprite_load_tiles
    pop     bc

    ; restore sprite pointer
    pop     hl

    ; unset the unused row index until the next frame
    ld      a,$ff
    ld      [coreSpriteRow],a

    ; unset animation changed flag of the sprite
    dec     l
    res     4,c; make sure to reset the flag bit to avoid palette messups
    res     4,[hl]
    inc     l

    ; next animation frame
.animate:

    ; load tile row that is used by the sprite and multiply it by 16
    ; in order to adjust for the tile data offset in vram
    ld      a,[hli]
    add     a; x 16
    add     a
    add     a
    add     a

    ; store tile row offset into b
    ld      b,a

    ; check number of frames left
    ld      a,[hl]
    cp      0
    jr      nz,.wait_animation

    ; check for stopped length
    cp      $ff
    jr      z,.halt_animation
    
    ; load next animation frame data
    inc     l; skip frames left

.next_animation_frame:

    ; load animation id
    ld      a,[hli]

    ; load animation pointer into de (TODO optimize)
    push    hl
    call    _get_animation_pointer
    ld      d,h
    ld      e,l
    pop     hl

    ; load animation index, and increase it
    ld      a,[hl]
    inc     a
    ld      [hli],a
    add     3; add initial offset for animation header

    ; add offset to base pointer of animation 
    add     e
    ld      e,a
    adc     a,d
    sub     e
    ld      d,a
    
    ; load frame value from animation
    ld      a,[de]
    
    ; check for end marker
    cp      $ff
    jr      z,.stop_animation

    ; check for loop marker ($fe)
    cp      $fe
    jr      nz,.advance_animation

.loop_animation:
    dec     l; go back to index

    ; set index back to 0
    xor     a
    ld      [hld],a; go back to id
    jr      .next_animation_frame

.stop_animation:

    ; go back to frames left and set to $ff
    dec     l; back to index
    dec     l; back to id
    dec     l; back to frames left
    ld      [hli],a; set frames left to $ff
    jr      .halt_animation

.advance_animation:

    ; write frame value to sprite data
    ld      [hld],a; going back to index

    dec     l; go back to id
    dec     l; go back to frames left
    
    ; add offset for animation frame data
    ld      a,14
    add     e
    ld      e,a
    adc     a,d
    sub     e
    ld      d,a

    ; load new frame length
    ld      a,[de]

.wait_animation:

    ; reduce frames left
    dec     a
    ld      [hli],a

.halt_animation:
    inc     l; skip animation index
    inc     l; skip animation id

    ; load animation frame value and multiply by 4
.set_animation_frame:
    ld      a,[hli]
    add     a
    add     a

    ; check for frame value of $04 and hide sprite
    cp      16
    jr      nz,.set_animation_tile

    ; setup 0x0 position to hide the sprite
    ld      e,0
    inc     l

    ld      d,0
    inc     l
    jr      .draw_hardware_sprite

.set_animation_tile:
    ; add tile row offset to animation frame offset
    add     b
    ld      b,a

    ; load sprite x position
    ld      a,[hli]
    ld      d,a

    ; add x scroll offset
    ld      a,[coreScrollX]
    add     d
    ld      d,a

    ; load sprite y position
    ld      a,[hli]
    ld      e,a

    ; add y scroll offset
    ld      a,[coreScrollY]
    add     e
    ld      e,a

.draw_hardware_sprite:

    ; load sprite index
    ld      a,[hl]

    ; now update the actual hardware sprites
    push    hl
    call    _new_sprite_update_hardware
    pop     hl

    ret

.disabled:

    ; check if the sprite was previously enabled
    and     %01000000
    jr      z,.skip

    ; if it was, move it off screen and unset the wasEnabled flag
    dec     l
    res     6,[hl]

    ; load sprite index
    ld      a,l
    add     8
    ld      l,a
    ld      a,[hl]

    ; move hardware sprites off screen to hide it
    ld      d,0
    ld      e,0
    push    hl
    call    _new_sprite_update_hardware
    pop     hl

    ; setup pointer to next sprite
    ret     

.skip:
    ; skip to next sprite
    ld      a,l
    add     7
    ld      l,a
    ret


_new_sprite_update_hardware:; a = sprite index, b = tile index, c = flags, d = xpos, e = ypos

    ; multiply sprite index by 16 to get the hardware offset 
    ; as uneven sprites are consumed by the 8x16 sprite mode
    ; and we need two of these 8x16 sprites to show a full 16x16 sprite
    add     a
    add     a
    add     a
    add     a

    ; load the low byte of the first hardware sprite's address
    ld      l,a

    ; load the high byte of the first hardware sprite's address
    ld      h,spriteOam >> 8

    ; adjust palette bits
    ld      a,[coreColorEnabled]
    cp      1
    jr      z,.direction

    ; adjust palette for DMG
    ld      a,c
    and     %00000001; mask of unused palette bits
    swap    a
    or      c
    ld      c,a

.direction:

    ; mask of non used sprite flag bits
    ld      a,c
    and     %00110111
    ld      c,a

    ; setup tile index correction for second sprite
    ld      a,2

    ; check if the sprite is mirrored
    bit     5,c
    jr      z,.first
    
.right:; mirrored direction, facing left, sprite tiles get switch

    ; add tile index offset for first sprite
    inc     b
    inc     b

    ; setup tile index correction for second sprite
    ld      a,$FE

.first:

    ; first hardware sprite
    ld      [hl],e; ypos
    inc     l
    ld      [hl],d; xpos
    inc     l
    ld      [hl],b; tile index
    inc     l
    ld      [hl],c
    inc     l

    ; add index correction for second sprite
    add     b
    ld      b,a

    ; add x position offset for second sprite
    ld      a,d
    add     8
    ld      d,a

    ; second hardware sprite
    ld      [hl],e; ypos
    inc     l
    ld      [hl],d; xpos
    inc     l
    ld      [hl],b; tile index
    inc     l
    ld      [hl],c

    ret


; Tile Row Management ---------------------------------------------------------
_new_sprite_load_tiles:; a = animation id, b = tile row index

    ; load animation data address and row index
    call    _get_animation_pointer
    
    ; load source tile row
    ld      a,[hli]
    ld      c,a

    ; load low byte of tile map address
    ld      a,[hli]
    
    ; load high byte of tile map address
    ld      h,[hl]
    ld      l,a

    ; decompress sprite row into vram
    ld      de,$8000
    call    _load_new_sprite_row

    ret


_new_sprite_update_tile_rows:

    ; go through all tile rows 
    ld      hl,spriteRowsUsed + 7
    ld      c,8; loop counter / row index
    ld      b,$ff; tmp var holding the last unused row

.loop:

    ; load row flag
    ld      a,[hl]

    ; check if the row was until the the previous frame and reset it for the next frame
    cp      2
    jr      z,.was_used
    
    ; check if the row is currently used
    cp      1
    jr      z,.next

    ; otherwise the row is available and we point the unused row index to it
    ld      a,b

    ; otherwise the row is available so we set b to it (correct for zero indexing)
    ld      b,c
    dec     b
    jr      .next

    ; mark the row as available on the next frame
.was_used:
    xor     a
    ld      [hl],a

.next:
    dec     l
    dec     c
    jr      nz,.loop

    ; store unused row index into high ram
    ld      a,b
    ld      [coreSpriteRow],a

    ret


_new_sprite_tile_row_set_was_used:; a = tile row index
    ld      de,spriteRowsUsed; base pointer
    add     e; add row index
    ld      e,a
    ld      a,2
    ld      [de],a; mark as used
    ret


_new_sprite_tile_row_set_used:; a = tile row index
    ld      de,spriteRowsUsed; base pointer
    add     e; add row index
    ld      e,a
    ld      a,1
    ld      [de],a; mark as used
    ret


; Helpers ---------------------------------------------------------------------
_get_new_sprite_pointer:; a = sprite index -> hl = pointer
    ld      h,spriteData >> 8; high byte, needs to be aligned at 256 bytes
    ld      l,a
    add     a; x 2
    add     a; x 4
    add     a; x 8
    add     l; x 9
    ld      l,a
    ret

_get_animation_pointer:; a = animation id -> hl = pointer
    ld      de,DataSpriteAnimation
    ld      h,0
    ld      l,a
    add     hl,hl; x32
    add     hl,hl
    add     hl,hl
    add     hl,hl
    add     hl,hl
    add     hl,de
    ret

; hl = sprite map pointer, b = target row in ram, c = row index in sprite map, de = target base in ram
_load_new_sprite_row: ; load a compressed tile row into vram

    ; adjust target pointer for target row
    ld      a,d 
    add     b
    ld      d,a

    ; offset into location table
    ld      b,0
    sla     c; each table entry is two bytes
    add     hl,bc ; hl = table offset data pointer

    ; read high and low byte for the offset
    ld      a,[hli]
    ld      b,a
    ld      a,[hli]
    ld      c,a; bc = offset until row data (from current table index position)

    ; create final data pointer for tile row data
    ; the offset value is pre calcuated to be relative from the table data pointer + 2
    add     hl,bc

    ; decode with end marker in stream
    call    core_decode_eom

    ret

