; Screen handling -------------------------------------------------------------
core_screen_off:
    ld      hl,rLCDC
    bit     7,[hl]          ; Is LCD already off?
    ret     z               ; yes, exit

    ld      a,[rIE]
    push    af
    res     0,a
    ld      [rIE],a         ; Disable vblank interrupt if enabled

.screen_off_loop:  
    ld      a,[rLY]         ; Loop until in first part of vblank
    cp      145
    jr      nz,.screen_off_loop
    res     7,[hl]          ; Turn the screen off
    pop     af
    ld      [rIE],a         ; Restore the state of vblank interrupt
    ret

core_screen_on:
    ld      a,LCDCF_ON|LCDCF_BG8800|LCDCF_BG9800|LCDCF_BGON|LCDCF_OBJ16|LCDCF_OBJON
    ld      [rLCDC],a
    ret

