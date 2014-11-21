; Initialize Hardware and Core ------------------------------------------------
core_init:

    di                      ; Disable interrupts

    ; check for gameboy color hardware
    cp      $11; GBC leaves 0x11 in the accumulator after startup
    jr      nz,.nocolor

    ; switch to double speed mode
    xor     a
    ld      [$FFFF],a
    ld      a,$30
    ld      [$FF00],a
    ld      a,$01
    ld      [$FF4D],a
    stop

    ; flag color mode 
    ld      [coreColorEnabled],a
    jr      .vars

.nocolor:
    xor     a
    ld      [coreColorEnabled],a

.vars:

    ; Clear core variables
    xor     a
    ld      [coreVBlankDone],a
    ld      [coreLoopCounter],a
    ld      [coreTimerCounter],a
    ld      [coreInput],a
    ld      [coreInputOn],a
    ld      [coreInputOff],a
    ld      [coreRandomHigh],a
    ld      [coreRandomLow],a
    ld      [corePaletteChanged],a
    ld      [coreDecodeAddress],a
    ld      [coreDecodeAddress + 1],a
    ld      [coreTimerToggle],a
    ld      [coreScrollX],a
    ld      [coreScrollY],a

    ld      sp,$FFFF        ; init stack pointer
    call    core_screen_off ; Disable Screen
    call    core_setup_dma  ; Setup DMA transfer

    ; Clear RAM, otherwise we will run into problems on real hardware
    ; where it is not going to get initialized
    ld      a,$00           
    ld      hl,$c000
    ld      bc,8192
    call    core_mem_set

    ; Clear VRam (removing Nintendo Logo left over from boot up)
    ld      a,$00           
    ld      hl,$8000
    ld      bc,6144
    call    core_mem_set

    ; Clear Background Screen Buffer
    ld      a,$80
    ld      hl,$9800
    ld      bc,1024
    call    core_mem_set

    ; Reset Scroll registers
    xor     a
    ld      [rSCX],a
    ld      [rSCY],a

    ; Reset palette registers
    ld      [rBGP],a
    ld      [rOBP0],a
    ld      [rOBP1],a

    ; Run init code and the loop once so we don't have a blank frame on powerup
    call    math_update_random
    call    core_input
    call    game_init
    call    game_loop

    ; Enable interrupts
    ei

    ; Setup interrupts
    ld      a,IEF_VBLANK | IEF_TIMER
    ld      [rIE],a
    ld      a,TACF_START | TACF_4KHZ
    ld      [rTAC],a

    call    core_screen_on  ; Turn on the screen
    jp      core_loop       ; Start main loop

