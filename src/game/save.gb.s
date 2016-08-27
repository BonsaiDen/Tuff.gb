SECTION "SaveLogic",ROM0

; SRAM Loading ----------------------------------------------------------------
save_load_from_sram:

    di

    ; writing $0A anywhere into the $0000-1FFFF range will enable external ram
    ld      hl,$0000
    ld      [hl],$0A

    ; writing a byte into the $4000-$5FFF range will select corresponding ram bank
    ld      hl,$4000
    ld      [hl],SAVE_RAM_BANK

    ; calculate checksum
    ld      bc,SAVE_COMPLETE_SIZE
    ld      de,$A000 + SAVE_CHECKSUM_SIZE
    call    _crc16

    ; high byte
    ld      hl,$A000
    ld      a,[hli]
    cp      b
    jr      nz,.defaults

    ; low byte
    ld      a,[hli]
    cp      c
    jr      nz,.defaults

    ; version
    ld      a,[hli]
    cp      SAVE_GAME_VERSION
    jr      nz,.defaults

    ; Map Data
    ld      a,[hli]
    ld      [mapRoomX],a

    ld      a,[hli]
    ld      [mapRoomY],a

    ; Player State
    ld      b,SAVE_PLAYER_STATE_BYTES
    ld      de,playerX
.loop_player_state:
    ld      a,[hli]
    ld      [de],a
    inc     de
    dec     b
    jr      nz,.loop_player_state

    ; Script Status
    ld      b,SCRIPT_TABLE_MAX_ENTRIES
    ld      de,scriptTableStatus
.loop_script_status:
    ld      a,[hli]
    ld      [de],a
    inc     de
    dec     b
    jr      nz,.loop_script_status

    ; stored entity state seperator
    ld      a,[hli] ; E5, "verified" via the checksum

    ; copy entity state to working ram
    ld      bc,SAVE_ENTITY_DATA_SIZE
    ld      de,entityStoredState
    call    core_mem_cpy

    xor     a
    call    save_load_player
    jr      .end

.defaults:
    ld      a,1
    call    save_load_player

.end:
    ; disable external RAM
    ld      hl,$0000
    ld      [hl],$00

    ei
    ret


save_load_player:

    ; Check if we should use the game defaults
    cp     1; a = 1
    jr     nz,.init

    ; Positions
    ld      a,SAVE_DEFAULT_PLAYER_X
    ld      [playerX],a

    ld      a,SAVE_DEFAULT_PLAYER_Y
    ld      [playerY],a

    ld      a,SAVE_DEFAULT_ROOM_X
    ld      [mapRoomX],a

    ld      a,SAVE_DEFAULT_ROOM_Y
    ld      [mapRoomY],a

    ; Abilities
    ld      a,%1111_1111
    ld      [playerAbility],a

.init:

    ld      a,[mapRoomX]
    ld      b,a
    ld      a,[mapRoomY]
    ld      c,a

    call    map_load_room
    call    player_reset

    call    effect_init

    ret


save_check_state: ; return 1 in a if a valid save state exists in sram

    di

    ; writing $0A anywhere into the $0000-1FFFF range will enable external ram
    ld      hl,$0000
    ld      [hl],$0A

    ; calculate checksum
    ld      bc,SAVE_COMPLETE_SIZE
    ld      de,$A000 + SAVE_CHECKSUM_SIZE
    call    _crc16

    ; high byte
    ld      hl,$A000
    ld      a,[hli]
    cp      b
    jr      nz,.missing

    ; low byte
    ld      a,[hli]
    cp      c
    jr      nz,.missing

    ; game version
    ld      a,[hl]
    cp      SAVE_GAME_VERSION
    jr      nz,.missing

    ld      a,1
    jr      .done

.missing:
    xor     a

.done:

    ; disable external RAM
    ld      hl,$0000
    ld      [hl],$00
    ei

    ret


; SRAM Saving -----------------------------------------------------------------
save_store_to_sram:

    di

    ; save current screens entities
    ld      a,[mapRoomX]
    ld      [mapRoomLastX],a
    ld      b,a
    ld      a,[mapRoomY]
    ld      [mapRoomLastY],a
    call    entity_store

    ; writing $0A anywhere into the $0000-1FFFF range will enable external ram
    ld      hl,$0000
    ld      [hl],$0A

    ; writing a byte into the $4000-$5FFF range will select corresponding ram bank
    ld      hl,$4000
    ld      [hl],SAVE_RAM_BANK

    ; crc16 checksum of the save data bytes starting from $A002
    ld      hl,$A000
    ld      a,$00
    ld      [hli],a
    ld      [hli],a

    ; game version
    ld      a,SAVE_GAME_VERSION
    ld      [hli],a

    ; Map Data
    ld      a,[mapRoomX]
    ld      [hli],a

    ld      a,[mapRoomY]
    ld      [hli],a

    ; Player State
    ld      b,SAVE_PLAYER_STATE_BYTES
    ld      de,playerX
.loop_player_state:
    ld      a,[de]
    inc     de
    ld      [hli],a
    dec     b
    jr      nz,.loop_player_state

    ; Script State
    ld      b,SCRIPT_TABLE_MAX_ENTRIES
    ld      de,scriptTableStatus
.loop_script_status:
    ld      a,[de]
    inc     de
    ld      [hli],a
    dec     b
    jr      nz,.loop_script_status

    ; Entity Data
    ld      a,$E5
    ld      [hli],a

    ; copy entity state to sram
    ld      bc,SAVE_ENTITY_DATA_SIZE
    ld      d,h
    ld      e,l
    ld      hl,entityStoredState
    call    core_mem_cpy

    ; caclulate checksum
    ld      bc,SAVE_COMPLETE_SIZE
    ld      de,$A000 + SAVE_CHECKSUM_SIZE
    call    _crc16

    ; write crc checksum
    ld      hl,$A000
    ld      a,b
    ld      [hli],a
    ld      [hl],c

    ; disable external RAM
    ld      hl,$0000
    ld      [hl],$00

    ei
    ret


; Helpers ---------------------------------------------------------------------
_crc16: ; de = source address, bc = byte count -> hl = crc
    push    hl
    ld	    hl,$ffff

.read:
    ld	    a,[de]
    inc	    de
    xor	    h
    ld	    h,a

    push    bc
    ld	    b,8

.crc_byte:
    add	    hl,hl
    jr	    nc,.next
    ld	    a,h
    xor	    $10
    ld	    h,a
    ld	    a,l
    xor	    $21
    ld	    l,a

.next:
    dec     b
    jr      nz,.crc_byte

    pop     bc
    dec     c
    jr	    nz,.read

    dec	    b
    jr	    nz,.read

    ld      b,h
    ld      c,l
    pop     hl

    ret

