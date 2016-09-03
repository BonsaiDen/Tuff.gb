; Horizontal Player Movement --------------------------------------------------
player_move:

    ; check for block breaking delay
    ld      a,[playerMovementDelay]
    cp      0
    jp      nz,.breaking_delayed

    ; check for landing frames
    ld      a,[playerLandingFrames]
    cp      0
    jp      nz,.landing

    ; moving on a platform?
    ld      a,[playerPlatformDirection]
    cp      $ff
    jr      z,.not_on_platform

    ; check if still touching ground and ignore platform movement
    call    player_collision_down
    jr      c,.not_on_platform

    ; check platform speed
    ld      a,[playerPlatformSpeed]
    cp      0
    jr      z,.not_on_platform

    ; store platform speed
    ld      e,a

    ; convert platform direction into player direction
    ld      a,[playerPlatformDirection]
    bit     1,a; check for vertical platforms
    ret     nz
    inc     a; platform 0/1 -> player 1/2
    ld      d,a
    call    _player_move
    ret

    ; are we moving at all?
.not_on_platform:
    ld      a,[playerSpeedLeft]
    ld      b,a
    ld      a,[playerSpeedRight]
    add     a,b
    jp      z,.stopped

    ; set walking animation only when on ground
    ld      a,[playerOnGround]
    cp      0
    jr      z,.not_on_ground

    ; check if we're running at full speed
    ld      a,[playerIsRunning]
    cp      1
    jr      z,.running_half
    cp      2
    jr      z,.running_full

.not_running:
    ld      a,PLAYER_ANIMATION_WALKING
    jr      .running_animation

.running_half:
    ld      a,PLAYER_ANIMATION_RUNNING_HALF
    jr      .running_animation

.running_full:

    ; speed dash trail effect
    ld      a,[coreLoopCounter]
    and     %0000_0010
    cp      %0000_0010
    jr      nz,.no_dash

    ; ypos
    ld      a,[playerY]
    ld      b,a

    ld      a,[playerDirection]
    cp      PLAYER_DIRECTION_RIGHT
    jr      nz,.dash_right

    ; xpos
    ld      a,[playerX]
    add     6
    ld      c,a
    ld      a,EFFECT_RUN_DASH_RIGHT
    jr      .dash_effect

.dash_right:
    ld      a,[playerX]
    add     4
    ld      c,a
    ld      a,EFFECT_RUN_DASH_LEFT

.dash_effect:
    call    effect_create

.no_dash:
    ld      a,PLAYER_ANIMATION_RUNNING_FULL

.running_animation:
    ld      [playerAnimation],a

.not_on_ground:

    ; reset wall direction flag
    ld      a,[playerInWater]
    cp      0
    jr      z,.move_right

    ; half speed when in water
    ld      a,[playerMoveTick]
    cp      0
    jp      z,.delay_movement
    xor     a
    ld      [playerMoveTick],a

    ; move right -----------------------------------
.move_right:
    ld      a,[playerSpeedRight]
    cp      0
    jr      z,.move_left

    ; store speed
    ld      e,a

.move_right_inner:
    ld      d,PLAYER_DIRECTION_RIGHT
    call    _player_move

    ; move left ------------------------------------
.move_left:
    ld      a,[playerSpeedLeft]
    cp      0
    ret     z

    ; store speed
    ld      e,a

.move_left_inner:
    ld      d,PLAYER_DIRECTION_LEFT
    call    _player_move
    ret

.stopped:

    ; reset wall flag when no direction is pressed
    ld      a,[coreInput]
    and     BUTTON_RIGHT | BUTTON_LEFT
    jr      nz,.idle_ground
    xor     a
    ld      [playerDirectionWall],a

    ; reset to idle animation if on ground and stopped
.idle_ground:

    ; check if player is on ground
    ld      a,[playerOnGround]
    cp      0
    jr      z,.idle_water

    ; if so set idle animation
    jr      .idle

