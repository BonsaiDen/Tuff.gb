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

    ; copy new player tiles into vram from the last update
    call    player_animation_update_tile

    ; update player animations during vblank to prevent flicker 
    call    player_animation_update

    ; update scroll registers
    ld      a,[coreScrollX]
    ld      [rSCX],a
    ld      a,[coreScrollY]
    ld      [rSCY],a

    ; check if we need to draw the room data to screen ram
    ld      a,[mapRoomUpdateRequired]
    cp      1
    jr      nz,.no_map_update

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

