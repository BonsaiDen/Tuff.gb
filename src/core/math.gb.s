; 8 x 8 bit multiplication ----------------------------------------------------
math_mul8b:                     ; this routine performs the operation HL=H*E
    ld      d,0                 ; clearing D and L
    ld      l,d
    ld      a,8                 ; we have 8 bits

.Mul8bLoop:
    add     hl,hl               ; advancing a bit
    jr      nc,.Mul8bSkip        ; if zero, we skip the addition (jr is used for speed)
    add     hl,de               ; adding to the product if necessary

.Mul8bSkip:
    dec     a
    jr      nz,.Mul8bLoop
    ret

; Fast RND
;
; An 8-bit pseudo-random number generator,
; using a similar method to the Spectrum ROM,
;
; R = random number seed
; an integer in the range [1, 256]
;
; R -> (33*R) mod 257
;
; S = R - 1
; an 8-bit unsigned integer
math_random:
    call    math_update_random
    ld      a,[coreRandomLow]
    ret

math_update_random:
    ld      a,[rDIV]
    ld      b,a
    ld      a,[coreRandomHigh]
    adc     b
    ld      [coreRandomHigh],a

    ld      a,[rDIV]
    ld      b,a
    ld      a,[coreRandomLow]
    sbc     b
    ld      [coreRandomLow],a
    ret

