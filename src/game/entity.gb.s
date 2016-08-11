SECTION "EntityLogic",ROM0


; Update the on screen entites based on the type handler ----------------------
entity_update:

    ; check if entity updates are active
    ld      a,[entityUpdateActive]
    cp      0
    ret     z

    ; entity screen state pointer
    ld      de,entityScreenState

.loop:

    ; load type / active
    ld      a,[de]
    cp      0
    jr      z,.skip; not active skip
    cp      $ff
    jr      z,.skip; disabled
    ld      l,a ; store type

    ; get sprite index
    ld      a,e; divide e by 8
    srl     a
    srl     a
    srl     a
    add     ENTITY_SPRITE_OFFSET
    ld      c,a; store sprite index for update handler

    ; invoke custom entity update handler
    ld      a,l
    dec     a; convert into 0 based offset

    ld      hl,DataEntityUpdateHandlerTable
    add     a,a ; multiply entity type by 4
    add     a,a
    add     a,l ; add a to hl
    ld      l,a
    adc     a,h
    sub     l
    ld      h,a

    ; store counter, screen state address and indecies
    push    de
    push    bc
    call    _entity_handler_jump
    pop     bc
    pop     de

    ; check if the update handler disabled the entity
    ld      a,[de]
    cp      $ff
    jr      z,.disabled; not active skip

    inc     e; skip type
    inc     e; skip flags
    inc     e; skip direction

    ld      h,c; 
    ld      a,[de] ; y position
    ld      c,a
    inc     e

    ld      a,[de] ; x position
    ld      b,a

    ld      a,h; restore entity sprite index
    call    new_sprite_set_position

    inc     e; skip x
    inc     e; tileslot?
    inc     e; custom
    inc     e; custom
    jr      .next

.disabled:
    ld      a,c
    push    de
    call    new_sprite_disable
    pop     de

.skip:
    ld      a,e
    add     8
    ld      e,a

.next:
    ld      a,e
    cp      (entityScreenState + ENTITY_PER_ROOM * 8) & $ff
    jr      nz,.loop
    ret


; Load the entity state from RAM or the map default and  ----------------------
; Set up sprite and initial data based on type handler ------------------------
entity_load:

    ; set entity updates active
    ld      a,1
    ld      [entityUpdateActive],a

    ; get offset for entity map data
    ld      hl,mapRoomBlockBuffer + MAP_ROOM_SIZE
    ld      b,0

.loop:
    ld      a,[mapRoomEntityCount]
    cp      b
    ret     z

    ; get type / used
    ld      a,[hl]
    ld      c,a ; store byte
    and     %00111111 ; mask type bits
    jr      z,.next ; entity is not set for room

    ; init base state
    call    _entity_screen_offset_de

    ; set type
    ld      a,c
    and     %00111111 ; mask type bits
    ld      [de],a
    inc     e

    ; reset flags
    xor     a
    ld      [de],a
    inc     e

    ; set default direction 
    ld      a,c
    and     %11000000 ; mask type bits
    swap    a
    srl     a
    srl     a
    ld      [de],a

    call    _entity_load

    push    hl

    ld      a,c ; type / dir flags
    and     %00111111 ; mask type bits
    ld      l,a; store entity type

    ; set sprite hardware offset (index + bg/fg offset)
    ld      a,c; restore flags
    call    _entity_sprite_offset
    add     b; add entity index to offset
    ld      h,a; store hardware offset

    ; calculate and store sprite index into c
    ld      a,ENTITY_SPRITE_OFFSET
    add     b ; offset + entity index
    ld      c,a

    ; get screen entity offset
    call    _entity_screen_offset_de

    ; store entity and sprite index 
    push    bc

    ; enable sprite
    call    new_sprite_enable
    ld      b,h; setup hardware index
    ld      a,c; setup sprite index
    call    new_sprite_set_hardware_index

    ; Get palette flag
    ld      a,l; load type
    call    _entity_defintion
    and     %01000000
    swap    a
    srl     a
    srl     a
    ld      b,a
    ld      a,c
    call    new_sprite_set_palette

    ; call custom load handler
    ld      a,l
    dec     a; convert into 0 based offset
    ld      hl,DataEntityLoadHandlerTable
    add     a,a  ; multiply entity type by 4
    add     a,a
    add     a,l ; add a to hl
    ld      l,a
    adc     a,h
    sub     l
    ld      h,a

    ; call the load handler
    push    de
    call    _entity_handler_jump
    pop     de
    cp      1
    jr      z,.ignore_load

    ; set sprite position
    inc     e ; skip type
    inc     e ; skip flags
    inc     e ; skip direction

    ld      l,c ; restore sprite index
    ld      a,[de] ; load y position
    ld      c,a
    inc     e

    ld      a,[de] ; load x position
    ld      b,a
    ld      a,l ; load sprite index
    call    new_sprite_set_position

    pop     bc;  restore entity / loop index
    jr      .next

