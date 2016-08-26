; Sleep Timer -----------------------------------------------------------------
player_sleep:

    ; in case no button is pressed decrease the sleep ticker
    ld      a,[coreInput]
    and     BUTTON_A | BUTTON_B | BUTTON_LEFT | BUTTON_RIGHT
    jr      nz,.active

    ; also check whether we're on the ground
    ld      a,[playerOnGround]
    cp      0
    jr      z,.active

    ; check sleep ticker
    ld      a,[playerSleepTick]
    cp      0
    ret     nz

    ; set sleeping
    ld      a,PLAYER_ANIMATION_SLEEP
    ld      [playerAnimation],a
    ret

.active:
    ld      a,PLAYER_SLEEP_WAIT
    ld      [playerSleepTick],a
    ret


player_sleep_timer:
    ld      a,[playerSleepTick]
    cp      0
    ret     z

    dec     a
    ld      [playerSleepTick],a
    ret

