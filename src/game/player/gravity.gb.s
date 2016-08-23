; Gravity ---------------------------------------------------------------------
player_gravity:

    ld      a,[playerGravityDelay]
    cp      0
    jr      nz,.delayed

    ; check for delay after landing
    ld      a,[playerLandingFrames]
    cp      0
    ret     nz

    ; only increase / decrease gravity every PLAYER_GRAVITY_INTERVAL ticks
    ld      a,[playerGravityTick]
    dec     a
    ld      [playerGravityTick],a

    ; check if the ticker reached 0
    cp      0
    jr      nz,.no_tick

    ; update gravity
    call    player_decrease_jump
    call    player_increase_fall

    ; reset ticker
    ld      a,PLAYER_GRAVITY_INTERVAL
    ld      [playerGravityTick],a

.no_tick:

    ; if under water half movement speed by 2
    ld      a,[playerWasUnderWater]
    cp      0
    jr      z,.move

    ld      a,[playerGravityTick]
    and     %00000001
    jr      nz,.delay_move

.move:
    call    player_fall
    call    player_jump

.delay_move:

    ; if jump force > 0 set jump animation
    ld      a,[playerJumpForce]
    cp      0
    jr      z,.no_jump

    ; set jump animation
    ld      a,[playerDoubleJumped]
    cp      1
    jr      z,.double_jump

    ld      a,PLAYER_ANIMATION_JUMP
    ld      [playerAnimation],a
    ret

.double_jump:
    ld      a,PLAYER_ANIMATION_DOUBLE_JUMP
    ld      [playerAnimation],a
    ret

.no_jump:

    ; if fall speed > 0 set fall animation
    ld     a,[playerFallSpeed]
    cp     0
    ret    z

    ; set fall animation
    ld      a,[playerIsPounding]
    cp      0
    ret     nz

    ; skip the animation when under water
    ; otherwise pressing against a ceiling will result in flicker
    ld      a,[playerUnderWater]
    cp      1
    ret     z

    ld      a,PLAYER_ANIMATION_FALL
    ld      [playerAnimation],a
    ret

.delayed:
    dec     a
    ld      [playerGravityDelay],a
    ret


; JUMPING ----------------------------------------------------------- JUMPING -
player_jump:

    ; check ability
    ld      a,[playerCanJump]
    cp      0
    ret     z

    ; check for landing frames
    ld      a,[playerLandingFrames]
    cp      0
    ret     nz

    ; Prevent very high jumps during pound end animation
    ld      a,[playerIsPounding]
    cp      0
    ret     nz

    ; Check for wall bounce
    ld      a,[playerBounceFrames]
    cp      0
    jp      nz,.jump

    ; see if the jump button has been pressed
    ld      a,[coreInput]
    and     BUTTON_A
    cp      BUTTON_A
    jp      nz,.not_pressed

    ; check if the player is continuosly pressing the button
    ld      a,[playerJumpPressed]
    cp      1
    jp      z,.still_pressed

    ; otherwise set the button pressed on first press
    ld      a,1
    ld      [playerJumpPressed],a

    ; no sound when not on ground
    ld      a,[playerOnGround]
    cp      0
    jr      z,.check_swimming

    ; no sound under water (even when on ground)
    ld      a,[playerUnderWater]
    cp      1
    jr      z,.no_sound

    ; when on ground play normal jump
    ld      a,SOUND_EFFECT_PLAYER_JUMP
    call    sound_play_effect_one

.check_swimming:

    ; check if swimming
    ld      a,[playerWaterHitDone]
    cp      1
    jr      nz,.no_sound

    ld      a,[playerInWater]
    cp      0
    jr      z,.no_sound

    ld      a,[playerUnderWater]
    cp      1
    jr      z,.no_sound

    ; player normal jump sound plus water leave sound
    ld      a,SOUND_EFFECT_PLAYER_JUMP
    call    sound_play_effect_one

    ld      a,SOUND_EFFECT_PLAYER_WATER_ENTER
    call    sound_play_effect_two

    ; under water movement
.no_sound:
    ld      a,[playerUnderWater]
    cp      1
    jr      z,.jump_swim

    ; check if we're in water (and the splash offset is done)
    ld      a,[playerWaterHitDone]
    cp      1
    jr      z,.jump_water

    ; and check if we're on the ground
    ld      a,[playerOnGround]
    cp      1
    jr      nz,.check_double; if not check for double jump

    ; set normal double jump threshold
    ld      a,PLAYER_DOUBLE_JUMP_THRESHOLD
    ld      [playerDoubleJumpThreshold],a

    ; land jump force
    ld      a,PLAYER_JUMP_FORCE
    ld      [playerJumpForce],a
    ld      a,PLAYER_GRAVITY_INTERVAL
    jr      .init_jump

    ; water jump force
