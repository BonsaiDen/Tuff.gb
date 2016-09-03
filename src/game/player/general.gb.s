; High Level Player API -------------------------------------------------------
player_init:

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
    ld      a,PLAYER_SPRITE_INDEX
    ld      b,PLAYER_HARDWARE_SPRITE_INDEX
    call    sprite_set_hardware_index

    ret


player_reset:

    ; Gravity / Control
    ld      a,1
    ld      [playerGravityTick],a
    ld      [playerOnGround],a

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
    ld      [playerBreakContinue],a
    ld      [playerEffectCounter],a

    ; Movement
    ld      [playerSpeedRight],a
    ld      [playerSpeedLeft],a
    ld      [playerDecTick],a
    ld      [playerMoveTick],a
    ld      [playerLandingFrames],a
    ld      [playerWaterTick],a
    ld      [playerRunningTick],a

    ; Sliding
    ld      [playerDirectionWall],a
    ld      [playerWallSlideDir],a
    ld      [playerWallSlideTick],a
    ld      [playerWallJumpPressed],a
    ld      [playerWallJumpTick],a
    ld      [playerWallJumpWindow],a

    ; Jumping
    ld      a,PLAYER_DOUBLE_JUMP_THRESHOLD
    ld      [playerDoubleJumpThreshold],a

    ; Other
    ld      a,PLAYER_SLEEP_WAIT
    ld      [playerSleepTick],a

    ld      a,255
    ld      [playerDissolveTick],a
    ld      [playerPlatformDirection],a

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
    ld      a,[mapHazardFlag]
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

.done:
    ret


; Handle Map Scrolling --------------------------------------------------------
player_scroll_map:; -> a 1 if scrolled 0 if not

    ; left ------------------------------
    ld      a,[playerX]
    cp      2 ; < 1
    jr      nc,.check_right

    ld      a,MAP_ROOM_EDGE_RIGHT - 2
    ld      [playerX],a
    call    map_scroll_left
    xor     a
    call    break_horizontal_blocks_on_scroll

    jr      .scrolled


    ; right -----------------------------
.check_right:
    ld      a,[playerX]
    cp      MAP_ROOM_EDGE_RIGHT - 1 ; > 159
    jr      c,.check_up

    ld      a,3
    ld      [playerX],a
    call    map_scroll_right
    ld      a,1
    call    break_horizontal_blocks_on_scroll

    jr      .scrolled


    ; up --------------------------------
.check_up:

    ; add a boost to the jump to we can reach a platform or something
    ld      a,[playerUnderWater]
    cp      0
    jr      nz,.check_up_water

    ld      a,[playerY]
    cp      2 ; < 1
    jr      nc,.check_down

    ld      a,PLAYER_JUMP_SCREEN_BOOST
    ld      [playerJumpForce],a

    ld      a,PLAYER_GRAVITY_INTERVAL / 2
    ld      [playerGravityTick],a

    ld      a,MAP_ROOM_EDGE_BOTTOM - 2
    ld      [playerY],a

    call    map_scroll_up

    jr      .scrolled


.check_up_water:

    ld      a,[playerY]
    cp      5 ; < 6
    jr      nc,.check_down

    ld      a,MAP_ROOM_EDGE_BOTTOM - 4
    ld      [playerY],a

    call    map_scroll_up

    jr      .scrolled


    ; down ------------------------------
.check_down:

    ld      b,MAP_ROOM_EDGE_BOTTOM + 1; normal lower screen border when not under water

    ld      a,[playerUnderWater]
    cp      0
    jr      z,.check_down_ground
    ld      b,MAP_ROOM_EDGE_BOTTOM - 3; when under water we need to include the swim animation offset

.check_down_ground:
    ld      a,[playerY]
    cp      b
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
    ld      b,0
    ld      c,0
    ld      a,PLAYER_SPRITE_INDEX
    call    sprite_set_position

    ; continue wall sliding in case we were already sliding before the screen
    ; transition happened
    ld      a,[playerWallSlideTick]
    cp      0
    jr      z,.not_sliding
    ld      a,1
    ld      [playerWallSlideTick],a

.not_sliding:
    ld      a,1
    ret

