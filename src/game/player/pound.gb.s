; Player Pound Attack ---------------------------------------------------------
player_pound:

    ; check ability
    ld      a,[playerCanPound]
    cp      0
    ret     z

    ; check if already pounding
    ld      a,[playerIsPounding]
    cp      0
    jp      nz,.delay
    
    ; check if on ground
    ld      a,[playerOnGround]
    cp      1
    ret     z

    ; check for B button
    ld      a,[coreInputOn]
    and     BUTTON_B
    cp      BUTTON_B
    ret     nz

    ; check if under water or swimming
    ld      a,[playerUnderWater]
    cp      1
    ret     z

    ld      a,[playerInWater]
    cp      1
    ret     z

    ; set pounding and animation
    ld      a,1
    ld      [playerIsPounding],a

    ld      a,PLAYER_ANIMATION_POUND_START
    ld      [playerAnimation],a

    ld      a,PLAYER_POUND_DELAY_START
    ld      [playerPoundTick],a

    ; reset movement 
    ld      a,0
    ld      [playerSpeedRight],a
    ld      [playerSpeedLeft],a
    ld      [playerFallSpeed],a
    ld      [playerWaterTick],a
    ld      [playerJumpForce],a
    ld      [playerDirectionWall],a
    ld      [playerWallSlideTick],a

    ; reset gravity tick
    ld      a,PLAYER_GRAVITY_INTERVAL
    ld      [playerGravityTick],a

    ; set new gravity max
    ld      a,PLAYER_GRAVITY_MAX_POUND
    ld      [playerGravityMax],a

    ; reset x centering for block beneath
    ld      a,0
    ld      [playerPoundCenterX],a

    ; check if there's a breakable block below us to align with
    ld      a,[playerX]
    ld      b,a

    ; difference of x block to current player xpos
    and     %11110000; modulo 16
    or      %00001000 
    sub     b
    cp      128
    jp      c,.positive

    ; make positive
    ld      b,a
    ld      a,$ff
    sub     b
    inc     a

.positive:
    
    ; check if difference < 3, otherwise exit
    cp      PLAYER_POUND_ALIGN_BORDER
    ret     nc

    ; block y align
    ld      a,[playerY]
    and     %11111000; modulo 16
    ld      c,a

    ld      a,[playerX]
    ld      b,a

.loop_find:

    ; check current block
    push    bc
    call    map_get_collision
    pop     bc
    ld      a,[mapCollisionFlag]
    cp      MAP_COLLISION_NONE; no collision, check next
    jp      z,.next
    cp      MAP_COLLISION_BREAKABLE ; found a block
    jp      z,.found

    ; setup normal collision here to prevent hazard values leaking through
    ; and triggering instant death in mid air
    ld      a,MAP_COLLISION_BLOCK
    ld      [mapCollisionFlag],a
    ret;    something other block, exit
    
    ; go to next block
.next:
    ld      a,c
    add     16
    cp      144; if we leave screen space prevent dead lock
    ret     nc

    ld      c,a
    jp      .loop_find

.found:
    ld      a,1
    ld      [playerPoundCenterX],a
    ret     
    

    ; delay the start / stop animation
.delay:
    ; check if we're at the start and play the pounding up sound
    ld      a,[playerIsPounding]
    cp      1
    jp      nz,.skip_sound

    ; for the first 3 ticks play a sound each time
    ld      a,[playerPoundTick]
    ld      b,a
    ld      a,PLAYER_POUND_DELAY_START
    sub     b
    ld      b,a
    cp      0
    jp      z,.sound_low
    cp      12
    jp      z,.sound_med
    cp      24
    jp      z,.sound_high
    jp      .skip_sound

.sound_high:
    ld      a,SOUND_PLAYER_POUND_UP_HIGH
    jp      .sound_play

.sound_med:
    ld      a,SOUND_PLAYER_POUND_UP_MED
    jp      .sound_play

.sound_low:
    ld      a,SOUND_PLAYER_POUND_UP_LOW

.sound_play:
    call    sound_stop
    call    sound_play

.skip_sound:
    ld      a,[playerPoundTick]
    cp      0
    jp      z,.pounding
    dec     a
    ld      [playerPoundTick],a

    ; disable gravity during delay
    ld      a,0
    ld      [playerFallSpeed],a
    ld      a,PLAYER_GRAVITY_INTERVAL
    ld      [playerGravityTick],a

    ; push away from ceiling
    call    player_collision_far_up
    cp      1
    jp      nz,.push_sides

    ld      a,[coreLoopCounter]
    and     %00000111
    cp      7
    jp      nz,.push_sides

    ld      a,[playerY]
    inc     a
    ld      [playerY],a

    ; push away from walls