.jump_water:

    ; gfx
    ld      b,8
    call    player_effect_dust_small
    ld      a,PLAYER_JUMP_FORCE
    ld      [playerJumpForce],a

    ; setup reduce water double jump threshold
    ld      a,PLAYER_DOUBLE_JUMP_WATER_THRESHOLD
    ld      [playerDoubleJumpThreshold],a

    ; unset under water flag when jumping out of water
    xor     a
    ld      [playerWasUnderWater],a
    ld      a,6 ; setup gravity tick delay so we do not jump as high as normally
    jr      .init_jump

.jump_swim:
    ld      a,PLAYER_JUMP_SWIM
    ld      [playerJumpForce],a
    ld      a,2 ; setup gravity tick delay

    ; if we are, set the initial jump force and reset the gravity ticker
.init_jump:
    ld      [playerGravityTick],a
    xor     a
    ld      [playerJumpFrames],a
    jr      .jump

    ; reset the jump state
.not_pressed:
    xor     a
    ld      [playerJumpPressed],a
    ld      [playerJumpHold],a
    ld      [playerWallJumpPressed],a
    jr      .jump

.check_double:

    ; don't allow any sort of double jump during wall sliding / jumping
    ld      a,[playerDirectionWall]
    cp      0
    jr      nz,.jump

    ld      a,[playerWallSlideDir]
    cp      0
    jr      nz,.jump

    ld      a,[playerWallJumpTick]
    cp      0
    jr      nz,.jump

    ; check if we really hit the button on this frame
    ld      a,[coreInputOn]
    and     BUTTON_A
    cp      BUTTON_A
    jr      nz,.jump

    ; check if we already double jumped
    ld      a,[playerDoubleJumped]
    cp      1
    jr      z,.jump

    ; prevent jumping while in contact with the ceiling
    call    player_collision_up
    jr      c,.jump

    ; check if above threshold for double jump
    ld      a,[playerDoubleJumpThreshold]
    ld      b,a
    ld      a,[playerJumpFrames]
    cp      b; PLAYER_DOUBLE_JUMP_THRESHOLD
    jr      c,.jump; if playerJumpFrames - threshold < 0 don't jump

    ; set double jump flag
    ld      a,1
    ld      [playerDoubleJumped],a

    ; set up double jump
    ld      a,SOUND_EFFECT_PLAYER_JUMP_DOUBLE
    call    sound_play_effect_one

    ; cloud gfx
    ld      a,[playerY]
    add     PLAYER_HEIGHT / 2
    ld      b,a
    ld      a,[playerX]
    add     4
    ld      c,a
    ld      a,EFFECT_PUFF_CLOUD
    call    effect_create

    xor     a
    ld      [playerFallSpeed],a
    ld      [playerFallFrames],a

    ld      a,PLAYER_JUMP_FORCE
    ld      [playerJumpForce],a
    ld      a,PLAYER_GRAVITY_INTERVAL
    jr      .init_jump

    ; if we're still pressing the button or are in the air update the jump value
.still_pressed:
    ld      a,[playerJumpHold]
    inc     a
    cp      $ff; limit to 255
    jr      z,.jump
    ld      [playerJumpHold],a

.jump:

    ; check if we need to move upwards
    ld      a,[playerJumpForce]
    ld      d,a
    cp      0
    ret     z ; we're not moving any longer

    ; check if we're the button was released
    ld      a,[playerJumpPressed]
    cp      0
    jr      nz,.apply_force ; if not continue applying jump force
    ret     z ; otherwise end here

    ; move player upwards
.apply_force:

    ; reset on ground flag
    xor     a
    ld      [playerOnGround],a

    ; move player upwards
    ld      a,[playerY]

    ; check collision at current top pixel
    call    player_collision_up
    jr      c,.collision

    ld      a,[playerY]
    dec     a

    ; check again with new top pixel
    call    player_collision_up
    jr      c,.collision

    ; finally set new top pixel
    ld      a,[playerY]
    dec     a
    ld      [playerY],a

    ; increase jump frames
    ld      a,[playerJumpFrames]
    inc     a
    ld      [playerJumpFrames],a

    ; loop until stored jump force reaches 0
    dec     d
    jr      nz,.apply_force
    ret

