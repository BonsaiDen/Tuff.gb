entity_handler_load_powerup:
    ld      a,c
    ld      b,ENTITY_ANIMATION_OFFSET + ENTITY_ANIMATION_POWERUP
    call    sprite_set_animation
    ;call    sprite_animation_start

    ; TODO check the actual powerup
    ld      a,[playerCanJump]; check if powerup is already collected
    ld      a,0
    ret
    

entity_handler_update_powerup: ; b = entity index, c = sprite index, de = screen data
    ld      hl,playerCanJump
    call    _entity_handler_powerup_collect
    ret


_entity_handler_powerup_collect: ; b = entity index, c = sprite index, de = screen data, hl = powerup enabled byte

    ld      a,[hl]
    cp      1
    ret     z

    ; TODO is this aligned, if so we only need to inc e
    inc     de; skip type
    inc     de; skip flags
    inc     de; skip direction

    call    entity_col_player
    cp      0
    ret     z

    ; disable entity
    dec     de
    dec     de
    dec     de
    dec     de
    xor     a
    ld      [de],a

    ; TODO trigger cutscene
    ; TODO we need a cutscene manager
    ; one active cutscene 
    ; - id
    ; - stage
    ; - tick
    ld      a,SCREEN_PALETTE_FLASH | SCREEN_PALETTE_LIGHT
    call    screen_animate

    ; enable ability 
    ld      a,1
    ld      [hl],a
    ret

