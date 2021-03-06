; Wall Sliding / Jumping Logic ------------------------------------------------
player_slide_wall:

    ; check ability
    ld      a,[playerAbility]
    and     PLAYER_ABILITY_WALL_JUMP
    ret     z

    ; if we're still in the ground hit animation where the player can't move
    ; disable and wall sliding
    ld      a,[playerLandingFrames]
    cp      0
    ret     nz

    ; check if wall jump was performed
    ld      a,[playerWallJumpTick]
    cp      0
    jp      nz,.wall_jump_speed


    ; check if on ground / in water
    ld      a,[playerOnGround]
    cp      0
    jp      nz,.on_ground

    ; check if on ground
    ld      a,[playerInWater]
    cp      0
    jp      nz,.on_ground

    ; check if falling
    ld      a,[playerFallSpeed]
    cp      0
    jr      z,.not_pressing_wall ; if fall speed is <= 1 do not slide

    ; check if pressing against a wall
    ld      a,[playerDirectionWall]
    cp      0
    jr      z,.not_pressing_wall

    ; check if player is pressing joypad in wall direction
    ld      b,a
    ld      a,[playerDirection]
    cp      b
    jr      nz,.not_pressing_wall

.pressing_wall:
    ld      b,a ; store wall direction

    ; check if already sliding
    ld      a,[playerWallSlideTick]
    cp      0 ; check if not sliding
    jr      nz,.sliding

    ; if pressing against a wall and not sliding and
    ; directionWall != slideDirection init slide
    ; only allow slide if dir = 0 or after wall jump
    ; in case of wall jump, still do not allow the same wall to be used again
    ld      a,[playerWallSlideDir]
    cp      b
    ret     z ; exit if same direction

    ; check if player fully touches the wall before initiating a slide
    ld      a,[playerDirection]
    cp      PLAYER_DIRECTION_RIGHT
    jr      z,.slide_right

.slide_left:
    call    player_collision_left_all
    ret     nc
    call    player_slide_wall_init
    ret

.slide_right:
    call    player_collision_right_all
    ret     nc
    call    player_slide_wall_init
    ret

.sliding:


    ; if sliding for more than X frames end slide
    cp      PLAYER_SLIDE_DURATION
    jr      z,.sliding_done

    ; otherwise continue sliding
    ld      b,a
    inc     a
    ld      [playerWallSlideTick],a

    ld      a,PLAYER_ANIMATION_SLIDE
    ld      [playerAnimation],a

    ; wall slide dust effect
    ld      a,[coreLoopCounter]
    and     %0000_0111
    cp      %0000_0111
    ret     nz

    ; only create effect after at least 8 frames of sliding
    ld      a,b
    cp      8
    ret     c; >= 8

    ; setup effect position
    ld      a,[playerY]
    ld      b,a

    ld      a,[playerDirectionWall]
    cp      2
    jr      z,.sliding_right

    ; left side
    ld      d,EFFECT_WALL_DUST_LEFT
    ld      a,[playerX]
    add     2
    jr      .sliding_effect

    ; right side
.sliding_right:
    ld      d,EFFECT_WALL_DUST_RIGHT
    ld      a,[playerX]
    add     6

.sliding_effect:
    ld      c,a
    ld      a,d
    call    effect_create
    ret


.sliding_done:

    call    player_slide_wall_stop
    xor     a
    ld      [playerWallSlideTick],a

    ld      a,PLAYER_WALL_JUMP_WINDOW
    ld      [playerWallJumpWindow],a
    ret


.not_pressing_wall:

    ; check wall jump window
    ld      a,[playerWallJumpWindow]
    cp      0
    jr      nz,.check_wall_jump

    ; if sliding and no longer pressing, end slide
    ld      a,[playerWallSlideTick]
    cp      0
    ret     z ; if not sliding, do nothing

    ; otherwise stop the slide and set the correct direction
    call    player_slide_wall_stop

    ; we have X frames where a wall jump can be executed by pressing
    ; the joypad away from the last jump direction and pressing the jump
    ; button at the same time
    ld      a,PLAYER_WALL_JUMP_WINDOW
    ld      [playerWallJumpWindow],a

    ret