.collision:
    xor     a
    ld      [playerJumpPressed],a

    ld      a,[playerJumpForce]
    srl     a
    srl     a
    ld      [playerJumpForce],a
    ret


player_decrease_jump:

    ; check if under water
    ld      a,[playerUnderWater]
    cp      1
    ret     z

    ; check whether the jump button is still pressed;
    ; if not we decrease the jump force more quickly
    ld      a,[playerJumpPressed]
    cp      0
    jr      nz,.fast ; fast decrease in case the jump button was released

    ; load current jump force
    ld      a,[playerJumpForce]
    cp      0
    ret     z ; do nothing in case jump is already 0

    ; normal decrease -1
    ld      a,[playerJumpForce]
    dec     a
    ld      [playerJumpForce],a

    ; fast decrease /= 2
.fast:
    ld      a,[playerJumpForce]
    srl     a
    ld      [playerJumpForce],a
    ret


; FALLING ----------------------------------------------------------- FALLING -
player_fall:

    ; check if we're falling at all
    ld      a,[playerFallSpeed]
    ld      d,a ; load the current fall speed as the loop counter
    cp      0
    ret     z

    ; if we're sliding only fall every couple of ticks
    ld      a,[playerWallSlideTick]
    and     PLAYER_SLIDE_SLOWDOWN
    cp      0
    ret     nz

.fall:

    ; check for downward collision
    call    player_collision_down
    jr      c,.collision; unlikely jump, thus jr and not jp

    ; check for platform collision
    ld      a,[playerPlatformDirection]
    cp      $ff
    jr      nz,.collision

    ; reset ground state
    xor     a
    ld      [playerOnGround],a

    ; increase player position
    ld      a,[playerY]
    inc     a
    ld      [playerY],a

    ; loop until stored fall speed reaches 0
    dec     d
    jr      nz,.fall
    jr      .no_collision

.collision:

    ; reset player state to ground after collision
    xor     a
    ld      [playerFallSpeed],a

    ; already on ground
    ld      a,[playerOnGround]
    cp      1
    ret     z

    ; don't allow landing while underwater
    ld      a,[playerInWater]
    cp      1
    ret     z

    ; set ground flag
    ld      a,1
    ld      [playerOnGround],a

    ; reset double jump flag
    xor     a
    ld      [playerDoubleJumped],a

    ; check how long we've been falling
    ld      a,[playerFallFrames]
    cp      14
    jr      c,.soft
    cp      50
    jr      c,.normal

    ; if we'be been falling for more than 30 frames play a landing animation
    ; and delay further movement
    ld      a,16
    ld      [playerLandingFrames],a

    ; skip landing animation if pounding
    ld      a,[playerIsPounding]
    cp      0
    jr      nz,.done

    ld      a,SOUND_EFFECT_PLAYER_LAND_HARD
    call    sound_play_effect_two

    ; Dust Effect
    ld      b,0
    call    player_effect_dust_small

    ; play landing animation
    ld      a,PLAYER_ANIMATION_LANDING
    ld      [playerAnimation],a

    jr      .done

.normal:
    ld      a,SOUND_EFFECT_PLAYER_LAND
    call    sound_play_effect_two
    jr      .done

.soft:
    ld      a,SOUND_EFFECT_PLAYER_LAND_SOFT
    call    sound_play_effect_two
    jr      .done

.done:
    xor     a
    ld      [playerFallFrames],a
    ld      [playerJumpFrames],a
    ret

.no_collision:

    ; decrease the numbers of jump frames
    ld      a,[playerJumpFrames]
    cp      0
    jr      z,.dec_fall
    dec     a
    ld      [playerJumpFrames],a

    ; increase the number of frames we were falling
.dec_fall:
    ld      a,[playerFallFrames]
    cp      $ff
    ret     z ; fall frames max out at 255

    ; increase if not yet at 255
    inc     a
    ld      [playerFallFrames],a
    ret


player_increase_fall:

    ; if we're still jumping do not increase the fall speed
    ld      a,[playerJumpForce]
    cp      0
    ret     nz; do not incrase

    ; if we're in water do not increase the fall speed
    ld      a,[playerInWater]
    cp      0
    ret     nz

    ; otherwise increase it until we reach the maximum
    ld      a,[playerGravityMax]
    ld      b,a
    ld      a,[playerFallSpeed]
    cp      b
    ret     z

    inc     a
    ld      [playerFallSpeed],a
    ret

