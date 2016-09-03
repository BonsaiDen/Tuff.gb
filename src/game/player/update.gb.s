; Main Player Update Logic ----------------------------------------------------
player_update:

    ; do not update during screen transitions
    ld      a,[mapRoomUpdateRequired]
    cp      0
    ret     nz

    ; check if we're dissolving
    ld      a,[playerDissolveTick]
    cp      $ff
    jp      nz,_player_dissolve

    ; control / animation
.control:

    ; reset hazard flag
    xor     a
    ld      [mapHazardFlag],a

    ; ignore when controls are disabled
    ld      a,[playerHasControl]
    cp      0
    jp      z,_player_update

    ; ignore when pounding
    ld      a,[playerIsPounding]
    cp      0
    jr      nz,.pounding

    ; apply movement
    call    player_accelerate
    call    player_decelerate
    call    player_move

.pounding:

    ; pounding logic
    call    player_pound

    ; Jumping / Falling
    call    player_gravity
    call    player_platform
    call    player_slide_wall

    ; Check for hazards
    call    player_check_hazard

    ; check for map scrolling
    call    player_scroll_map
    cp      0
    ret     nz; exit if the map got scrolled to prevent glitched collision access

    ; check for sleep animation
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
    cp      MAP_COLLISION_WATER_DEEP
    jr      z,.under_water

    ; check if swimming
    cp      MAP_COLLISION_WATER
    jr      z,.water

    ; check if was diving
    ld      a,[playerWasUnderWater]
    cp      0
    jr      z,.check_diving

    ; ignore surface checks when at the very bottom of the screen
    ld      a,[playerY]
    cp      124; we get placed at 125 after upwards screen transition while in water
    jr      nc,.water

    ; detect surfacing
    xor     a
    ld      [playerUnderWater],a
    ld      [playerInWater],a
    jr      .water

    ; check for deep water (diving)
.check_diving:
    ld      a,[playerY]
    ld      c,a
    ld      a,[playerX]
    ld      b,a
    call    map_get_collision
    cp      MAP_COLLISION_WATER_DEEP
    jr      z,.under_water

    ; reset water variables when on land
.land:
    xor     a
    ld      [playerInWater],a
    ld      [playerUnderWater],a
    ld      [playerWaterHitDone],a
    jr      _player_update

.under_water:
    ld      a,1
    ld      [playerUnderWater],a
    ld      [playerWasUnderWater],a

.water:
    call    player_water_update

    ; swim animation
    ld      a,[playerUnderWater]
    cp      0
    jr      z,_player_update

    ; do not overwrite pounding
    ld      a,[playerIsPounding]
    cp      0
    jr      nz,_player_update

    ; set swim animation when moving underwater
    ld      a,[coreInput]
    and     BUTTON_LEFT | BUTTON_RIGHT
    jr      z,.water_idle

    ; dont set animation when moving up / down
    ld      a,[coreInput]
    and     BUTTON_A | BUTTON_B
    jr      nz,.water_idle

    ; check if pushing against wall
    ld      a,[playerDirectionWall]
    cp      0
    jr      nz,_player_update

    ld      a,PLAYER_ANIMATION_SWIMMING
    ld      [playerAnimation],a

    jr      _player_update

    ; set idle animation in case neither a / b is pressed
.water_idle:
    ld      a,[coreInput]
    and     BUTTON_A | BUTTON_B
    jr      nz,_player_update

    ld      a,PLAYER_ANIMATION_IDLE
    ld      [playerAnimation],a

    ; animation / other logic
_player_update:

    ; reset player platform status
    xor     a
    ld      [playerPlatformSpeed],a
    dec     a
    ld      [playerPlatformDirection],a

    ; update player sprite position
    ld      a,[playerX]
    ld      b,a
    ld      a,[playerYOffset]
    ld      c,a
    ld      a,PLAYER_SPRITE_INDEX
    call    sprite_set_position

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
    call    sprite_unset_mirrored
    jr      .direction_changed

.direction_right:
    ld      a,PLAYER_SPRITE_INDEX
    call    sprite_set_mirrored

.direction_changed:
    ld      a,[playerDirection]
    ld      [playerDirectionLast],a
    xor     a
    ld      [playerIsRunning],a
    ld      [playerRunningTick],a

.no_direction_change:

    ; check for animation changes
    ld      a,[playerAnimationLast]
    ld      b,a
    ld      a,[playerAnimation]
    cp      b
    ret     z

    ; switch to new animation
    ld      a,[playerAnimation]
    ld      [playerAnimationLast],a
    ld      b,a
    ld      a,PLAYER_SPRITE_INDEX
    call    sprite_set_animation
    ret


player_check_hazard: ; will NOT return if hazard was hit
    ld      a,[mapHazardFlag]
    cp      MAP_COLLISION_LAVA
    jr      z,.dissolve
    cp      MAP_COLLISION_SPIKES
    jr      z,.dissolve
    cp      MAP_COLLISION_ELECTRIC
    jr      z,.dissolve
    ret

.dissolve:
    jp      player_dissolve


_player_dissolve:
    and     %0000_0010
    cp      %0000_0010
    jr      nz,.no_offset

    ; move downwards when in lava
    ld      a,[mapHazardFlag]
    cp      MAP_COLLISION_LAVA
    jr      nz,.no_offset

    ld      a,[playerYOffset]
    inc     a
    ld      [playerYOffset],a

.no_offset:

    ; check for lava death
    ld      a,[mapHazardFlag]
    cp      MAP_COLLISION_LAVA
    jr      nz,.not_lava

    ; skip fire effects
    ld      a,[playerDissolveTick]
    cp      20
    jr      nc,.not_lava

    ; lava fire effects
    and     %0000_0110
    cp      %0000_0110
    jr      nz,.not_lava

    ; randomize x position
    call    math_random
    rrca
    rrca
    and     %0000_1111
    sub     4
    ld      c,a
    and     %0000_0011
    ld      d,a

    ; create flame effect
    ld      a,[playerX]
    add     c
    ld      c,a

    ld      a,[playerY]
    add     d
    add     4
    ld      b,a
    ld      a,EFFECT_FIRE_FLARE
    call    effect_create

    ; tick dissolve timer
.not_lava:
    ld      a,[playerDissolveTick]
    inc     a
    ld      [playerDissolveTick],a

    ; initialize flash before we actually reset
    cp      50
    jr      nz,.check_reset

.flash_reset:
    ld      a,SCREEN_PALETTE_FLASH | SCREEN_PALETTE_DARK
    call    screen_animate
    ret

.check_reset:

    ; wait another 20 ticks before resetting player position
    cp      70
    jp      nz,_player_update

    ; reset player
    ld      a,255
    ld      [playerDissolveTick],a

    ; restore from last savepoint
    call    save_load_from_sram

    ld      a,SOUND_EFFECT_GAME_SAVE_RESTORE_FLASH
    call    sound_play_effect_one
    ret

