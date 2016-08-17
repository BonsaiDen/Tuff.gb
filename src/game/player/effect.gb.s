player_effect_dust_small:
    ld      a,[playerY]
    add     2
    sub     b
    ld      b,a
    ld      a,[playerX]
    add     a,4
    ld      c,a
    ld      a,EFFECT_DUST_CLOUD_SMALL
    call    effect_create
    ret

player_effect_water_splash:
    ; Left
    ld      a,[playerX]
    ld      c,a
    ld      a,[playerY]
    add     2
    ld      b,a
    ld      a,EFFECT_WATER_SPLASH_LEFT
    call    effect_create

    ; Right
    ld      a,[playerX]
    add     a,8
    ld      c,a
    ld      a,[playerY]
    add     2
    ld      b,a
    ld      a,EFFECT_WATER_SPLASH_RIGHT
    call    effect_create
    ret