.push_sides:
    call    player_collision_far_right
    cp      1
    jp      nz,.push_left

.push_right:
    ld      a,[coreLoopCounter]
    and     %00000111
    cp      7
    jp      nz,.push_left

    ld      a,[playerX]
    dec     a
    ld      [playerX],a

.push_left:
    call    player_collision_far_left
    cp      1
    jp      nz,.delay_done

    ld      a,[coreLoopCounter]
    and     %00000111
    cp      7
    jp      nz,.delay_done

    ld      a,[playerX]
    inc     a
    ld      [playerX],a

.delay_done:

    ; check if we should center the player horizontally
    ld      a,[playerPoundCenterX]
    cp      0
    ret     z

    ; only move every 7th frame
    ld      a,[coreLoopCounter]
    and     %00000111
    cp      7
    ret     nz

    ; slowly move the player into position
    ld      a,[playerX]
    and     %11110000; modulo 16
    or      %00001000; horizontal center of block
    ld      b,a; save target x into b

    ; compare
    ld      a,[playerX]
    cp      b
    ret     z
    jp      c,.left
    jp      nc,.right

.left:
    inc     a
    ld      [playerX],a
    ret

.right:
    dec     a
    ld      [playerX],a
    ret


.pounding:
    
    ld      a,[playerIsPounding]
    cp      2
    jp      z,.end

    ; set fall speed
    ld      a,PLAYER_GRAVITY_MAX_POUND
    ld      [playerFallSpeed],a

    ; check if we hit water
    ld      a,[playerInWater]
    cp      1
    jp      z,.water

    ; check if we hit ground
    ld      a,[playerOnGround]
    cp      1
    ret     nz; return if not

    ; If we hit ground shake screen, delay and then disable pounding
    ld      a,10
    call    screen_shake

    ; play sound
    ld      a,SOUND_PLAYER_LAND_POUND
    call    sound_play

    ; play animation
    ld      a,PLAYER_POUND_DELAY_END
    ld      [playerPoundTick],a

    ld      a,PLAYER_ANIMATION_POUND_END
    ld      [playerAnimation],a

    ; no more falling
    ld      a,0
    ld      [playerFallSpeed],a

    ; switch to end mode
    ld      a,2
    ld      [playerIsPounding],a
    ret

.water:
    ld      a,[playerCanDive]
    cp      1
    jp      z,.can_dive

    ; if the player cant dive we exit early
    ld      a,[playerInWater]
    cp      1
    jp      z,.water_end ; TODO fix y offset
    jp      .water_slow

.can_dive:
    ld      a,[playerWaterTick]
    cp      25
    jp      nc,.water_end

    ; slow down after the first 5 frames
.water_slow:
    cp      5
    jp      c,.water_next
    ld      a,1
    ld      [playerFallSpeed],a

.water_next:
    ld      a,[playerWaterTick]
    inc     a
    ld      [playerWaterTick],a
    ret

.water_end:

    ; skip water offset 
    ld      a,[playerUnderWater]
    cp      1
    jp      z,.under_water

    ld      a,PLAYER_WATER_OFFSET_MAX
    jp      .water_end_set

.under_water:
    ld      a,15
    jp      .water_end_set

.water_end_set:
    ld      [playerWaterTick],a

    ; switch to end mode
    ld      a,2
    ld      [playerIsPounding],a

    ld      a,PLAYER_POUND_DELAY_END
    ld      [playerPoundTick],a

    ld      a,PLAYER_ANIMATION_POUND_END
    ld      [playerAnimation],a

    ; play sound
    ld      a,SOUND_PLAYER_POUND_CANCEL
    call    sound_play

    ret

.end:
    
    ; unset pound
    ld      a,0
    ld      [playerIsPounding],a
    ld      [playerPoundYBlock],a

    ; reset gravity max
    ld      a,PLAYER_GRAVITY_MAX
    ld      [playerGravityMax],a
    ret