.on_ground:

    ; if we didnt slide we dont need to reset
    ld      a,[playerWallSlideDir]
    cp      0
    ret     z

    ; otherwise reset the sliding state and switch the direction
    call    player_slide_wall_stop
    xor     a
    ld      [playerWallSlideDir],a

    ret


.check_wall_jump:

    ; decrease window for wall jump
    ld      a,[playerWallJumpWindow]
    dec     a
    ld      [playerWallJumpWindow],a

    ; check last wall direction against player direction, must be different
    ld      a,[playerDirection]
    ld      b,a
    ld      a,[playerWallSlideDir]
    cp      b
    ret     z ; player must press joypad away from the wall he slided on, otherwise return

    ; check if button was hold down since the last jump, if so don't jump again
    ld      a,[playerWallJumpPressed]
    cp      0
    ret     nz

    ; check if jump button is pressed pressed
    ld      a,[coreInput]
    and     BUTTON_A
    ret     z; return if zero

    ; check for how many frames the button was hold down
    ; this prevents situations where we jump the wall
    ; and just change direction to trigger the wall jump
    ; we actually NEED to release the jump button and press it again
    ld      a,[playerJumpHold]
    cp      3
    ret     nc; if > 5 exit

    ; set up jump force and reset fall speed
    ld      a,PLAYER_JUMP_WALL
    ld      [playerJumpForce],a

    ld      a,PLAYER_GRAVITY_INTERVAL
    ld      [playerGravityTick],a

    ; reset jump variables
    xor     a
    ld      [playerFallFrames],a
    ld      [playerFallSpeed],a
    ld      [playerJumpFrames],a
    ld      [playerWallJumpWindow],a
    ld      [playerDoubleJumped],a

    ; setup forced movement away from the wall
    ld      a,[playerWallSlideDir]
    ld      [playerWallJumpDir],a

    ; reset old slide dir
    xor     a
    ld      [playerWallSlideDir],a

    ld      a,PLAYER_WALL_JUMP_DURATION
    ld      [playerWallJumpTick],a

    ; set up jump button state
    ld      a,1
    ld      [playerWallJumpPressed],a

    ; disable double jump during wall jump
    ld      [playerDoubleJumped],a

    ; play sound
    ld      a,SOUND_EFFECT_PLAYER_WALL_JUMP
    call    sound_play_effect_one

    ; dust gfx
    ld      a,[playerY]
    ld      b,a

    ld      a,[playerWallJumpDir]
    cp      PLAYER_DIRECTION_RIGHT
    jr      z,.effect_right

.effect_left:
    ld      a,[playerX]
    add     2
    ld      c,a
    ld      a,EFFECT_DUST_SIDE_LEFT
    jr      .effect

.effect_right:
    ld      a,[playerX]
    add     4
    ld      c,a
    ld      a,EFFECT_DUST_SIDE_RIGHT

.effect:
    call    effect_create
    ret


.wall_jump_speed:

    ; decrease ticks left for wall jump speed boost
    ld      a,[playerWallJumpTick]
    dec     a
    ld      [playerWallJumpTick],a
    cp      0
    jr      z,.stop

    ; modify player speed variable
    ld      a,[playerWallJumpDir]
    cp      PLAYER_DIRECTION_LEFT
    jr      z,.right

.left:
    ld      a,2
    ld      [playerSpeedLeft],a
    xor     a
    ld      [playerSpeedRight],a
    ret

.right:
    ld      a,2
    ld      [playerSpeedRight],a
    xor     a
    ld      [playerSpeedLeft],a
    ret

.stop:
    xor     a
    ld      [playerSpeedRight],a
    ld      [playerSpeedLeft],a
    ret


player_slide_wall_init:
    ld      a,[playerDirectionWall]
    ld      [playerWallSlideDir],a
    ld      a,1
    ld      [playerWallSlideTick],a
    ret


player_slide_wall_stop:

    ; avoid graphical glitches when switching animation and direction
    ld      a,PLAYER_ANIMATION_FALL
    ld      [playerAnimation],a

    ; reset tick
    xor     a
    ld      [playerWallSlideTick],a
    ld      [playerWallJumpWindow],a

    ; reset fall frames
    ld      [playerFallFrames],a

    ret

