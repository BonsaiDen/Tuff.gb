; Tileset ---------------------------------------------------------------------

; hl = sprite map pointer, b = target row in ram, c = row index in sprite map, de = target base in ram
tileset_load_sprite_row: ; load a compressed sprite row into vram

    push    bc

    ; adjust target pointer for target row
    ld      a,d 
    add     b
    ld      d,a

    ; offset into location table
    ld      b,0
    sla     c; each table entry is two bytes
    add     hl,bc ; hl = table offset data pointer

    ; read high and low byte for the offset
    ld      a,[hli]
    ld      b,a
    ld      a,[hli]
    ld      c,a; bc = offset until row data (from current table index position)

    ; create final data pointer for sprite row data
    ; the offset value is pre calcuated to be relative from the table data pointer + 2
    add     hl,bc

    ; decode with end marker in stream
    call    core_decode_eom

    pop     bc
    ret


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

