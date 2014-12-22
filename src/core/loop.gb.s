; Core Loop -------------------------------------------------------------------
core_loop:

    halt    ; stop system clock, return from halt when interrupted
    nop     ; If interrupts are disabled halt jumps one instruction!

    ; Wait for V-Blank
    ld      a,[coreVBlankDone]
    and     a                   ; V-Blank interrupt ?
    jr      z,core_loop         ; No, some other interrupt
    xor     a
    ld      [coreVBlankDone],a  ; Clear V-Blank flag
                                
    ; Fetch Joypad State
    call    core_input

    ; Run the main game loop 
    call    game_loop 

    ; Loop counter which goes from 0-7
    ld      a,[coreLoopCounter]
    inc     a
    and     %00000111
    ld      [coreLoopCounter],a
            
    jr      core_loop

