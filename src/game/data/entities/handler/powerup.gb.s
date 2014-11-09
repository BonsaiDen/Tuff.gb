entity_handler_load_powerup:
    ld      a,c
    ld      b,ENTITY_ANIMATION_OFFSET + ENTITY_ANIMATION_POWERUP
    call    sprite_animation_set
    call    sprite_animation_start

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

    ; TODO share this logic across the powerups
    inc     de; skip type
    inc     de; skip flags
    inc     de; skip direction

    ; check player x > powerup x - 16 and player x < powerup y 

    ; check bottom edge
    ld      a,[de] ; y
    add     1
    ld      l,a
    ld      a,[playerY]
    cp      l
    ret     nc; edge > player

    ; check left edge
    ld      a,[de] ; y
    sub     15
    ld      l,a
    ld      a,[playerY]
    cp      l
    ret     c; edge < player

    ; check player x > powerup x - 8 and player x < powerup x + 8
    inc     de

    ; check right edge
    ld      a,[de] ; x
    add     7 
    ld      l,a
    ld      a,[playerX]
    cp      l
    ret     nc; edge > player

    ; check left edge
    ld      a,[de] ; x
    sub     6 
    ld      l,a
    ld      a,[playerX]
    cp      l
    ret     c; edge < player

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

