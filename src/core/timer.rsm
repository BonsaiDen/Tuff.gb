; Timer Handler ---------------------------------------------------------------
core_timer_handler:

    di
    push    af
    push    bc
    push    de
    push    hl

    ; ~60ms timer (62.25585ms)
    ld      a,[coreTimer]
    inc     a
    ld      [coreTimer],a
    cp      4
    jr      nz,.skip

    ; Timer counter which goes from 0-7
    ld      a,[coreTimerCounter]
    inc     a
    and     %00000111
    ld      [coreTimerCounter],a

    call    game_timer
    xor     a
    ld      [coreTimer],a

.skip:
    pop     hl
    pop     de
    pop     bc
    pop     af

    reti

