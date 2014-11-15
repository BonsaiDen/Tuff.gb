; High Level Player API -------------------------------------------------------
player_init:

    ; Position 
    ld      a,24
    ld      [playerX],a
    ld      a,62
    ld      [playerY],a
    ld      [playerYOffset],a

    ; Direction
    ld      a,PLAYER_DIRECTION_RIGHT
    ld      [playerDirection],a
    xor     a
    ld      [playerDirectionLast],a

    ; Animation
    ld      a,PLAYER_ANIMATION_IDLE
    ld      [playerAnimation],a
    ld      a,255
    ld      [playerAnimationLast],a

    ; Jumping / Falling
    call    player_reset

    ; Sprite
    ld      a,PLAYER_SPRITE_INDEX
    call    sprite_enable
    ld      b,0
    call    sprite_set_tile_offset

    ; Load initial sprite data
    call    player_animation_init
    call    player_animation_update

    ret


player_reset:

    ; Gravity / Control
    ld      a,1
    ld      [playerGravityTick],a
    ld      a,PLAYER_GRAVITY_MAX
    ld      [playerGravityMax],a
    ld      [playerHasControl],a

    xor     a
    ld      [playerJumpForce],a
    ld      [playerJumpPressed],a
    ld      [playerGravityDelay],a
    ld      [playerFallSpeed],a
    ld      [playerUnderWater],a
    ld      [playerWasUnderWater],a
    ld      [playerIsPounding],a
    ld      [playerIsRunning],a
    ld      [playerInWater],a
    ld      [playerDoubleJumped],a
    ld      [playerFallFrames],a
    ld      [playerJumpFrames],a
    ld      [playerBreakDelayed],a
    ld      [playerJumpHold],a

    ld      a,1
    ld      [playerOnGround],a

    ; Movement
    xor     a
    ld      [playerSpeedRight],a
    ld      [playerSpeedLeft],a
    ld      [playerDecTick],a
    ld      [playerMoveTick],a
    ld      [playerLandingFrames],a
    ld      [playerWaterTick],a
    ld      [playerRunningTick],a

    ; Sliding
    xor     a
    ld      [playerDirectionWall],a
    ld      [playerWallSlideDir],a
    ld      [playerWallSlideTick],a
    ld      [playerWallJumpPressed],a
    ld      [playerWallJumpTick],a

    ; Other
    ld      a,PLAYER_SLEEP_WAIT
    ld      [playerSleepTick],a

    ld      a,255
    ld      [playerDissolveTick],a

    ret


PlayerDissolveSounds:
    DB      $00; none
    DB      $00; block
    DB      SOUND_EFFECT_PLAYER_DEATH_LAVA; water, TODO new effect
    DB      $00; water deep
    DB      SOUND_EFFECT_PLAYER_DEATH_LAVA; lava
    DB      $00; breakable
    DB      SOUND_EFFECT_PLAYER_DEATH_LAVA; spikes, TODO new effect
    DB      SOUND_EFFECT_PLAYER_DEATH_ELECTRIC


player_dissolve:

    ; jump out if already dissolving
    ld      a,[playerDissolveTick]
    cp      255
    jr      nz,.done

    ; get sound to play
    ld      a,[mapCollisionFlag]
    ld      hl,PlayerDissolveSounds
    ld      b,0
    ld      c,a
    add     hl,bc
    ld      a,[hl]
    call    sound_play_effect_one

    ; dissolve player when hitting a hazard
    ld      a,PLAYER_ANIMATION_DISSOLVE
    ld      [playerAnimation],a
    xor     a
    ld      [playerDissolveTick],a
    ld      [mapCollisionFlag],a

.done:
    ret


; Handle Map Scrolling --------------------------------------------------------
player_scroll_map:

    ; left ------------------------------
    ld      a,[playerX]
    cp      2 ; < 1
    jr      nc,.check_right

    ld      a,157
    ld      [playerX],a
    call    map_scroll_left

    jr      .scrolled


    ; right -----------------------------
.check_right:
    ld      a,[playerX]
    cp      158 ; > 159
    jr      c,.check_up

    ld      a,3
    ld      [playerX],a
    call    map_scroll_right

    jr      .scrolled


    ; up --------------------------------
.check_up:

    ; add a boost to the jump to we can reach a platform or something
    ld      a,[playerUnderWater]
    cp      1
    jr      z,.check_up_water

    ld      a,[playerY]
    cp      2 ; < 1
    jr      nc,.check_down

    ld      a,PLAYER_JUMP_SCREEN_BOOST
    ld      [playerJumpForce],a

    ld      a,PLAYER_GRAVITY_INTERVAL / 2
    ld      [playerGravityTick],a

    ld      a,125
    ld      [playerY],a

    call    map_scroll_up

    jr      .scrolled


.check_up_water:

    ld      a,[playerY]
    cp      5 ; < 6
    jr      nc,.check_down

    ld      a,125
    ld      [playerY],a

    call    map_scroll_up

    jr      .scrolled


    ; down ------------------------------
.check_down:

    ld      b,130; normal border when not under water

    ld      a,[playerUnderWater]
    cp      1
    jr      nz,.check_down_ground
    ld      b,126; under water we need to include the swim animation offset

.check_down_ground:
    ld      a,[playerY]
    cp      b ; 
    jr      c,.done

    ld      a,6
    ld      [playerY],a
    call    map_scroll_down

    ld      a,PLAYER_GRAVITY_INTERVAL
    ld      [playerGravityTick],a
    jr      .scrolled

.done:
    xor     a
    ret

.scrolled:
    ld      b,255
    ld      c,255
    ld      a,PLAYER_SPRITE_INDEX
    call    sprite_set_position
    ld      a,1
    ret