; Collision Detection with Breakable Blocks -----------------------------------
player_pounding_collision:

    ; check which 16x16 blocks we're hitting
    ld      a,255; reset
    ld      [playerPoundBlockM],a
    ld      [playerPoundBlockR],a
    ld      [playerPoundBlockL],a
    
    ; middle of player
    ld      a,[playerY]
    ld      c,a

    ld      a,[playerX]
    ld      b,a
    call    map_get_collision
    ld      a,[mapCollisionFlag]
    cp      MAP_COLLISION_BLOCK
    jp      z,.collision

    cp      MAP_COLLISION_BREAKABLE
    jr      nz,.check_right

    ; store M block x coordinate
    ld      a,[playerX]; divide x by 16
    srl     a
    srl     a
    srl     a
    srl     a
    ld      [playerPoundBlockM],a; store block a x

    ; right edge of player
.check_right:
    ld      a,[playerY]
    ld      c,a

    ld      a,[playerX]
    add     7
    ld      b,a
    call    map_get_collision
    ld      a,[mapCollisionFlag]
    cp      MAP_COLLISION_BLOCK
    jr      z,.collision

    cp      MAP_COLLISION_BREAKABLE
    jr      nz,.check_left

    ; store R block x coordinate
    ld      a,[playerX]; divide x by 16
    add     7
    srl     a
    srl     a
    srl     a
    srl     a
    ld      [playerPoundBlockR],a

    ; left edge of player
.check_left:
    ld      a,[playerY]
    ld      c,a

    ld      a,[playerX]
    sub     8
    ld      b,a
    call    map_get_collision
    ld      a,[mapCollisionFlag]

    cp      1
    jr      z,.collision

    cp      5
    jr      nz,.check_blocks

    ; store L block x coordinate
    ld      a,[playerX]; divide x by 16
    sub     8
    srl     a
    srl     a
    srl     a
    srl     a
    ld      [playerPoundBlockL],a

.check_blocks:

    ld      a,[playerY]; divide by 16
    ld      c,a
    srl     c
    srl     c
    srl     c
    srl     c

    ; check which 16x16 blocks need to be destroyed
    ld      a,[playerPoundBlockR]
    cp      255
    push    bc
    call    nz,player_destroy_breakable_block
    pop     bc

    ld      a,[playerPoundBlockM]
    cp      255
    push    bc
    call    nz,player_destroy_breakable_block
    pop     bc

    ld      a,[playerPoundBlockL]
    cp      255
    push    bc
    call    nz,player_destroy_breakable_block
    pop     bc

    ld      a,0; fall through breakable blocks
    ret

.collision:
    ld      a,1; stop if we touch a normal collision block
    ret


player_destroy_breakable_block:; a = block x, c = block y

    ld      b,a; move x tile into b

    ; divide by 8 and modulo 2 to figure out the top / bottom block
    ld      a,[playerY]
    srl     a
    srl     a
    srl     a
    and     %00000001

    cp      0
    jr      z,.top

    cp      1
    jr      z,.bottom
    ret

.top:

    ; check if block can be broken
    call    map_check_breakable_block_top
    cp      0
    ret     z

    ; check if we need to set up the initial delay
    ld      a,[playerBreakDelayed]
    cp      1
    jr      nz,.delay

    ; wait for delay to be over
    ld      a,[playerGravityDelay]
    cp      0
    ret     nz

    ; reset delay
    ld      a,0
    ld      [playerBreakDelayed],a

    ; break block
    call    map_destroy_breakable_block_top

    ld      a,SOUND_PLAYER_POUND_BREAK
    call    sound_play

    ret
    
.bottom:
    ; check if block can be broken
    call    map_check_breakable_block_bottom
    cp      0
    ret     z

    ; check if we need to set up the initial delay
    ld      a,[playerBreakDelayed]
    cp      1
    jr      nz,.delay

    ; wait for delay to be over
    ld      a,[playerGravityDelay]
    cp      0
    ret     nz

    ; reset delay
    ld      a,0
    ld      [playerBreakDelayed],a

    ; break block
    call    map_destroy_breakable_block_bottom

    ld      a,SOUND_PLAYER_POUND_BREAK
    call    sound_play

    ret

.delay:

    ld      a,3
    call    screen_shake

    ; sound
    ld      a,SOUND_PLAYER_POUND_BREAK
    call    sound_play

    ; align player y to 
    ld      a,[playerY]
    and     %11111000
    ld      [playerY],a

    ld      a,1
    ld      [playerBreakDelayed],a

    ; check if we already added delay for this block row
    ; this is done so that when breaking two blocks at the time we only get
    ; 1 delay
    ld      a,[playerY];
    ld      c,a
    ld      a,[playerPoundYBlock]
    cp      c
    ret     z; if so exit

    ; otherwise set the block row to the current one
    ld      a,c
    ld      [playerPoundYBlock],a

    ld      a,4
    ld      [playerGravityDelay],a

    ret