.idle_water:

    ; don't override swim animation under water
    ld      a,[playerInWater]
    cp      0
    ret     z

    ; set idle animation when swimming
    jr      .idle

.delay_movement:
    inc     a
    ld      [playerMoveTick],a
    ret

.landing:
    dec     a
    ld      [playerLandingFrames],a
    cp      0
    ret     nz

.idle:
    ld      a,PLAYER_ANIMATION_IDLE
    ld      [playerAnimation],a
    ret

.breaking_delayed:
    dec     a
    ld      [playerMovementDelay],a
    ret


; Moving ----------------------------------------------------------------------
_player_move: ; e = movement speed, d = movement direction

.loop:

    ; check for collision
    ld      a,d
    cp      PLAYER_DIRECTION_RIGHT
    jr      z,.move_right

    ; left
    call    player_collision_left
    jr      nc,.not_blocked
    jr      .maybe_blocked

    ; right
.move_right:
    call    player_collision_right
    jr      nc,.not_blocked

    ; if blocked, check for actual wall hit (we might have broken through a block)
.maybe_blocked:
    call    _player_wall_hit
    jr      c,.not_blocked; we broke a block continue moving

    ; set wall drection flag
    ld      a,d
    ld      [playerDirectionWall],a

    ; set pushing animation when not in water
    ld      a,[playerInWater]
    cp      0
    jr      z,.push_wall
    jr      .stopped

.push_wall:

    ; only allow pushing when actually on the ground
    ld      a,[playerOnGround]
    cp      0
    jr      z,.stopped

    ; check for full vertical collision with the walL
    ld      a,d
    cp      PLAYER_DIRECTION_RIGHT
    jr      z,.push_wall_right

    ; pushing left
    call    player_collision_left_all
    jr      nc,.stopped
    jr      .push_wall_animation

    ; pushing right
.push_wall_right:
    call    player_collision_right_all
    jr      nc,.stopped

    ; set pushing animation
.push_wall_animation:

    ; check if player is moving on platform and don't set animation
    ld      a,[playerPlatformSpeed]
    cp      0
    jr      nz,.stopped

    ld      a,PLAYER_ANIMATION_PUSHING
    ld      [playerAnimation],a
    ret

.stopped:
    ld      a,PLAYER_ANIMATION_IDLE
    ld      [playerAnimation],a
    ret

.not_blocked:

    ; set in-water animation if required
    ld      a,[playerInWater]
    cp      0
    jr      z,.move_apply

    ld      a,PLAYER_ANIMATION_SWIMMING
    ld      [playerAnimation],a

.move_apply:
    ld      hl,playerX

    ld      a,d
    cp      PLAYER_DIRECTION_RIGHT
    jr      z,.move_add

    ; move left
    dec     [hl]
    jr      .next

    ; move right
.move_add:
    inc     [hl]

.next:
    dec     e
    jr      nz,.loop
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

    ; don't accelerate during bouncing
    ld      a,[playerBounceFrames]
    cp      0
    jp      nz,.bounce

    ; if both directions are pressed at the same time ignore input
    ld      a,[coreInput]
    and     BUTTON_LEFT | BUTTON_RIGHT
    cp      BUTTON_LEFT | BUTTON_RIGHT
    ret     z

    ; check if we can run
    ld      a,[playerAbility]
    and     PLAYER_ABILITY_RUN
    jr      z,.is_not_running

    ; check for B button and running
    ld      a,[playerOnGround]; needs to be on ground
    cp      0
    jr      z,.is_not_running

    ld      a,[playerInWater]; not in water
    cp      0
    jr      nz,.is_not_running

    ld      a,[coreInput]; and hold the B button
    and     BUTTON_B
    jr      z,.is_not_running

    ld      a,[coreInput]; and either direction is still pressed
    and     BUTTON_RIGHT | BUTTON_LEFT
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
    jr      z,.check_direction; if both are false keep running

    ; if either is true reset running mode
.stop_running:
    xor     a
    ld      [playerIsRunning],a

    ; check which direction is pressed
