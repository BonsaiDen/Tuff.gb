; Horizontal Player Movement --------------------------------------------------
player_move:

    ; check for landing frames
    ld      a,[playerLandingFrames]
    cp      0
    jp      nz,.landing

    ; are we moving at all?
    ld      a,[playerSpeedLeft]
    ld      b,a
    ld      a,[playerSpeedRight]
    add     a,b
    cp      0
    jp      z,.stopped

    ; set walking animation only when on ground
    ld      a,[playerOnGround]
    cp      1
    jr      nz,.not_on_ground

    ; check if we're running at full speed
    ld      a,[playerIsRunning]
    cp      1
    jr      z,.running_half
    cp      2
    jr      z,.running_full

.not_running:
    ld      a,PLAYER_ANIMATION_WALKING
    ld      [playerAnimation],a
    jr      .not_on_ground
    
.running_half:
    ld      a,PLAYER_ANIMATION_RUNNING_HALF
    ld      [playerAnimation],a
    jr      .not_on_ground

.running_full:
    ld      a,PLAYER_ANIMATION_RUNNING_FULL
    ld      [playerAnimation],a

.not_on_ground:
    ld      a,[playerInWater]
    cp      0
    jr      z,.not_in_water

    ; half speed when in water
    ld      a,[playerMoveTick]
    cp      1
    jp      nz,.delay
    xor     a
    ld      [playerMoveTick],a

.not_in_water:

    ; load x position
    ld      a,[playerX]
    ld      d,a

    ; move right -----------------------------------
.move_right:
    ld      a,[playerSpeedRight]
    cp      0
    jr      z,.move_left
    ld      e,a

    ; reset wall flag
    xor     a
    ld      [playerDirectionWall],a

.loop_right:

    call    player_collision_right
    cp      0
    jr      z,.not_blocked_right

    ; check for wall hit
    call    player_wall_hit
    cp      1
    jr      z,.not_blocked_right; we broke a block continue moving

    ; set wall flag
    ld      a,PLAYER_DIRECTION_RIGHT
    ld      [playerDirectionWall],a

    ; set pushing animation when not in water
    ld      a,[playerInWater]
    cp      0
    jr      z,.pushing_right
    jr      .idle_right

.pushing_right:
    call    player_collision_right_all
    cp      0
    jr      z,.idle_right
    ld      a,[playerOnGround]
    cp      1
    jr      nz,.idle_right
    ld      a,PLAYER_ANIMATION_PUSHING
    ld      [playerAnimation],a
    jr      .move_left

.idle_right:
    ld      a,PLAYER_ANIMATION_IDLE
    ld      [playerAnimation],a
    jr      .move_left

.not_blocked_right:
    ld      a,[playerInWater]
    cp      1
    jr      nz,.not_in_water_right
    ld      a,PLAYER_ANIMATION_SWIMMING
    ld      [playerAnimation],a

.not_in_water_right:
    inc     d
    ld      a,d
    ld      [playerX],a
    dec     e
    jr      nz,.loop_right


    ; move left ------------------------------------
.move_left:
    ld      a,[playerSpeedLeft]
    cp      0
    jr      z,.moved
    ld      e,a

    ; reset wall flag
    xor     a
    ld      [playerDirectionWall],a

.loop_left:

    call    player_collision_left
    cp      0
    jr      z,.not_blocked_left

    ; check for wall hit
    call    player_wall_hit
    cp      1
    jr      z,.not_blocked_left; we broke a block continue moving

    ; set wall flag
    ld      a,PLAYER_DIRECTION_LEFT
    ld      [playerDirectionWall],a

    ; set pushing animation when not in water
    ld      a,[playerInWater]
    cp      0
    jr      z,.pushing_left
    jr      .idle_left

.pushing_left:
    call    player_collision_left_all
    cp      0
    jr      z,.idle_left
    ld      a,[playerOnGround]
    cp      1
    jr      nz,.idle_left
    ld      a,PLAYER_ANIMATION_PUSHING
    ld      [playerAnimation],a
    jr      .moved

