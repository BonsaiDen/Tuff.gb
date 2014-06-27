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

    ld      a,[rLY]
    cp      148
    ret     nc

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
    jr      z,.done

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

    ; flag for update
    ld      a,1
    ld      [playerAnimationUpdate],a

.done:
    ret

player_animation_update_tile:

    ; check if we need to update the tile data for the player
    ld      a,[playerAnimationUpdate]
    cp      0
    ret     z
    
    ; figure out which row in the sprite sheet maps
    ; to the current animation
    ld      a,[playerAnimation]
    ld      hl,playerAnimationRowMap
    ld      d,0
    ld      e,a
    add     hl,de
    ld      a,[hl]

    ; load the corresponding row into vram
    ld      hl,DataPlayerImg
    ld      b,0
    ld      c,a
    ld      de,$8000
    call    tileset_load_sprite_row

    xor     a
    ld      [playerAnimationUpdate],a

    ret