.ignore_load:
    pop     bc;  restore entity / loop index

    call    _entity_screen_offset_hl
    ld      [hl],0

    ld      a,c
    call    new_sprite_disable

.next:
    pop     hl
    inc     hl
    inc     hl

    inc     b
    ld      a,b
    cp      ENTITY_PER_ROOM
    jp      nz,.loop
    ret



; Load a single Entity's state ------------------------------------------------
_entity_load:

    ; check if an existing bucket that stores this entity 
    push    hl
    push    de
    push    bc
    call    _entity_get_current_room_id
    call    _entity_find_bucket ; c is the room id, b is the entity id, return a and hl

    cp      1
    jr      nz,.load_defaults

.load_stored:
    
    inc     hl; skip room id

    ; get entity screen offset for b into de
    call    _entity_screen_offset_de
    inc     e; skip type

    ; load flags, direction and entity id (FFFFDDII)
    ld      a,[hli]
    ld      b,a; store copy of original value into b

    ; get flags
    swap    a
    and     %00001111
    ld      [de],a; set flags
    inc     e

    ; get direction
    ld      a,b; load origin value one more time
    srl     a
    srl     a
    and     %00000011
    ld      [de],a; set direction
    inc     e

    ; load y position
    ld      a,[hli]
    ld      [de],a
    inc     e
    
    ; load x position
    ld      a,[hl]
    ld      [de],a
    inc     e

    ; restore registers
    pop     bc
    pop     de
    pop     hl
    ret


    ; load default data from map buffer
.load_defaults:

    ; restore registers
    pop     bc
    pop     de
    pop     hl

    ; push loop indicies
    push    hl
    push    de
    
    ; get entity screen offset for b into de
    call    _entity_screen_offset_de
    inc     e ; skip type
    inc     e ; skip flags
    inc     e ; skip direction

    ; skip stored type and direction
    inc     hl

    ; load x/y value
    ld      a,[hl]
    and     %11110000 ; y position, just works we can skip the x16 here
    add     16 ; anchor at the bottom
    ld      [de],a
    inc     e

    ; x position
    ld      a,[hl]
    and     %00001111 ; need to multiply by 16 here
    swap    a
    add     8
    ld      [de],a

    ; restore indicies
    pop     de
    pop     hl
    ret


; Store the entity state into RAM based on the type handler -------------------
; -----------------------------------------------------------------------------
entity_store:
    ld      de,entityScreenState
    ld      b,0

.loop:
    ld      a,[de]
    cp      0
    jr      z,.skip; entity is not loaded for this screen

    ; find a bucket to store this entity in, either the bucket which already
    ; stores it, or a unused one
    push    de
    call    _entity_get_last_room_id
    call    _entity_get_store_bucket
    pop     de

    ; did we find a bucket?
    cp      1
    jr      nz,.next

    ; store into bucket
    ; c is the room id, b is the entity id, hl is the pointer, de the screen data
    ld      a,c
    ld      [hli],a ; store room id

    inc     e ; skip type [0]
    
    ; combine flags, entity id and direction
    ; FFFFDDII
    ld      a,[de]; load flags
    inc     e 
    swap    a
    and     %11110000
    or      b; merge with id
    ld      b,a; store into b

    ld      a,[de] ; load direction
    inc     e
    add     a
    add     a
    and     %00001100
    or      b; merge with id and flags
    ld      [hli],a 

    ; y position
    ld      a,[de]
    inc     e
    ld      [hli],a 

    ; x position
    ld      a,[de]
    ld      [hl],a 

    ; skip x, tileslot, custom and custom
    inc     e
    inc     e
    inc     e
    inc     e
    jr      .next

