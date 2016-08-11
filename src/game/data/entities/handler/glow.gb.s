entity_handler_load_glow:
    ; TODO set hardware sprite indexes for entity sprites!
    ld      a,c
    ld      b,ENTITY_ANIMATION_OFFSET + ENTITY_ANIMATION_GLOW
    call    new_sprite_set_animation
    ;call    sprite_animation_start
    xor     a; 
    ret
    

entity_handler_update_glow: ; generic, b = entity index, c = sprite index, de = screen data

    ; only run every third frame
    ld      a,[coreLoopCounter]
    and     %00000001
    cp      %00000001
    ret     nz

    inc     de; skip type
    inc     de; skip flags
    call    entity_glow_movement
    ret


entity_glow_movement:; de = pointer at direction flag

    ; randomly switch the direction 
    call    math_random
    cp      8
    jr      nc,.move
    call    math_random
    and     %00000011
    ld      [de],a
    ret

.move:
    push    bc
    push    de

    inc     de; skip direction
    ld      a,[de]; load y position and store into c
    ld      c,a
    inc     de
    ld      a,[de]; load x position and store into b
    ld      b,a

    dec     de
    dec     de
    ld      a,[de]; load direction flag

    ; 1. check current direction
    cp      ENTITY_DIRECTION_UP
    jr      z,.up
    cp      ENTITY_DIRECTION_RIGHT
    jr      z,.right
    cp      ENTITY_DIRECTION_DOWN
    jr      z,.down
    cp      ENTITY_DIRECTION_LEFT
    jr      z,.left
    
.done:
    ; set y and x direction
    inc     de
    ld      a,c
    ld      [de],a

    inc     de
    ld      a,b
    ld      [de],a

    pop     de
    pop     bc
    ret

.direction:
    call    math_random
    and     %00000011
    ld      [de],a
    pop     de
    pop     bc
    ret

; Left ------------------------------------------------------------------------
.left:
    call    entity_col_left
    jr      c,.direction
    dec     b
    dec     b
    jr      .done

; Right -----------------------------------------------------------------------
.right:
    call    entity_col_right
    jr      c,.direction
    inc     b
    inc     b
    jr      .done

; Up --------------------------------------------------------------------------
.up:
    call    entity_col_up
    jr      c,.direction
    dec     c
    dec     c
    jr      .done
    
; Down ------------------------------------------------------------------------
.down:
    call    entity_col_down
    jr      c,.direction
    inc     c
    inc     c
    jr      .done

