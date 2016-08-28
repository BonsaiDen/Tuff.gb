entity_handler_load_powerup:; b = entity index, c = sprite index, de = screen data
    ld      a,c
    ld      b,ENTITY_ANIMATION_OFFSET + ENTITY_ANIMATION_POWERUP
    call    sprite_set_animation

    inc     e; skip type

    ; convert powerup type index into bitmask
    ld      a,[de]
    call    _ability_bitmask
    ld      b,a; store bitmask

    ; check if powerup is already collected
    ld      a,[playerAbility]
    and     b
    jr      nz,.collected

    ; load entity
    xor     a
    ret

.collected:
    ld      a,1; prevent loading of entity
    ret


entity_handler_update_powerup: ; b = entity index, c = sprite index, de = screen data

    inc     e; skip type
    inc     e; skip flags
    inc     e; skip direction

    ; check for collection
    call    entity_col_player
    ret     nc

    ; disable entity
    dec     e
    dec     e; back to direction
    dec     e; back to flags
    ld      a,[de]; load flags
    dec     e; back to type

    ; convert powerup type index into bitmask
    call    _ability_bitmask
    ld      b,a; store bitmask

    ; grant ability to player
    ld      a,[playerAbility]
    or      b
    ld      [playerAbility],a

    ; disable entity
    ld      a,$ff
    ld      [de],a

    ; flash screen
    ; TODO play a small cutscene with effects in the future
    ld      a,SCREEN_PALETTE_FLASH | SCREEN_PALETTE_LIGHT
    call    screen_animate

    ret


_ability_bitmask: ; a = power up index (1-8) -> a = ability bit mask
    ld      b,a

    ; convert to ability bit mask
    ld      a,1
.shift:
    dec     b
    ret     z
    sla     a
    jr      .shift

