; Timer Handler ---------------------------------------------------------------
core_timer_handler:

    di
    push    af
    push    bc
    push    de
    push    hl

    ; When in color mode we need to step down the timer by 2
    ld      a,[coreColorEnabled]
    ld      a,[coreTimerToggle]
    inc     a
    and     %00000001
    ld      [coreTimerToggle],a
    jr      nz,.done

    ; Timer counter which goes from 0-7 (on a ~250ms basis)
.timer:
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

