SECTION "SaveLogic",ROM0

; Constants -------------------------------------------------------------------
SAVE_GAME_VERSION          EQU 9

SAVE_HEADER_SIZE           EQU 3
SAVE_VERSION_SIZE          EQU 1
SAVE_CHECKSUM_SIZE         EQU 2
SAVE_PLAYER_DATA_SIZE      EQU 12
SAVE_ENTITY_HEADER_SIZE    EQU 1
SAVE_ENTITY_DATA_SIZE      EQU ENTITY_STORED_STATE_SIZE
SAVE_COMPLETE_SIZE         EQU SAVE_HEADER_SIZE + SAVE_VERSION_SIZE + SAVE_PLAYER_DATA_SIZE + SAVE_ENTITY_HEADER_SIZE + SAVE_ENTITY_DATA_SIZE

SAVE_DEFAULT_PLAYER_X      EQU 12
SAVE_DEFAULT_PLAYER_Y      EQU 48
SAVE_DEFAULT_ROOM_X        EQU 2
SAVE_DEFAULT_ROOM_Y        EQU 0
SAVE_RAM_BANK              EQU 0


; SRAM Handling Routines ------------------------------------------------------
save_load_from_sram:; a = 1 triggers defaults
    
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

    ; check header
    ld      a,[hli]
    cp      $12
    jr      nz,.defaults

    ld      a,[hli]
    cp      $34
    jr      nz,.defaults

    ld      a,[hli]
    cp      $56
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

    ; Player Data
    ld      a,[hli]
    ld      [playerX],a

    ld      a,[hli]
    ld      [playerY],a

    ld      a,[hli]
    ld      [playerDirection],a

    ; Player Abilities
    ld      a,[hli]
    ld      [playerCanJump],a
    
    ld      a,[hli]
    ld      [playerCanWallJump],a

    ld      a,[hli]
    ld      [playerCanSwim],a

    ld      a,[hli]
    ld      [playerCanDive],a

    ld      a,[hli]
    ld      [playerCanPound],a

    ld      a,[hli]
    ld      [playerCanRun],a

    ld      a,[hli]
    ld      [playerCanDoubleJump],a

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
    ld      a,1
    ld      [playerCanJump],a

    ld      a,1
    ld      [playerCanWallJump],a

    ld      a,1
    ld      [playerCanSwim],a

    ld      a,1
    ld      [playerCanDive],a

    ld      a,1
    ld      [playerCanPound],a

    ld      a,1
    ld      [playerCanRun],a

    ld      a,1
    ld      [playerCanDoubleJump],a

.init:
    
    ld      a,[mapRoomX]
    ld      b,a
    ld      a,[mapRoomY]
    ld      c,a

    call    map_load_room
    call    player_reset

    ret


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

    ; header prefix
    ld      a,$12
    ld      [hli],a

    ld      a,$34
    ld      [hli],a

    ld      a,$56
    ld      [hli],a

    ; game version
    ld      a,SAVE_GAME_VERSION
    ld      [hli],a

    ; Map Data
    ld      a,[mapRoomX]
    ld      [hli],a

    ld      a,[mapRoomY]
    ld      [hli],a

    ; Player Data
    ld      a,[playerX]
    ld      [hli],a

    ld      a,[playerY]
    ld      [hli],a

    ld      a,[playerDirection]
    ld      [hli],a

    ; Player Abilities
    ld      a,[playerCanJump]
    ld      [hli],a

    ld      a,[playerCanWallJump]
    ld      [hli],a

    ld      a,[playerCanSwim]
    ld      [hli],a

    ld      a,[playerCanDive]
    ld      [hli],a

    ld      a,[playerCanPound]
    ld      [hli],a

    ld      a,[playerCanRun]
    ld      [hli],a

    ld      a,[playerCanDoubleJump]
    ld      [hli],a

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
    ld      a,c
    ld      [hl],a

    ; disable external RAM
    ld      hl,$0000 
    ld      [hl],$00

    ei
    ret


save_check_state: ; return 1 in a if a save state exists in sram

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

    ; check header
    ld      a,[hli]
    cp      $12
    jr      nz,.missing

    ld      a,[hli]
    cp      $34
    jr      nz,.missing

    ld      a,[hli]
    cp      $56
    jr      nz,.missing

    ; game version
    ld      a,[hli]
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


; Helpers ---------------------------------------------------------------------
; de = source address, bc = byte count -> hl = crc
_crc16:
    push    hl
    ld	    hl,$ffff

.read:
    ld	    a,[de]
    inc	    de
    xor	    h
    ld	    h,a

    push    bc
    ld	    b,8

.crcByte:
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
    jr      nz,.crcByte

    pop     bc
    dec     c
    jr	    nz,.read

    dec	    b
    jr	    nz,.read

    ld      b,h
    ld      c,l
    pop     hl

    ret

