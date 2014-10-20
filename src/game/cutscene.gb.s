; Cutscene Functions ----------------------------------------------------------
cutscene_init:; a = cutsceneNumber

    ; set active cutscene number
    ld      [cutsceneNumber],a
    ld      b,a; store target number

    ; find the base address of the cutscene handlers from the cutscene table
    ld      hl,DataCutsceneHandlerTable

.next:
    ld      a,[hli]; load and skip the cutscene number
    cp      b
    jr      nz,.skip
    cp      $ff; check for table end marker
    jr      z,.missing
    jr      .found

.skip:
    ; skip DW holding the handler address
    inc     hl
    inc     hl
    jr      .next

.found:
    call    _cutscene_handler_setup
    ret

.missing:
    xor     a
    ld      [cutsceneNumber],a
    ret


cutscene_timer:

    ; do nothing if there's no active cutscene 
    ld      a,[cutsceneNumber]
    cp      0
    ret     z
    
    ; load the current cutscene handler's address
    ld      a,[cutsceneOffset]
    ld      h,a
    ld      a,[cutsceneOffset + 1]
    ld      l,a
    call    _cutscene_handler_jump

    ; compare the ticks the current handler should run with the current tick count
    ld      b,a; store the tick number returned by the handler
    ld      a,[cutsceneTick]
    cp      b
    jr      nz,.next; continue running the current hanlder

    ; check the next cutscene handler entry in the table
    ld      a,[cutsceneTableEntry + 1]
    ld      h,a
    ld      a,[cutsceneTableEntry]
    ld      l,a

    ld      a,[hli]; load cutscene number

    ; compare with current cutscene
    ld      b,a
    ld      a,[cutsceneNumber]
    cp      b
    jr      nz,.done; if the number's don't match, end the current cutscene

    ; otherwise setup the next handler
    call    _cutscene_handler_setup
    ret

.done:
    call    cutscene_end
    ret

.next:
    inc     a
    ld      [cutsceneTick],a
    ret


cutscene_end:; a -> 0
    xor     a
    ld      [cutsceneNumber],a
    ret


; Helper ----------------------------------------------------------------------
_cutscene_handler_setup:

    ; store the base offset address for the current cutscene
    ld      a,[hli]
    ld      [cutsceneOffset + 1],a
    ld      a,[hli]
    ld      [cutsceneOffset],a

    ; store the address of the next cutscene
    ld      a,h
    ld      [cutsceneTableEntry + 1],a
    ld      a,l
    ld      [cutsceneTableEntry],a

    ; reset tick counter
    xor     a
    ld      [cutsceneTick],a
    ret


_cutscene_handler_jump:
    jp      [hl]; Jump Trampolin