.skip:
    ld      a,e
    add     8
    ld      e,a

.next:
    inc     b
    ld      a,b
    cp      ENTITY_PER_ROOM
    jr      nz,.loop
    ret


; Reset the entity screen state -----------------------------------------------
; -----------------------------------------------------------------------------
entity_reset:
    ld      hl,entityScreenState
    ld      b,0

.loop:
    ld      a,[hl]
    cp      0
    jr      z,.skip; not loaded

    ; disable sprite 
    ld      a,b
    add     ENTITY_SPRITE_OFFSET
    call    new_sprite_disable

    ; unset type
    xor     a
    ld      [hl],a

.skip:
    ld      de,8
    add     hl,de

.next:
    inc     b
    ld      a,b
    cp      ENTITY_PER_ROOM
    jr      nz,.loop
    ret


; Collision Wrappers ----------------------------------------------------------
; -----------------------------------------------------------------------------
entity_col_up:; b = x, c = y
    push    bc

    ld      a,c
    sub     17
    ld      c,a

    ; middle
    call    map_get_collision_simple
    jr      nz,.done

    ; left
    ld      a,b
    sub     7
    ld      b,a
    call    map_get_collision_simple
    jr      nz,.done

    ; right
    ld      a,b
    add     14
    ld      b,a
    call    map_get_collision_simple

.done:
    pop     bc
    ret
    

entity_col_down:; b = x, c = y
    push    bc

    ; middle
    call    map_get_collision_simple
    jr      nz,.done

    ; left
    ld      a,b
    sub     7
    ld      b,a
    call    map_get_collision_simple
    jr      nz,.done

    ; right
    ld      a,b
    add     14
    ld      b,a
    call    map_get_collision_simple

.done:
    pop     bc
    ret
    

entity_col_left:; b = x, c = y
    push    bc

    ; border
    ld      a,b
    sub     9
    ld      b,a

    ; bottom
    dec     c
    call    map_get_collision_simple
    jr      nz,.done

    ; middle
    ld      a,c
    sub     7
    ld      c,a
    call    map_get_collision_simple
    jr      nz,.done

    ; top
    ld      a,c
    sub     8
    ld      c,a
    call    map_get_collision_simple

.done:
    pop     bc
    ret
    

entity_col_right:; b = x, c = y
    push    bc

    ld      a,b
    add     8
    ld      b,a

    ; bottom
    dec     c
    call    map_get_collision_simple
    jr      nz,.done

    ; middle
    ld      a,c
    sub     7
    ld      c,a
    call    map_get_collision_simple
    jr      nz,.done

    ; top
    ld      a,c
    sub     8
    ld      c,a
    call    map_get_collision_simple

.done:
    pop     bc
    ret


entity_col_player:; a -> collision

    ; check player x > powerup x - 16 and player x < powerup y 

    ; check bottom edge
    ld      a,[de] ; y
    add     1
    ld      l,a
    ld      a,[playerY]
    cp      l
    jr      nc,.missed; edge > player

    ; check left edge
    ld      a,[de] ; y
    sub     15
    ld      l,a
    ld      a,[playerY]
    cp      l
    jr      c,.missed; edge < player

    ; check player x > powerup x - 8 and player x < powerup x + 8
    inc     de

    ; check right edge
    ld      a,[de] ; x
    add     7 
    ld      l,a
    ld      a,[playerX]
    cp      l
    jr      nc,.missed; edge > player

    ; check left edge
    ld      a,[de] ; x
    sub     6 
    ld      l,a
    ld      a,[playerX]
    cp      l
    jr      c,.missed; edge < player

    ld      a,1
    ret

.missed:
    xor     a
    ret



; Trampolin for entity logic handler ------------------------------------------
; -----------------------------------------------------------------------------
_entity_handler_jump:
    jp      [hl]


; Entity Sprite Handling ------------------------------------------------------
; -----------------------------------------------------------------------------
_entity_sprite_offset: ; a = sprite type -> a = background offset
    call    _entity_defintion
    and     %10000000
    cp      %10000000
    jr      z,.foreground
    ld      a,ENTITY_BG_SPRITE_INDEX
    ret

