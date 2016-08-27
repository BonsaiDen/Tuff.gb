; Timer Handler ---------------------------------------------------------------
core_timer_handler:

    di
    push    af
    push    bc
    push    de
    push    hl

    ld      a,[coreColorEnabled]
    cp      0
    jr      z,.update_timer

    ; When in color mode we need to slow down the timer by a factor of 2
    ld      a,[coreTimerToggle]
    inc     a
    and     %00000001
    ld      [coreTimerToggle],a
    jr      nz,.done

.update_timer:

    ; Timer counter which goes through 0-7 (on a ~250ms basis)
    ld      a,[coreTimerCounter]
    inc     a
    and     %00000111
    ld      [coreTimerCounter],a

    call    game_timer

.done:
    pop     hl
    pop     de
    pop     bc
    pop     af

    reti

