; Main Player Update Logic ----------------------------------------------------
player_update:

    ; do not update during screen transitions
    ld      a,[mapRoomUpdateRequired]
    cp      1
    ret     z

    ; check if we're dissolving
    ld      a,[playerDissolveTick]
    cp      255
    jr      z,.control

    ; wait for 25 ticks before flashing screen and resetting player position
    ld      a,[playerY]
    add     2
    ld      [playerYOffset],a

    ld      a,[playerDissolveTick]
    inc     a
    ld      [playerDissolveTick],a

    ; initialize flash before we actually reset
    cp      20
    jr      z,.flash_reset
    jr      .check_reset

.flash_reset:
    ld      a,SCREEN_PALETTE_FLASH | SCREEN_PALETTE_DARK
    call    screen_animate
    ret

.check_reset:
    cp      30
    jp      nz,.update

    ; reset player
    ld      a,255
    ld      [playerDissolveTick],a

    call    save_load_from_sram
    
    ld      a,SOUND_EFFECT_GAME_SAVE_RESTORE_FLASH
    call    sound_play_effect_one
    ret


    ; control / animation
.control:
    
    ; ignore when controls are disabled
    ld      a,[playerHasControl]
    cp      0
    jp      z,.update

    ; ignore when pounding
    ld      a,[playerIsPounding]
    cp      0
    jr      nz,.pounding

    call    player_accelerate
    call    player_decelerate
    call    player_move

.pounding:

    ; check for hazard (checked before gravity so we actually overlap a few pixels)
    ld      a,[mapCollisionFlag]
    cp      MAP_COLLISION_LAVA
    jr      z,.dissolve
    cp      MAP_COLLISION_SPIKES
    jr      z,.dissolve
    cp      MAP_COLLISION_ELECTRIC
    jr      z,.dissolve

    ; pounding logic
    call    player_pound

    ; Jumping / Falling
    call    player_gravity
    call    player_slide_wall

    ; check for hazard once more after gravity got applied
    ld      a,[mapCollisionFlag]
    cp      MAP_COLLISION_LAVA
    jr      z,.dissolve
    cp      MAP_COLLISION_SPIKES
    jr      z,.dissolve
    cp      MAP_COLLISION_ELECTRIC
    jr      z,.dissolve

    ; check for map scrolling
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
    cp      MAP_COLLISION_WATER_DEEP
    jr      z,.under_water

    ; check if swimming
    cp      MAP_COLLISION_WATER
    jr      z,.water

    ; check if was diving
    ld      a,[playerWasUnderWater]
    cp      1
    jr      nz,.check_diving

    ; ignore surface checks when at the very bottom of the screen
    ld      a,[playerY]
    cp      124; we get placed at 125 after upwards screen transition while in water
    jr      nc,.water

    ; detect surfacing
    xor     a
    ld      [playerUnderWater],a
    ld      [playerInWater],a
    jr      .water

.dissolve:
    jp      z,player_dissolve

    ; check for deep water (diving)
.check_diving:
    ld      a,[playerY]
    ld      c,a
    ld      a,[playerX]
    ld      b,a
    call    map_get_collision
    ld      a,[mapCollisionFlag]
    cp      MAP_COLLISION_WATER_DEEP
    jr      z,.under_water

    ; reset water variables when on land
.land:
    xor     a
    ld      [playerInWater],a
    ld      [playerUnderWater],a
    ld      [playerWaterHitDone],a
    jr      .update

.under_water:
    ld      a,1
    ld      [playerUnderWater],a
    ld      [playerWasUnderWater],a
    jr      .water

.water:

    ; check ability
    ld      a,[playerCanSwim]
    cp      0
    jr      z,.dissolve

    call    player_water_update

    ; swim animation
    ld      a,[playerUnderWater]
    cp      1
    jr      nz,.update

    ; do not overwrite pounding
    ld      a,[playerIsPounding]
    cp      0
    jr      nz,.update

    ; set swim animation when moving underwater
    ld      a,[coreInput]
    and     BUTTON_LEFT | BUTTON_RIGHT
    cp      0
    jr      z,.water_idle

    ; dont set animation when moving up / down
    ld      a,[coreInput]
    and     BUTTON_A | BUTTON_B
    cp      0
    jr      nz,.water_idle

    ; check if pushing against wall
    ld      a,[playerDirectionWall]
    cp      0
    jr      nz,.update

    ld      a,PLAYER_ANIMATION_SWIMMING
    ld      [playerAnimation],a

    jr      .update

    ; set idle animation in case neither a / b is pressed
.water_idle:
    ld      a,[coreInput]
    and     BUTTON_A | BUTTON_B
    cp      0
    jr      nz,.update

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