.idle_left:
    ld      a,PLAYER_ANIMATION_IDLE
    ld      [playerAnimation],a
    jr      .moved

.not_blocked_left:
    ld      a,[playerInWater]
    cp      1
    jr      nz,.not_in_water_left
    ld      a,PLAYER_ANIMATION_SWIMMING
    ld      [playerAnimation],a

.not_in_water_left:
    dec     d
    ld      a,d
    ld      [playerX],a
    dec     e
    jr      nz,.loop_left


    ; moved ----------------------------------------
.moved:
    ld      a,d
    ld      [playerX],a
    ret     z

.stopped: 

    ; reset wall flag when no direction is pressed
    ld      a,[coreInput]
    and     BUTTON_RIGHT | BUTTON_LEFT
    jr      nz,.reset
    xor     a
    ld      [playerDirectionWall],a

    ; reset to idle animation if on ground
.reset:
    ld      a,[playerOnGround]
    cp      0
    jr      z,.stopped_water

    ld      a,PLAYER_ANIMATION_IDLE
    ld      [playerAnimation],a
    ret

.stopped_water:
    ld      a,[playerInWater]
    cp      0
    ret     z

    ld      a,PLAYER_ANIMATION_IDLE
    ld      [playerAnimation],a
    ret

.delay:
    inc     a
    ld      [playerMoveTick],a
    ret

.landing:
    dec     a
    ld      [playerLandingFrames],a
    cp      0
    ret     nz

    ld      a,PLAYER_ANIMATION_IDLE
    ld      [playerAnimation],a
    ret


; Horizontal Acceleration -----------------------------------------------------
player_accelerate:

    ; skip during wall jump with forced horizontal movement
    ld      a,[playerWallJumpTick]
    cp      0
    ret     nz

    ; skip while pounding
    ld      a,[playerIsPounding]
    cp      0
    ret     nz

    ; if both directions are pressed at the same time ignore input
    ld      a,[coreInput]
    and     BUTTON_LEFT | BUTTON_RIGHT
    cp      BUTTON_LEFT | BUTTON_RIGHT
    ret     z

    ; check for B button and running
    ld      a,[playerCanRun]
    cp      1
    jr      nz,.is_not_running

    ld      a,[playerOnGround]; needs to be on ground
    cp      1
    jr      nz,.is_not_running

    ld      a,[playerInWater]; not in water
    cp      1
    jr      z,.is_not_running

    ld      a,[coreInput]; and hold the B button
    and     BUTTON_B
    jr      z,.is_not_running

    ld      a,[coreInput]; and either direction is still pressed
    and     BUTTON_RIGHT | BUTTON_LEFT
    cp      0
    jr      z,.is_not_running

    ; increase running tick unless limit is reached
    ld      a,[playerRunningTick]
    cp      PLAYER_RUNNING_DELAY
    jr      z,.is_running_half

    cp      PLAYER_RUNNING_DELAY_FULL
    jr      z,.is_running_full

    inc     a
    ld      [playerRunningTick],a
    jr      .check_running_end

    ; set running mode when tick limits get reached
.is_running_half:
    inc     a
    ld      [playerRunningTick],a
    ld      a,1
    ld      [playerIsRunning],a
    jr      .check_running_end

.is_running_full:
    ld      a,2
    ld      [playerIsRunning],a
    jr      .check_running_end

    ; reset the running ticks if the conditions are not met
.is_not_running:
    xor     a
    ld      [playerRunningTick],a

.check_running_end:
    
    ; check if we should disabled the running flag
    ; this happens once we loose the running conditions
    ; and touch ground or enter water
    ld      a,[playerRunningTick]
    cp      PLAYER_RUNNING_DELAY; >= 
    jr      nc,.check_direction

    ; check for matching direction button
    ld      a,[playerDirection]
    cp      PLAYER_DIRECTION_RIGHT
    jr      z,.check_running_end_right

    ; left
    ld      a,[coreInput]
    and     BUTTON_LEFT
    jr      z,.stop_running
    jr      .check_running_state