.check_direction:
    ld      a,[coreInput]
    and     BUTTON_LEFT
    jr      nz,.acc_left

    ld      a,[coreInput]
    and     BUTTON_RIGHT
    jr      nz,.acc_right

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
    ; ignore platform movement when controlling directly
    xor     a
    ld      [playerPlatformSpeed],a

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

.bounce:
    dec     a
    ld      [playerBounceFrames],a
    ret     nz


player_decelerate:

    ; check for break continuation and skip decrease
    ld      a,[playerBreakContinue]
    cp      0
    jr      nz,.break_continue

    ; check for bounce frames and skip decrease
    ld      a,[playerBounceFrames]
    cp      PLAYER_BOUNCE_FRAMES - PLAYER_DECELERATE_FRAMES
    ret     nc

    ; Never decrease speed while running, otherwise there will be one frame
    ; every 10 frames where we'll bounce of during wall hits even though we
    ; should break them
    ld      a,[playerIsRunning]
    cp      0
    ret     nz

    ; only decelerate on every 10th frame
    ; this introduces "lag" or a sliding when turning rapidly
    ld      a,[playerDecTick]
    inc     a
    cp      10
    jr      z,.decrease

    ; if not on 10th frame store frame count and return
    ld      [playerDecTick],a
    ret

.decrease:
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

.break_continue:
    dec     a
    ld      [playerBreakContinue],a

    ; keep full running speed
    ld      a,2
    ld      [playerIsRunning],a

    ret


player_is_running:; -> a = 0 = is running
    ld      a,[playerSpeedRight]
    ld      b,a
    ld      a,[playerSpeedLeft]
    or      b
    ld      c,a
    and     %00000010; check if speed is >= 2
    cp      %00000010
    ret

_player_wall_hit:; d = direction -> carry set = no wall / block destroy, no carry = bounce

    ; Do not bounce from forced wall jump movement
    ld      a,[playerWallJumpTick]
    cp      0
    jr      nz,.done; normal collision

    ; cancel any existing previous bounce
    ld      a,[playerBounceFrames]
    cp      0
    jr      nz,.cancel_bounce; normal collision

    ; check player movement speed
    call    player_is_running
    jr      nz,.done; normal collision

    ; check if we can actually break blocks, if now we'll bounc off the wall
    ld      a,[playerAbility]
    and     PLAYER_ABILITY_BREAK
    jr      z,.bounce

    ; check player speed, if we're not fast enough we'll bounce off the wall
    ld      a,c
    and     %00000011
    cp      %00000011
    jr      nz,.bounce

    ; only if at full speed
    call    _player_running_collision
    jr      nc,.bounce; non-breakable wall in our way
    scf; indicate that we should break through the wall
    ret

.cancel_bounce:
    ld      a,$01
    ld      [playerGravityTick],a
    xor     a
    ld      [playerBounceFrames],a
    ld      [playerSpeedLeft],a
    ld      [playerSpeedRight],a
    ret

.done:
    xor     a
    ld      [playerRunningTick],a
    ret

.bounce:

    ; reset running tick
    xor     a
    ld      [playerRunningTick],a

    ld      a,[playerSpeedRight]
    cp      PLAYER_SPEED_FULL
    jr      z,.bounce_big

    ld      a,[playerSpeedLeft]
    cp      PLAYER_SPEED_FULL
    jr      z,.bounce_big

.bounce_small:
    ld      a,PLAYER_BOUNCE_FRAMES - 10
    ld      [playerBounceFrames],a
    ld      a,PLAYER_JUMP_FORCE * 1
    ld      [playerJumpForce],a
    ld      a,$06
    jr      .bounce_setup

.bounce_big:
    ld      a,PLAYER_BOUNCE_FRAMES - 10
    ld      [playerBounceFrames],a
    ld      a,PLAYER_JUMP_FORCE * 3 / 2
    ld      [playerJumpForce],a
    ld      a,$09

