SECTION "EffectLogic",ROM0

effect_init:
    ;ld      b,11
    ;ld      c,112
    ;ld      a,12
    ;call    effect_create
    ret


; Update all active Effects ---------------------------------------------------
effect_update:
    ld      l,0

_effect_update: ; l = reset

    ; effect state pointer
    ld      de,effectScreenState
    ld      h,0

.loop:
    ; check active flag
    ld      a,[de]
    and     %1000_0000
    cp      0
    jr      z,.next; not active skip

    ; check if in reset mode
    ld      a,l
    cp      1
    jr      z,.reset

    ; update sprite
    push    hl
    push    de
    call    _update_effect_sprite
    pop     de
    pop     hl

    ; check if still active
    jr      c,.next

.reset:
    ; clear flags
    ld      a,[de]
    and     %0011_1111
    ld      [de],a
    push    de
    call    _effect_reset
    pop     de

.next:
    inc     h
    ld      a,e
    add     EFFECT_BYTES
    ld      e,a
    cp      (effectScreenState + EFFECT_MAX_COUNT * EFFECT_BYTES) & $ff
    jp      nz,.loop
    ret


; Create a new Effect ---------------------------------------------------------
effect_create:; a = effect type, b = ypos, c = xpos

    ; get free animation slot
    ld      de,effectScreenState

    ; effect index
    ld      h,0

    ; store effect type
    ld      l,a

.loop:
    ; load type / active
    ld      a,[de]
    and     %1000_0000
    cp      0
    jr      nz,.skip; active, skip
    ld      a,l; restore effect index
    call     _effect_create
    ret

.skip:
    inc     h
    ld      a,e
    add     EFFECT_BYTES
    ld      e,a
    cp      (effectScreenState + EFFECT_MAX_COUNT * EFFECT_BYTES) & $ff
    jp      nz,.loop
    ret


; Reset all active Effects ----------------------------------------------------
effect_reset:
    ld      l,1
    call    _effect_update
    ret


_effect_create:; a = effect index, de = effect data pointer, b = ypos, c = xpos

    ; multiply effect animation index by 8
    add     a
    add     a
    add     a

    ; setup effect data index
    push    bc
    ld      hl,DataEffectAnimation
    ld      b,0
    ld      c,a
    add     hl,bc
    pop     bc

    ; load effect animation row
    ld      a,[hli]
    inc     a; offset animation row by 1
    push    hl
    push    de
    push    bc
    call    _effect_get_animation_quad
    ld      [coreTmp],a; store animation quad
    pop     bc
    pop     de
    pop     hl

    ; return early if we could not load the effect animation quad
    cp      $ff
    ret     z

    ; load flags
    ld      a,[hli]
    or      %1000_0000; set active flag
    ld      [de],a
    inc     e

    ; load dy from effect animation
    ld      a,[hli]
    ld      [de],a
    inc     e

    ; store ypos
    ld      a,b
    ld      [de],a
    inc     e

    ; store xpos
    ld      a,c
    ld      [de],a
    inc     e

    ; reset animation delay offset
    xor     a
    ld      [de],a
    inc     e

    ; load animation delay
    ld      a,[hli]
    ld      [de],a
    inc     e

    ; load animation loop count
    ld      a,[hli]
    ld      [de],a
    inc     e

    ; load animation max index:
    ld      a,[hli]
    ld      [de],a
    inc     e

    ; reset effect animation index
    xor     a
    ld      [de],a
    inc     e

    ; store effect animation tile offset
    ld      a,[coreTmp]; multiply by 8
    ld      [de],a

    ret


_update_effect_sprite:; h = effect index, de = effect data pointer

    ; store effect sprite index
    ld      a,h
    add     a ; effect index * 4
    add     a

    ; load sprite oam address
    ld      l,a
    ld      h,spriteOam >> 8

    ; load effect flags
    ld      a,[de]
    ld      b,a; store flags
    inc     e

    ; check fore- / background flag and update hardware sprite  index
    and     %0001_0000
    jr      nz,.background
    ld      a,l
    add     EFFECT_FG_SPRITE_INDEX * 4
    ld      l,a
    jr      .update

.background:
    ld      a,l
    add     EFFECT_BG_SPRITE_INDEX * 4
    ld      l,a

.update:

    ; load dy
    ld      a,[de]
    inc     e
    cp      0
    jr      z,.no_move
    ld      c,a; store dy for add
    sub     $80
    jr      c,.add_y

.sub_y:
    ; only move every specified frame
    ld      c,a; store dy for sub
    ld      a,[coreLoopCounter]
    sub     c
    jr      c,.no_move
    ld      a,[de]
    dec     a
    jr      .update_y

.add_y:

    ; only move every specified frame
    ld      a,[coreLoopCounter]
    sub     c
    jr      c,.no_move
    ld      a,[de]
    inc     a
    jr      .update_y

.no_move:
    ld      a,[de]

.update_y:

    ; store updated ypos
    ld      [de],a
    ld      c,a
    inc     e

    ; check for water collision mode
    ld      a,b
    and     %0100_0000
    cp      %0100_0000
    jr      nz,.transparency

    ; load xpos
    push    bc
    ld      a,[de]
    sub     4; horizonal center of sprite
    ld      b,a

    ; divide x by 8
    srl     b
    srl     b
    srl     b

    ; divide y by 8
    ld      a,c
    sub     4;
    srl     a
    srl     a
    srl     a
    ld      c,a

    ; check tile collision value for deep water
    call    map_get_tile_collision
    pop     bc
    cp      MAP_COLLISION_WATER_DEEP
    jp      nz,.disable

    ; check for transparency
