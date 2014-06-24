; Input Constants -------------------------------------------------------------
BUTTON_DOWN     EQU %10000000
BUTTON_UP       EQU %01000000
BUTTON_LEFT     EQU %00100000
BUTTON_RIGHT    EQU %00010000
BUTTON_START    EQU %00001000
BUTTON_SELECT   EQU %00000100
BUTTON_B        EQU %00000010
BUTTON_A        EQU %00000001


; Input Handling --------------------------------------------------------------
core_input:

    ; store old state into d and reset new state
    ld      a,[coreInput]
    ld      d,a
    xor     a
    ld      [coreInput],a

    ; toggle d-pad lines on
    ld      a,%00100000
    ld      [rP1],a

    ; read dpad data
    ld      a,[rP1]
    ld      a,[rP1]
    ld      a,[rP1]
    ld      a,[rP1]
    and     %00001111
    swap    a               
    ld      b,a ; store d-pad data into the high bits

    ; toggle button lines on
    ld      a,%00010000
    ld      [rP1],a
    
    ; read button data
    ld      a,[rP1]
    ld      a,[rP1]
    ld      a,[rP1]
    ld      a,[rP1]
    ld      a,[rP1]
    ld      a,[rP1]
    and     %00001111; just keep the button data
    or      b; combine with dpad data
    cpl     ; invert the data so active buttons are read as 1 

    ; store new state
    ld      [coreInput],a
    ld      c,a ; store a copy of the current button state
            
    ; reset the joypad by activating both buttons and dpad
    ld      a,%00110000
    ld      [rP1],a

    ; get the buttons which were initially pressed on this frame
    ld      a,c; load the current state
    xor     d; first XOR with the old state to get the state difference
    and     c; now AND with the current state to only get inputs
    ld      [coreInputOn],a

    ; get the buttons released on this frame
    ld      a,c ; load the current state
    xor     d; first XOR with the old state to get the state difference
    and     d; now AND with the current state to only get inputs 
    ld      [coreInputOff],a

    ; a = [Down][Up][Left][Right][Start][Select][B][A]
    ret

