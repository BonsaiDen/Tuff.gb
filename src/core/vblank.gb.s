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

    ; game specific code ------------------------------------------------------

    ; now copy OAM to match the sprites
    call    $ff80

    ; update scroll registers (values need to be negated)
    ld      a,[coreScrollX]
    dec     a
    cpl
    ld      [rSCX],a

    ld      a,[coreScrollY]
    dec     a
    cpl
    ld      [rSCY],a

    ; check if we need to draw the room data to screen ram
    ld      a,[mapRoomUpdateRequired]
    cp      0
    jr      z,.no_map_update

    ; draw new before updating sprites so the player does not appear in
    ; the wall of the previous room for one frame
    call    map_draw_room

.no_map_update:

    ; Set vblank flag, this will cause the core loop to run the game loop once
    ld      a,1
    ld      [coreVBlankDone],a

    ; end of game specific code -----------------------------------------------

    pop     hl
    pop     de
    pop     bc
    pop     af

    reti

