;*
;* Sprite Trash Prevention Macros
;*
;*   Started 15-April-97
;*
;* Initials: JF = Jeff Frohwein
;*
;* V1.0 - 12-Jun-97 : Original Release - JF
;* V1.1 - 27-Jul-97 : Modified for new subroutine prefixes - JF
;*
;*   When the 16-bit register pairs BC,DE, or HL are
;*  incremented or decremented while they contain
;*  values in the range $fe00-$feff, corruption of
;*  Sprite OAM ram may result. Use these macros when
;*  needed to prevent this from occuring.

;If all of these are already defined, don't do it again.

        IF      !DEF(INCDEC_INC)

INCDEC_INC  SET  1

rev_Check_incdec_inc: MACRO
;NOTE: REVISION NUMBER CHANGES MUST BE ADDED
;TO SECOND PARAMETER IN FOLLOWING LINE.
        IF      \1 > 1.1      ; <---- NOTE!!! PUT FILE REVISION NUMBER HERE
        WARN    "Version \1 or later of 'incdec.inc' is required."
        ENDC
        ENDM

INC_BC: MACRO
        push    hl
        ld      hl,1
        add     hl,bc
        ld      b,h
        ld      c,l
        pop     hl
        ENDM

INC_DE: MACRO
        push    hl
        ld      hl,1
        add     hl,de
        ld      d,h
        ld      e,l
        pop     hl
        ENDM

INC_HL: MACRO
        push    bc
        ld      bc,1
        add     hl,bc
        pop     bc
        ENDM

DEC_BC: MACRO
        push    hl
        ld      hl,-1
        add     hl,bc
        ld      b,h
        ld      c,l
        pop     hl
        ENDM

DEC_DE: MACRO
        push    hl
        ld      hl,-1
        add     hl,de
        ld      d,h
        ld      e,l
        pop     hl
        ENDM

DEC_HL: MACRO
        push    bc
        ld      bc,-1
        add     hl,bc
        pop     bc
        ENDM

        ENDC    ;INCDEC_INC

