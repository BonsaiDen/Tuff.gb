; Far Bank Logic --------------------------------------------------------------
core_far_call:; a = bank, hl = address -> returns to bank 1 afterwards

    ; switch to new bank
    ld      [$2000],a

    ; push return address onto stack
    call    _core_far_jump

    ; restore bank but do not modify af
    push    af
    ld      a,$1
    ld      [$2000],a
    pop     af
    ret

_core_far_jump:
    jp      [hl]
