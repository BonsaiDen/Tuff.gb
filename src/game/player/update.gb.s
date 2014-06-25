; Main Player Update Logic ----------------------------------------------------
player_update:

    ; do not update during screen transitions
    ld      a,[mapRoomUpdateRequired]
    cp      1
    ret     z

    ; check if we're dissolving
    ld      a,[playerDissolveTick]
    cp      255
    jp      z,.control

    ; wait for 25 ticks before flashing screen and resetting player position
    ld      a,[playerY]
    add     2
    ld      [playerYOffset],a

    ld      a,[playerDissolveTick]
    inc     a
    ld      [playerDissolveTick],a
    cp      30
    jp      nz,.update

    ld      a,255
    ld      [playerDissolveTick],a

    call    screen_flash_fast_dark
    call    save_load_from_sram
    
    ld      a,SOUND_GAME_SAVE_RESTORE_FLASH
    call    sound_play
    ret


    ; control / animation
.control:

    ; ignore when pounding
    ld      a,[playerIsPounding]
    cp      0
    jp      nz,.pounding

    call    player_accelerate
    call    player_decelerate
    call    player_move

.pounding:

    ; check for hazard (checked before gravity so we actually overlap a few pixels)
    ld      a,[mapCollisionFlag]
    cp      4; lava
    jp      z,player_dissolve
    cp      6; spikes
    jp      z,player_dissolve
    cp      7; electricity
    jp      z,player_dissolve

    ; pounding logic
    call    player_pound

    ; Jumping / Falling
    call    player_gravity
    call    player_slide_wall

    ; check for hazard once more after gravity got applied
    ld      a,[mapCollisionFlag]
    cp      4; lava
    jp      z,player_dissolve
    cp      6; spikes
    jp      z,player_dissolve
    cp      7; electricity
    jp      z,player_dissolve

    call    player_scroll_map
    cp      1
    ret     z; exit if the map got scrolled to prevent glitched collision access

    call    player_sleep

    ; y position for sprite
    ld      a,[playerY]
    ld      [playerYOffset],a

    ; now check for shallow water (swimming)
    ld      a,[playerY]
    sub     5
    ld      c,a
    ld      a,[playerX]
    ld      b,a
    call    map_get_collision

    ld      a,[mapCollisionFlag]
    cp      3
    jr      z,.under_water

    ; check if swimming
    cp      2 
    jr      z,.water

    ; check if was diving
    ld      a,[playerWasUnderWater]
    cp      1
    jp      nz,.check_diving

    ; ignore surface checks when at the very bottom of the screen
    ld      a,[playerY]
    cp      124; we get placed at 125 after upwards screen transition while in water
    jp      nc,.water

    ; detect surfacing
    ld      a,0
    ld      [playerUnderWater],a
    ld      [playerInWater],a
    jp      .water


    ; check for deep water (diving)
.check_diving:
    ld      a,[playerY]
    ld      c,a
    ld      a,[playerX]
    ld      b,a
    call    map_get_collision
    ld      a,[mapCollisionFlag]
    cp      3
    jr      z,.under_water

    ; reset water variables when on land
.land:
    ld      a,0
    ld      [playerInWater],a
    ld      [playerUnderWater],a
    ld      [playerWaterHitDone],a
    jp      .update

.under_water:
    ld      a,1
    ld      [playerUnderWater],a
    ld      [playerWasUnderWater],a
    jp      .water

.water:

    ; check ability
    ld      a,[playerCanSwim]
    cp      0
    jp      z,player_dissolve

    call    player_water_update

    ; swim animation
    ld      a,[playerUnderWater]
    cp      1
    jp      nz,.update

    ; do not overwrite pounding
    ld      a,[playerIsPounding]
    cp      0
    jp      nz,.update

    ; set swim animation when moving underwater
    ld      a,[coreInput]
    and     BUTTON_LEFT | BUTTON_RIGHT
    cp      0
    jp      z,.water_idle

    ; dont set animation when moving up / down
    ld      a,[coreInput]
    and     BUTTON_A | BUTTON_B
    cp      0
    jp      nz,.water_idle

    ; check if pushing against wall
    ld      a,[playerDirectionWall]
    cp      0
    jp      nz,.update

    ld      a,PLAYER_ANIMATION_SWIMMING
    ld      [playerAnimation],a

    jp      .update

    ; set idle animation in case neither a / b is pressed
.water_idle:
    ld      a,[coreInput]
    and     BUTTON_A | BUTTON_B
    cp      0
    jp      nz,.update

    ld      a,PLAYER_ANIMATION_IDLE
    ld      [playerAnimation],a

    ; animation / other logic
.update:

    ; update player sprite position
    ld      a,[playerX]
    ld      b,a
    ld      a,[playerYOffset]
    ld      c,a
    ld      a,PLAYER_SPRITE_INDEX
    call    sprite_set_position

    ret     