.foreground:
    ld      a,ENTITY_FG_SPRITE_INDEX
    ret


; Helper ----------------------------------------------------------------------
_entity_screen_offset_hl: ; b = entity index
    ld      h,entityScreenState >> 8; high byte, needs to be aligned at 256 bytes
    ld      l,b
    sla     l
    sla     l
    sla     l
    ret


_entity_screen_offset_de: ; b = entity index
    ld      d,entityScreenState >> 8; high byte, needs to be aligned at 256 bytes
    ld      e,b
    sla     e
    sla     e
    sla     e
    ret


_entity_defintion: ; a = sprite type
    push    hl
    ld      hl,DataEntityDefinitions

    dec     a; convert into zero based index

    ; a x 8
    add     a
    add     a
    add     a

    ; hl + a
    add     a,l
    ld      l,a
    adc     a,h
    sub     l
    ld      h,a

    ; load definition
    ld      a,[hl]
    pop     hl
    ret



; Entity Storage Bucket Handling ----------------------------------------------
; -----------------------------------------------------------------------------
_entity_get_current_room_id: ; c -> room id

    ld      a,[mapRoomX]
    inc     a ; convert to 1 based indexing
    ld      h,a

    ld      a,[mapRoomY]
    inc     a ; convert to 1 based indexing
    ld      e,a

    ; get room number index into hl
    call    math_mul8b ; hl = h * e 
    ld      c,l

    ret



_entity_get_last_room_id: ; c -> room id

    ld      a,[mapRoomLastX]
    inc     a ; convert to 1 based indexing
    ld      h,a

    ld      a,[mapRoomLastY]
    inc     a ; convert to 1 based indexing
    ld      e,a

    ; get room number index into hl
    call    math_mul8b ; hl = h * e 
    ld      c,l

    ret



_entity_get_store_bucket: ; c = room id (1-255), b = entity id (0-3) -> hl = bucker pointer
    push    bc
    call    _entity_find_bucket; first check for a existing bucket that contains the entity
    cp      1
    jr      z,.done ; found a used bucket for this entity

    ; find a free bucket, if possible
    call    _entity_find_free_bucket
.done:
    pop     bc
    ret
    


_entity_find_bucket: ; b = room id (1-255), c = entity id (0-3)
    ; return a = 1 if we found a match, in which case hl = data pointer to entity state

    ; [roomid] (1 based indexing)
    ; [ffffff][ii] flags and entity id
    ; [y position]
    ; [x position]
    ld      hl,entityStoredState
    ld      e,0

.loop:
    ld      a,[hl]; get room id
    cp      0
    jr      z,.skip; skip empty buckets

    ; check for room id match
    cp      c
    jr      nz,.skip

    ; check entity id match
    inc     hl
    ld      a,[hl]
    and     %00000011
    dec     hl
    cp      b
    jr      nz,.skip

    ; match found, hl is at the correct offset already
    ld      a,1
    ret

.skip:
    inc     hl
    inc     hl
    inc     hl
    inc     hl

    ; break out after going through all rooms
.next:
    inc     e
    ld      a,e
    cp      ENTITY_MAX_STORE_BUCKETS
    jr      z,.not_found
        
    jr      .loop
    
.not_found:
    xor     a
    ret



_entity_find_free_bucket:
    ; return a = 1 if we found a free spot, in which case hl = data pointer to entity state

    ; [roomid] (1 based indexing)
    ; [ffffff][ii] flags and entity id
    ; [y position]
    ; [x position]
    ld      hl,entityStoredState
    ld      e,0

.loop:
    ld      a,[hl]; get room id
    cp      0
    jr      nz,.used; skip used buckets

    ; found a free spot, return the pointer
    ld      a,1
    ret

.used:
    inc     hl
    inc     hl
    inc     hl
    inc     hl

    ; break out after going through all rooms
.next:
    inc     e
    ld      a,e
    cp      ENTITY_MAX_STORE_BUCKETS
    jr      z,.not_found
        
    jr      .loop
    
.not_found:
    xor     a
    ret

