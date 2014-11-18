; Data Unpacking Routines -----------------------------------------------------
CORE_DECODE_MIN_COPY_LENGTH     EQU 2
CORE_DECODE_MIN_REPEAT_LENGTH   EQU 2
                                

; Decompression Algorithm -----------------------------------------------------
; -----------------------------------------------------------------------------
core_decode_eom: ; HL = source, DE = target, coreDecodeAddress

    ; check there is a end address specified 
    ld      a,[coreDecodeAddress]
    cp      0
    jr      z,.decode

    ; check low byte
    ld      a,[coreDecodeAddress + 1]
    cp      e 
    jr      nz,.decode

    ; check high byte
    ld      a,[coreDecodeAddress]
    cp      d
    jr      nz,.decode

    ; reset decode address
    xor     a
    ld      [coreDecodeAddress],a
    ret

    ; fetch next instruction byte and goto first data byte
.decode:
    ld      a,[hli]
    bit     7,a
    jr      nz,.repeat ; if set we have a repeat token
    bit     6,a
    jr      nz,.literal ; if set we have a literal token
    bit     5,a
    jr      nz,.repeat_zero; if we have a zero repeater


; Copy ------------------------------------------------------------------------
.copy:
    ; copy a number of bytes from a previous location in the stream to the current location
    and     %00011111; number of bytes to copy (aka match length)
    add     a,CORE_DECODE_MIN_COPY_LENGTH + 1; the encoder also remove the min encode length
    ld      b,a; ; store the actual match size, this is also used as the loop counter for the copying

    ld      a,[hli]; load copy offset and goto instruction byte
    add     a,b; add match size to get final offset TODO is this really overflow safe?
    ld      c,a; store offset

    ; hl = de - offset
    push    hl; store next instruction offset
    ld      a,e 
    or      a ; clear carry
    sbc     c ; subtract offset from low byte
    ld      l,a

    ld      a,d ; subtract high byte
    sbc     0; subtract the carry if it exists
    ld      h,a

.copy_loop:; b is our loop counter

    ; wait for vblank
    ld      a,[rSTAT]       ; <---+
    and     STATF_BUSY      ;     |
    jr      nz,@-4          ; ----+
    ; TODO handle invalid vram access

    ld      a,[hli]
    ld      [de],a
    inc     de
    dec     b
    jr      nz,.copy_loop

    pop     hl; restore next instruction offset
    jr      core_decode_eom
            

; Literals --------------------------------------------------------------------
.literal: ; read a number of plain bytes from the input stream
    and     %00111111; number of bytes to read
    inc     a; add 1 since the encoder encodes 1 as 0
    ld      b,a; store loop counter

.literal_copy:

    ; wait for vblank
    ld      a,[rSTAT]       ; <---+
    and     STATF_BUSY      ;     |
    jr      nz,@-4          ; ----+
    ; TODO handle invalid vram access

    ld      a,[hli]; goto next literal byte and eventually the next instruction byte
    ld      [de],a
    inc     de
    dec     b
    jr      nz,.literal_copy
    jr      core_decode_eom


; Repeating -------------------------------------------------------------------
.repeat:
    bit     6,a; check if we need to repeat one or two bytes
    jr      nz,.repeat_two; two bytes

.repeat_one:
    and     %00111111; number of times to repeat
    add     a,CORE_DECODE_MIN_REPEAT_LENGTH
    ld      b,a; store loop counter
    ld      a,[hli]; load byte to repeat and goto next instruction byte
    ld      c,a; store repeat byte

.repeat_one_loop:

    ; wait for vblank
    ld      a,[rSTAT]       ; <---+
    and     STATF_BUSY      ;     |
    jr      nz,@-4          ; ----+
    ; TODO handle invalid vram access

    ld      a,c; restore repeat byte
    ld      [de],a
    inc     de
    dec     b
    jr      nz,.repeat_one_loop
    jr      core_decode_eom

.repeat_zero:
    bit     4,a
    ret     nz; %00110000 is the end of data marker
    and     %00001111; number of times to repeat
    add     a,CORE_DECODE_MIN_REPEAT_LENGTH
    ld      b,a; store loop counter

.repeat_zero_loop:

    ; wait for vblank
    ld      a,[rSTAT]       ; <---+
    and     STATF_BUSY      ;     |
    jr      nz,@-4          ; ----+
    ld      [de],a; a is zero after the and
    inc     de
    dec     b
    jr      nz,.repeat_zero_loop
    jp      core_decode_eom

.repeat_two:
    and     %00111111; number of times to repeat
    add     a,CORE_DECODE_MIN_REPEAT_LENGTH
    ld      b,a; store loop counter

.repeat_two_loop:

    ; wait for vblank
    ld      a,[rSTAT]       ; <---+
    and     STATF_BUSY      ;     |
    jr      nz,@-4          ; ----+

    ; first byte
    ld      a,[hli]; goto second value byte
    ld      [de],a
    inc     de

    ; second byte
    ld      a,[hld]; go back to first value byte 
    ld      [de],a
    inc     de

    dec     b
    jr      nz,.repeat_two_loop
    inc     hl; goto second value byte
    inc     hl; goto next instruction byte
    jp      core_decode_eom