.bounce_setup:
    call    screen_shake
    ld      a,SOUND_EFFECT_PLAYER_BOUNCE_WALL
    call    sound_play_effect_one
    xor     a
    ld      [playerJumpFrames],a
    inc     a
    ld      [playerJumpPressed],a
    ld      [playerGravityTick],a

    ; check wall collision direction
    ld      a,d
    cp      PLAYER_DIRECTION_RIGHT
    jr      z,.bounce_right

.bounce_left:

    ; gfx
    ld      c,2
    ld      b,0
    call    player_effect_dust

    ; setup speed
    ld      a,[playerSpeedLeft]
    ld      [playerSpeedRight],a
    xor     a
    ld      [playerSpeedLeft],a
    ret

.bounce_right:

    ; gfx
    ld      c,6
    ld      b,0
    call    player_effect_dust

    ; setup speed
    ld      a,[playerSpeedRight]
    ld      [playerSpeedLeft],a
    xor     a
    ld      [playerSpeedRight],a
    ret


; Running Collision Detection with Breakable Blocks ---------------------------
_player_running_collision:; d = direction -> carry set = break block, no carry = collide with wall

    ; setup X offset value
    ld      a,d
    cp      PLAYER_DIRECTION_RIGHT
    jr      z,.right

.left:
    ld      h,-PLAYER_HALF_WIDTH
    jr      .detect

.right:
    ld      h,PLAYER_HALF_WIDTH

.detect:

    ; check which 16x16 blocks we're hitting
    ld      a,255; reset
    ld      [playerBreakBlockM],a; middle
    ld      [playerBreakBlockR],a; bottom
    ld      [playerBreakBlockL],a; top

    ; middle of player
    ld      a,[playerY]
    sub     7
    ld      c,a

    ld      a,[playerX]
    add     h
    ld      b,a
    call    map_get_collision
    cp      MAP_COLLISION_BLOCK
    jp      z,.collision

    cp      MAP_COLLISION_BREAKABLE
    jr      nz,.check_bottom

    ; store middle block y coordinate
    ld      a,[playerY]; divide y by 16
    sub     7
    swap    a
    and     $f
    ld      [playerBreakBlockM],a; store block a x

    ; bottom edge of player
.check_bottom:
    ld      a,[playerY]
    sub     1
    ld      c,a

    ld      a,[playerX]
    add     h
    ld      b,a
    call    map_get_collision
    cp      MAP_COLLISION_BLOCK
    jr      z,.collision

    cp      MAP_COLLISION_BREAKABLE
    jr      nz,.check_top

    ; store Bottom block y coordinate
    ld      a,[playerY]; divide y by 16
    sub     1
    swap    a
    and     $f
    ld      [playerBreakBlockR],a

    ; top edge of player
.check_top:
    ld      a,[playerY]
    sub     PLAYER_HEIGHT - 1
    ld      c,a

    ld      a,[playerX]
    add     h
    ld      b,a
    call    map_get_collision
    cp      MAP_COLLISION_BLOCK
    jr      z,.collision

    cp      MAP_COLLISION_BREAKABLE
    jr      nz,.check_blocks

    ; store Top block y coordinate
    ld      a,[playerY]; divide y by 16
    sub     PLAYER_HEIGHT - 1
    swap    a
    and     $f
    ld      [playerBreakBlockL],a

.check_blocks:

    ; setup x block based on current player direction
    ld      a,[playerX]; divide by 16 to get X tile
    add     h
    swap    a
    and     $f
    ld      b,a

    ; check which 16x16 blocks need to be destroyed
    ld      a,[playerBreakBlockR]
    cp      $ff
    push    bc
    call    nz,break_horizontal_blocks
    pop     bc

    ld      a,[playerBreakBlockM]
    cp      $ff
    push    bc
    call    nz,break_horizontal_blocks
    pop     bc

    ld      a,[playerBreakBlockL]
    cp      $ff
    push    bc
    call    nz,break_horizontal_blocks
    pop     bc

    scf
    ret

.collision:
    and     a; bounce of
    ret

