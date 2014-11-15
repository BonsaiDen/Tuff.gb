; Animation -------------------------------------------------------------------
playerAnimationRowMap:
    DB 0; IDLE      
    DB 1; WALKING   
    DB 3; SLEEP     
    DB 4; PUSHING   
    DB 2; JUMP      
    DB 2; FALL      
    DB 9; RUNNING FULL
    DB 6; SWIMMING  
    DB 7; DISSOLVE  
    DB 2; SURFACE   
    DB 0; SLIDE     
    DB 5; POUND START
    DB 5; POUND STOP
    DB 8; LANDING
    DB 2; DOUBLE JUMP      
    DB 1; RUNNING HALF


player_animation_update: ; executed during vblank

    ; check for direction changes
    ld      a,[playerDirectionLast]
    ld      b,a
    ld      a,[playerDirection]
    cp      b
    jr      z,.no_direction_change

    ; switch to new direction
    cp      PLAYER_DIRECTION_RIGHT
    jr      z,.direction_right

.direction_left:
    ld      a,PLAYER_SPRITE_INDEX
    call    sprite_unset_mirror
    jr      .direction_changed

.direction_right:
    ld      a,PLAYER_SPRITE_INDEX
    call    sprite_set_mirror
    jr      .direction_changed

.direction_changed:
    ; TODO reset animation frame?
    ; right now this depends on the animate_all updating the tile 
    ; we need a separate function here though
    ld      a,[playerDirection]
    ld      [playerDirectionLast],a
    xor     a
    ld      [playerIsRunning],a
    xor     a
    ld      [playerRunningTick],a

.no_direction_change:

    ; check for animation changes
    ld      a,[playerAnimationLast]
    ld      b,a
    ld      a,[playerAnimation]
    cp      b
    ret     z

    ; get new animation
    ld      a,[playerAnimation]
    ld      b,a

    ; switch to new animation
    ld      a,PLAYER_SPRITE_INDEX
    call    sprite_animation_set
    call    sprite_animation_start

    ; flag as changed
    ld      a,b
    ld      [playerAnimationLast],a

    ; calculate offset into sprite RAM 
    add     dataPlayerSpriteMap >> 8
    ld      h,a; x256
    ld      l,0

    ; setup sprite ram target pointer ($8000 or $8100)
    ld      a,[playerAnimationRow]
    add     $80
    ld      d,a
    ld      e,0
    ld      bc,128; 256 bytes
    call    core_vram_cpy

    ; set up tile offset
    ld      a,[playerAnimationRow]
    add     a; x2
    add     a; x4
    ld      b,a

    ; update offset for player sprite
    ld      a,PLAYER_SPRITE_INDEX
    call    sprite_set_tile_offset

    ; toggle row
    ld      a,[playerAnimationRow]
    xor     1
    ld      [playerAnimationRow],a

    ret


player_animation_init:

    ; unload compressed tile rows into RAM 
    ld     b,0
.loop:

    ; load row index in sprite map into c
    ld     hl,playerAnimationRowMap
    ld     d,0
    ld     e,b
    add    hl,de
    ld     a,[hl]
    ld     c,a

    ld     hl,DataPlayerImg
    ld     de,dataPlayerSpriteMap
    call   tileset_load_sprite_row

    ; next
    inc    b
    ld     a,b
    cp     PLAYER_ANIMATION_COUNT
    jr     nz,.loop
    ret

