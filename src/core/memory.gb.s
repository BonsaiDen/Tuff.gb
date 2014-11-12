;*
;* Taken from:
;*
;* MEMORY.ASM - Memory Manipulation Code
;* by GABY. Inspired by Carsten Sorensen & others.
;*
;* V1.0 - Original release
;*

; Memory Set ------------------------------------------------------------------
core_mem_set: ; a = value, hl = address, bc = bytecount
    inc     b
    inc     c
    jr      .skip
.loop:
    ld      [hli],a
.skip:
    dec     c
    jr      nz,.loop
    dec     b
    jr      nz,.loop
    ret


; Memory Copy -----------------------------------------------------------------
core_mem_cpy: ; hl = source, de = dest, bc = bytecount
    inc     b
    inc     c
    jr      .skip
.loop:
    ld      a,[hli]
    ld      [de],a
    inc     de
.skip:
    dec     c
    jr      nz,.loop
    dec     b
    jr      nz,.loop
    ret


; VRAM Set --------------------------------------------------------------------
core_vram_set: ; d = value, hl = address, bc = bytecount
    inc     b
    inc     c
    jr      .skip

.loop:
    ld      a,[rSTAT]       ; <---+
    and     STATF_BUSY      ;     |
    jr      nz,@-4          ; ----+
    ld      a,d
    ld      [hli],a

.skip:
    dec     c
    jr      nz,.loop
    dec     b
    jr      nz,.loop
    ret


; VRAM Copy -------------------------------------------------------------------
core_vram_cpy: ; hl = source, de = dest, bc = bytecount / 2
    inc     b
    inc     c
    jr      .skip

.loop:
    ld      a,[rSTAT]       ; <---+
    and     STATF_BUSY      ;     |
    jr      nz,@-4          ; ----+
    ld      a,[hli]
    ld      [de],a
    inc     de

    ld      a,[rSTAT]       ; <---+
    and     STATF_BUSY      ;     |
    jr      nz,@-4          ; ----+
    ld      a,[hli]
    ld      [de],a
    inc     de

.skip:
    dec     c
    jr      nz,.loop
    dec     b
    jr      nz,.loop
    ret


core_vram_cpy_low: ; hl = source, de = dest, b = bytecount
.loop:
    ld      a,[rSTAT]       ; <---+
    and     STATF_BUSY      ;     |
    jr      nz,@-4          ; ----+
    ld      a,[hli]
    ld      [de],a
    inc     de
    dec     b
    jr      nz,.loop
    ret