.check_running_end_right:
    ld      a,[coreInput]
    and     BUTTON_RIGHT
    jr      z,.stop_running

    ; if not running check for ground or water or wall slide
.check_running_state:
    ld      a,[playerWallSlideDir]
    ld      c,a
    ld      a,[playerOnGround]
    ld      b,a
    ld      a,[playerInWater]
    or      b; 
    or      c; 
    cp      0
    jr      z,.check_direction; if both are false keep running
    
    ; if either is true reset running mode
.stop_running:
    xor     a
    ld      [playerIsRunning],a

    ; check which direction is pressed
.check_direction:
    ld      a,[coreInput]
    and     BUTTON_LEFT
    cp      BUTTON_LEFT
    jr      z,.acc_left

    ld      a,[coreInput]
    and     BUTTON_RIGHT
    cp      BUTTON_RIGHT
    jr      z,.acc_right

    ret ; not moving in any direction

.acc_right:
    ld      hl,playerSpeedRight

    ; set player direction
    ld      a,PLAYER_DIRECTION_RIGHT
    ld      [playerDirection],a
    jr      .accelerate

.acc_left:
    ld      hl,playerSpeedLeft

    ; set player direction
    ld      a,PLAYER_DIRECTION_LEFT
    ld      [playerDirection],a

.accelerate:
    ld      a,[playerIsRunning]
    cp      1
    jr      z,.running_half
    cp      2
    jr      z,.running_full

    ld      b,PLAYER_SPEED_NORMAL
    jr      .increase

.running_half:
    ld      b,PLAYER_SPEED_FAST
    jr      .increase

.running_full:
    ld      b,PLAYER_SPEED_FULL
    jr      .increase

    ; load speed from corresponding direction variable 
.increase:
    ld      a,[hl]
    cp      b; >= max speed
    ret     z
    ret     nc
    inc     a
    ld      [hl],a
    ret


player_decelerate:

    ; only decelerate on every 10th frame
    ; this introduces "lag" or a sliding when turning rapidly
    ld      a,[playerDecTick]
    inc     a
    cp      10
    jr      z,.decrease_right

    ; if not on 10th frame store frame count and return
    ld      [playerDecTick],a
    ret

.decrease_right:

    ; check if running
    ld      a,[playerSpeedRight]
    cp      PLAYER_SPEED_FAST
    jr      z,.decrease_right_forced
    cp      PLAYER_SPEED_FULL
    jr      z,.decrease_right_forced

    ; check if right direction is still pressed
    ld      a,[coreInput]
    and     BUTTON_RIGHT
    jr      nz,.decrease_left

    ; right
.decrease_right_forced:
    ld      a,[playerSpeedRight]
    cp      0
    jr      z,.decrease_left
    dec     a
    ld      [playerSpeedRight],a

.decrease_left:

    ; check if running
    ld      a,[playerSpeedLeft]
    cp      PLAYER_SPEED_FAST
    jr      z,.decrease_left_forced
    cp      PLAYER_SPEED_FULL
    jr      z,.decrease_left_forced

    ; check if left direction is still pressed
    ld      a,[coreInput]
    and     BUTTON_LEFT
    jr      nz,.no_decrease

    ; left
.decrease_left_forced:
    ld      a,[playerSpeedLeft]
    cp      0
    jr      z,.no_decrease ; if it reached zero we're done

    dec     a
    ld      [playerSpeedLeft],a

.no_decrease:
    xor     a
    ld      [playerDecTick],a
    ret


player_wall_hit:; -> a = block destroy = 1, bounce = 0

    ; check player movement speed
    ld      a,[playerSpeedRight]
    ld      b,a
    ld      a,[playerSpeedLeft]
    or      b
    and     %00000010; check if speed is >= 2
    ret     z; do nothing in case it isnt

    ; check wall collision type normal / breaking
    ; TODO check all 3 collision points to be either none or breaking

    ; check for bouncing of walls during running
.bounce:
    ; TODO setup bounce
    xor      a
    ret

.break:
    ld       a,1; indicate that we do not want to be stopped by the wall
    ret

