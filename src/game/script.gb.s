SECTION "ScriptLogic",ROM0

; Script Execution ------------------------------------------------------------
script_execute:; b = room x, c = room y, a = trigger flag (LEAVE / ENTER)

    push    hl
    push    de
    push    bc

    ; store trigger flag
    ld      e,a

    ; combine x and y coordinates
    ld      a,b
    swap    a
    or      c
    ld      c,a; store coordinates into c

    ; setup loop
    ld      b,SCRIPT_TABLE_ENTRIES
    ld      hl,scriptHandlerTable
.loop:
    
    ; compare room coordinates
    ld      a,[hli]
    cp      c
    jr      nz,.skip_coordinates

    ; load the script flags
    ld      a,[hli]
    ld      c,a; store raw flags into c

    ; compare trigger flag
    and     %00000001
    cp      e
    jr      nz,.skip_flags

    ; check if the script should run only once
    ld      c,a; restore flags
    and     %00000010;
    jr      z,.run_script; if not, always execute the script
        
    ; TODO check script memory flag to see if the script has been run


    ; run script address handler
.run_script:
    
    ; load script address
    ld      a,[hli]
    ld      e,a
    ld      a,[hli]
    ld      d,a
    
    ; setup script jump
    push    hl
    push    de
    push    bc

    ; setup script call
    ld      h,d
    ld      l,e
    call    _script_handler

    pop     bc
    pop     de
    pop     hl

    ; TODO mark script as run if SCRIPT_TRIGGER_ROOM_ONCE is set

    jr      .next

.skip_coordinates:
    inc     hl

.skip_flags:
    inc     hl
    inc     hl

.next:
    dec     b
    jr      nz,.loop

    pop     bc
    pop     de
    pop     hl

    ret


_script_handler:
    jp      [hl]
    

scriptRoomTest:
    ld      a,10
    call    screen_shake
    ret

