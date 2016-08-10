SECTION "ScriptLogic",ROM0

; Script Initialization -------------------------------------------------------
script_init:
    ld      a,0
    ld      hl,scriptTableStatus
    ld      bc,SCRIPT_TABLE_MAX_ENTRIES
    call    core_mem_set
    ret


; Script Execution ------------------------------------------------------------
script_execute:; a = trigger flag (LEAVE / ENTER)

    push    hl
    push    de
    push    bc

    ; store trigger flag
    ld      e,a

    ; combine x and y coordinates
    ld      a,[mapRoomY]
    ld      c,a
    ld      a,[mapRoomX]
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

    ; load the script's config flags
    ld      a,[hli]
    ld      c,a; store raw flags into c

    ; compare script flags with the requested trigger flag 
    ; to see whether we should execute the script upon leaving or entering the room
    and     %00000001; mask off other flags
    cp      e; compare with argument
    jr      nz,.skip_address
        
    ; now load the script's stored flags from memory
    push    hl
    ld      hl,scriptTableStatus

    ; add current script index 
    ; TODO ensure alignment of script data ?
    ld      a,l
    add     b
    ld      l,a

    ld      a,[hl]
    pop     hl
            
    ; check if the script was already triggered
    ; and if so, prevent it from running
    and     SCRIPT_FLAG_TRIGGERED
    jr      nz,.skip_address

    ; run script address handler
.run_script:
    
    ; load script address
    ld      a,[hli]
    ld      e,a
    ld      a,[hli]
    ld      d,a
    
    ; setup script jump
    push    hl
    push    bc

    ; setup script call
    ld      h,d
    ld      l,e
    call    _script_handler
    pop     bc

    ; check if we should store the triggered flag to memory for the current script
    ld      a,c; restore flags and compare
    and     SCRIPT_TRIGGER_ROOM_STORE
    jr      z,.no_flags; if flag is not set, skip storing

    ; get pointer to the current script's memory flags
    ld      hl,scriptTableStatus
    ld      a,l; add current script index
    add     b

    ; load current script's memory flags and set triggered bit
    ld      a,[hl]
    or      SCRIPT_FLAG_TRIGGERED
    ld      [hl],a

.no_flags:
    pop     hl
    jr      .next

.skip_coordinates:
    inc     hl

.skip_address:
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

