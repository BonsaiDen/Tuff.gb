; VBlank Handler --------------------------------------------------------------
core_vblank_handler:

    di
    push    af
    push    bc
    push    de
    push    hl

    ; Update palettes here so we avoid changing them midframe
    ld      a,[corePaletteChanged]
    cp      0
    jr      z,.palette_done

    ; reset changed flag
    xor     a
    ld      [corePaletteChanged],a

    ; check if we need to update the color palette
    ld      a,[coreColorEnabled]
    cp      0
    jr      z,.palette_dmg
    call    screen_update_palette_color
    jr      .palette_done

.palette_dmg:
    ld      a,[corePaletteBG]
    ld      [rBGP],a

    ld      a,[corePaletteSprite0]
    ld      [rOBP0],a

    ld      a,[corePaletteSprite1]
    ld      [rOBP1],a

.palette_done:

    ; check if we need to draw the room data to screen ram
    ld      a,[mapRoomUpdateRequired]
    cp      0
    jr      z,.no_map_update

    ; draw new room into VRAM (updates scrolling, sprites and effects)
    call    map_draw_room

    ; copy sprites AFTER room load so entity sprites are positioned correctly
    call    $ff80
    jr      .scrolling

.no_map_update:

    ; just copy sprites in case no room update was required
    call    $ff80

.scrolling:

    ; update scroll registers (values need to be negated)
    ld      a,[coreScrollX]
    dec     a
    cpl
    ld      [rSCX],a

    ld      a,[coreScrollY]
    dec     a
    cpl
    ld      [rSCY],a

    ; Set vblank flag, this will cause the core loop to run the game loop once
    ld      a,1
    ld      [coreVBlankDone],a

    ; end of game specific code -----------------------------------------------

    pop     hl
    pop     de
    pop     bc
    pop     af

    reti

