entity_handler_load_save_light: ; generic, b = entity index, c = sprite index
    ld      b,ENTITY_ANIMATION_OFFSET + ENTITY_ANIMATION_SAVE_LIGHT
    jr      _entity_handler_load_save

entity_handler_load_save_dark: ; generic, b = entity index, c = sprite index
    ld      b,ENTITY_ANIMATION_OFFSET + ENTITY_ANIMATION_SAVE_DARK

_entity_handler_load_save:
    ld      a,c
    call    sprite_set_animation
    xor     a
    ret

entity_handler_update_save: ; generic, b = entity index, c = sprite index, de = screen data

    inc     e; skip type
    inc     e; skip flags
    inc     e; skip direction

    ; check player y === save y
    ld      a,[de] ; y
    ld      b,a
    ld      a,[playerY]
    cp      b
    ret     nz; player y != save y

    ; check down press
    ld      a,[coreInputOn]
    and     %10000000
    cp      %10000000
    ret     nz

    ; check x
    call    entity_col_player
    ret     nc

    call    save_store_to_sram
    ld      a,SCREEN_PALETTE_FLASH | SCREEN_PALETTE_LIGHT
    call    screen_animate
    ld      a,SOUND_EFFECT_GAME_SAVE_FLASH
    call    sound_play_effect_one
    ret

