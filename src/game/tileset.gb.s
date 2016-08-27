; Tileset ---------------------------------------------------------------------

; hl = sprite map pointer, b = target row in ram, c = row index in sprite map, de = target base in ram
; tileset_load_sprite_row_compressed: ; load a compressed sprite row into vram
;
;     push    bc
;
;     ; adjust target pointer for target row
;     ld      a,d
;     add     b
;     ld      d,a
;
;     ; offset into location table
;     ld      b,0
;     sla     c; each table entry is two bytes
;     add     hl,bc ; hl = table offset data pointer
;
;     ; read high and low byte for the offset
;     ld      a,[hli]
;     ld      b,a
;     ld      a,[hli]
;     ld      c,a; bc = offset until row data (from current table index position)
;
;     ; create final data pointer for sprite row data
;     ; the offset value is pre calcuated to be relative from the table data pointer + 2
;     add     hl,bc
;
;     ; decode with end marker in stream
;     call    core_decode_eom
;
;     pop     bc
;     ret


; copy tiles to character data in vram
tileset_load: ; hl = source
    ld      de,$8800
    call    core_decode_eom
    ret


    ; copy animated tiles into WRAM buffer (the last 64 tiles, 1024 bytes)
tileset_load_animations:; hl = source
    ld      de,mapTileAnimationBuffer
    call    core_decode_eom
    ret


tileset_draw_image:; hl = image source

    ; decompress tiles into vram
    ld      de,$8800; start target for decode write
    call    core_decode_eom

    ld      de,mapRoomTileBuffer; start target for decode write
    call    core_decode_eom

    ; copy data pointer into de
    ld      de,mapRoomTileBuffer

    ; screen tile base pointer
    ld      hl,$9800

    ld      b,18
.loop_y:
    ld      c,20

.loop_x:

    ; wait for vblank
    ld      a,[rSTAT]       ; <---+
    and     STATF_BUSY      ;     |
    jr      nz,@-4          ; ----+

    ld      a,[de]
    ld      [hli],a
    inc     de

    ; loop x
    dec     c
    jr      nz,.loop_x

    ; 16 bit addition of 12 to hl
    ld      a,l
    add     a,12
    ld      l,a
    adc     a,h
    sub     l
    ld      h,a

    ; loop y
    dec     b
    jr      nz,.loop_y

    ; clear room tile buffer to avoid collisions errors later on
    ld      hl,mapRoomTileBuffer; start target for decode write
    ld      bc,512
    ld      a,$DF
    call    core_mem_set

    ret