.transparency:
    ld      a,b
    and     %0010_0000
    cp      %0010_0000
    jr      nz,.update_x

    ; move the sprite to y 0 on every other frame to emulate 50% transparency
    ld      a,[coreLoopCounter]
    and     %0000_0001
    jr      nz,.update_x
    xor     a
    ld      c,a

.update_x:

    ; load and set updated ypos
    ld      a,b
    and     %1000_0000
    cp      %1000_0000
    jr      nz,.not_active

    ; only add scroll offset for active effects to avoid hiding issues
    ld      a,[coreScrollY]
    add     c
    ld      c,a

.not_active:
    ld      a,c
    ld      [hli],a

    ; load and set xpos
    ld      a,[de]
    ld      c,a
    ld      a,[coreScrollX]
    add     c
    inc     e
    ld      [hli],a

    ; load animation delay offset
    ld      a,[de]
    inc     a
    ld      [de],a
    ld      c,a
    inc     e

    ; load animation delay and compare offset
    ld      a,[de]
    cp      c
    jr      nz,.no_index_advance

    ; store flags
    push    bc

    ; reset delay offset
    dec     e
    xor     a
    ld      [de],a
    inc     e; skip delay offset
    inc     e; skip delay
    inc     e; skip loops left
    ld      a,[de]; load max animation index
    ld      b,a; store max animation index
    inc     e

    ; advance frame index
    ld      a,[de]
    inc     a
    ld      c,a; store frame index
    cp      b
    jr      nz,.no_overflow
    xor     a; reset animation frame

.no_overflow:
    ld      [de],a
    dec     e
    dec     e; back to loops left

    ; check if the animation looped
    ld      a,c
    cp      b

    ; restore flags
    pop     bc
    jr      nz,.update_index

    ; update loops left
    ld      a,[de]
    cp      $ff
    jr      z,.update_index; endless looping with $ff
    dec     a
    cp      0; disable effect if no loops are left
    jr      z,.disable
    ld      [de],a
    jr      .update_index

.no_index_advance:
    inc     e; skip animation delay

    ; load frame index
.update_index:
    inc     e; skip loops left
    inc     e; skip max index
    ld      a,[de]
    ld      c,a
    inc     e

    ; load animation tile offset and add current animation index
    ld      a,[de]
    add     a
    add     a
    add     a
    add     $60; add base tile offset
    add     c; add current animation index * 2
    add     c
    inc     e

    ; update animation tile
    ld      [hli],a; tile index

    ; update sprite palette
    ld      a,[coreColorEnabled]
    cp      1
    jr      z,.color

    ; adjust palette and flags for DMG
    ld      a,b
    and     %0000_0111
    swap    a
    ld      b,a
    jr      .palette

.color:

    ; adjust palette and and flags for GBC
    ld      a,b
    and     %0000_0111
    ld      b,a
    swap    a
    or      b
    and     %0110_0001; only use the first palette index bit
    ld      b,a

.palette:
    ld      a,b
    ld      [hl],a

    ; mark as active
    scf
    ret

.disable:
    ; mark as disable
    and     a
    ret


_effect_reset:

    push    hl
    push    de

    ; store effect index
    ld      b,h

    ; skip effect flags and dy
    inc     e
    inc     e

    ; clear ypos
    xor     a
    ld      [de],a

    ; skip effect data until animation tile
    ld      a,e
    add     6
    ld      e,a

    ; decrease effect quad usage
    ld      a,[de]; load quad index
    add     a; multiply by 2
    ld      hl,effectQuadsUsed
    add     l
    ld      l,a
    dec     [hl]; decrease usage

    ; hide hardware sprite
    ld      h,b; restore effect index
    pop     de
    call    _update_effect_sprite
    pop     hl
    ret


; Tile Quad Management --------------------------------------------------------
_effect_get_animation_quad: ; a = animation row index -> a loaded effect quad

    ; store animation row index
    ld      d,a

    ; effect quad index
    ld      b,$ff

    ; go through all available effect quads
    ld      c,EFFECT_MAX_TILE_QUADS - 1
    ld      hl,effectQuadsUsed + EFFECT_MAX_TILE_QUADS * 2 - 1

.loop:

    ; check quad animation index
    ld      a,[hld]
    cp      d
    jr      nz,.check_unused

    ; increase usage count
    inc     [hl]

    ; found already loaded quad with same animation row index
    ld      b,c
    jr      .done

.check_unused:

    ; check usage count
    ld      a,[hl]
    cp      0
    jr      nz,.next

    ; increase usage count
    inc     a
    ld      [hli],a

    ; set quad animation row index
    ld      a,d
    ld      [hl],a

    ; load animation row into target quad
    ld      b,c; setup target quad index
    push    bc
    dec     a ; correct row offset for loading
    call    _effect_load_tiles
    pop     bc

    ; loaded new quad
    jr      .done

.next:
    dec     hl; skip usage count
    dec     c
    jp      nz,.loop

    ; return the quad
.done:
    ld      a,b
    ret


_effect_load_tiles:; a = animation row index, b = tile quad index

    ld      c,a

    ; multiply quad index
    ld      h,b
    ld      e,$80
    call    math_mul8b

    ; calculate tile ram offset
    ld      de,$8600
    add     hl,de
    ld      d,h
    ld      e,l

    ; load high byte of tile map address
    ld      hl,DataEffectImg

    ; decompress sprite row into vram
    ld      b,0 ; offset into location table
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

