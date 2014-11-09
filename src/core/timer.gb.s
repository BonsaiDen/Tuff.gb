; Timer Handler ---------------------------------------------------------------
core_timer_handler:

    di
    push    af
    push    bc
    push    de
    push    hl

    ; Timer counter which goes from 0-7 (on a ~250ms basis)
    ld      a,[coreTimerCounter]
    inc     a
    and     %00000111; TODO in double speed mode will just adjust this?
    ld      [coreTimerCounter],a

    call    game_timer

    pop     hl
    pop     de
    pop     bc
    pop     af

    reti

