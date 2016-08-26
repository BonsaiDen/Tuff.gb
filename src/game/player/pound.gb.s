; Player Pound Attack ---------------------------------------------------------
player_pound:

    ; check ability
    ld      a,[playerAbility]
    and     PLAYER_ABILITY_POUND
    ret     z

    ; check if already pounding
    ld      a,[playerIsPounding]
    cp      0
    jp      nz,_player_pound_init

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
    xor     a
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

    ; check if we can actually break blocks, if not skip centering
    ld      a,[playerAbility]
    and     PLAYER_ABILITY_BREAK
    ret     z

    ; reset x centering for block beneath
    xor     a
    ld      [playerPoundCenterX],a

    ; align ourselves with the 16x16 block directly below
    ld      a,[playerX]
    ld      b,a

    ; check difference of x block to current player xpos
    and     %11110000; modulo 16
    or      %00001000
    sub     b
    cp      128
    jr      c,.positive

    ; make positive
    ld      b,a
    ld      a,$ff
    sub     b
    inc     a

.positive:

    ; check if difference < 3, otherwise don't align
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
    cp      MAP_COLLISION_NONE; no collision, check next
    jr      z,.next
    cp      MAP_COLLISION_BREAKABLE ; found a block
    jr      z,.found

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
    jr      .loop_find

.found:
    ld      a,1
    ld      [playerPoundCenterX],a
    ret


    ; delay the start / stop animation

_player_pound_init:
    ; check if we're at the start and play the pounding up sound
    ld      a,[playerIsPounding]
    cp      1
    jr      nz,.skip_sound

    ; for the first 3 ticks play a sound each time
    ld      a,[playerPoundTick]
    ld      b,a
    ld      a,PLAYER_POUND_DELAY_START
    sub     b
    ld      b,a
    cp      0
    jr      z,.sound_low
    cp      12
    jr      z,.sound_med
    cp      24
    jr      z,.sound_high
    jr      .skip_sound

.sound_high:
    ld      a,SOUND_EFFECT_PLAYER_POUND_UP_HIGH
    jr      .sound_play

.sound_med:
    ld      a,SOUND_EFFECT_PLAYER_POUND_UP_MED
    jr      .sound_play

.sound_low:
    ld      a,SOUND_EFFECT_PLAYER_POUND_UP_LOW

.sound_play:
    call    sound_play_effect_one

.skip_sound:
    ld      a,[playerPoundTick]
    cp      0
    jr      z,_player_pound_update
    dec     a
    ld      [playerPoundTick],a

    ; disable gravity during delay
    xor     a
    ld      [playerFallSpeed],a
    ld      a,PLAYER_GRAVITY_INTERVAL
    ld      [playerGravityTick],a

    ; push away from ceiling
    call    player_collision_far_up
    jr      nc,.push_sides

    ld      a,[coreLoopCounter]
    and     %00000111
    cp      7
    jr      nz,.push_sides

    ld      a,[playerY]
    inc     a
    ld      [playerY],a

    ; push away from walls
.push_sides:
    call    player_collision_far_right
    jr      nc,.push_left

.push_right:
    ld      a,[coreLoopCounter]
    and     %00000111
    cp      7
    jr      nz,.push_left

    ld      a,[playerX]
    dec     a
    ld      [playerX],a

.push_left:
    call    player_collision_far_left
    jr      nc,.delay_done

    ld      a,[coreLoopCounter]
    and     %00000111
    cp      7
    jr      nz,.delay_done

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
    ret     z; centered
    jr      c,.left

.right:
    dec     a
    ld      [playerX],a
    ret

.left:
    inc     a
    ld      [playerX],a
    ret


_player_pound_update:

    ld      a,[playerIsPounding]
    cp      2
    jp      z,.end

    ; set fall speed
    ld      a,PLAYER_GRAVITY_MAX_POUND
    ld      [playerFallSpeed],a

    ; check if we hit water
    ld      a,[playerInWater]
    cp      1
    jr      z,.water

    ; check if we hit ground
    ld      a,[playerOnGround]
    cp      1
    ret     nz; return if not

    ; If we hit ground shake screen, delay and then disable pounding
    ld      a,10
    call    screen_shake

    ; play sound
    ld      a,SOUND_EFFECT_PLAYER_LAND_POUND
    call    sound_play_effect_one

    ; play animation
    ld      a,PLAYER_POUND_DELAY_END
    ld      [playerPoundTick],a

    ld      a,PLAYER_ANIMATION_POUND_END
    ld      [playerAnimation],a

    ; create dust gfx
    ld      c,0
    ld      b,2
    call    player_effect_dust

    ld      c,PLAYER_HALF_WIDTH + 1
    ld      b,2
    call    player_effect_dust

    ; no more falling
    xor     a
    ld      [playerFallSpeed],a

    ; switch to end mode
    ld      a,2
    ld      [playerIsPounding],a
    ret

.water:
    ld      a,[playerAbility]
    and     PLAYER_ABILITY_DIVE
    jr      nz,.can_dive

    ; reset water entry if we cannot swim
    xor     a
    ld      [playerFallSpeed],a

    ; if the player cant dive we exit early
    ld      a,[playerInWater]
    cp      1
    jr      z,.water_end
    jr      .water_slow

.can_dive:
    ld      a,[playerWaterTick]
    cp      25
    jr      nc,.water_end

    ; slow down after the first 5 frames
.water_slow:
    cp      5
    jr      c,.water_next
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
    jr      z,.under_water

    ld      a,PLAYER_WATER_OFFSET_MAX
    jr      .water_end_set

.under_water:
    ld      a,15
    jr      .water_end_set

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
    ld      a,SOUND_EFFECT_PLAYER_POUND_CANCEL
    call    sound_play_effect_one

    ; setup for water dissolve
    xor     a
    ld      [playerWaterHitDone],a
    ret

.end:

    ; unset pound
    xor     a
    ld      [playerIsPounding],a
    ld      [playerBreakBlockOffset],a

    ; reset gravity max
    ld      a,PLAYER_GRAVITY_MAX
    ld      [playerGravityMax],a
    ret



; Collision Detection with Breakable Blocks -----------------------------------
player_pounding_collision:

    ; check which 16x16 blocks we're hitting
    ld      a,$ff; reset
    ld      [playerBreakBlockM],a
    ld      [playerBreakBlockR],a
    ld      [playerBreakBlockL],a

    ; middle of player
    ld      a,[playerY]
    ld      c,a

    ld      a,[playerX]
    ld      b,a
    call    map_get_collision
    cp      MAP_COLLISION_BLOCK
    jp      z,.collision

    cp      MAP_COLLISION_BREAKABLE
    jr      nz,.check_right

    ; store M block x coordinate
    ld      a,[playerX]; divide x by 16
    swap    a
    and     $f
    ld      [playerBreakBlockM],a; store block a x

    ; right edge of player
.check_right:

    ; setup
    ld      a,[playerY]
    ld      c,a
    ld      a,[playerX]
    add     7
    ld      b,a
    call    map_get_collision
    cp      MAP_COLLISION_BLOCK
    jr      z,.collision

    ; if the block is not breakable, check the left side
    cp      MAP_COLLISION_BREAKABLE
    jr      nz,.check_left

    ; store R block x coordinate
    ld      a,[playerX]; divide x by 16
    add     7
    swap    a
    and     $f
    ld      [playerBreakBlockR],a

    ; left edge of player
.check_left:
    ld      a,[playerY]
    ld      c,a

    ld      a,[playerX]
    sub     8
    ld      b,a
    call    map_get_collision
    cp      MAP_COLLISION_BLOCK
    jr      z,.collision

    ; if the block is not breakable, check if we can break the right side
    cp      MAP_COLLISION_BREAKABLE
    jr      nz,.check_blocks

    ; check if we can actually break blocks
    ld      a,[playerAbility]
    and     PLAYER_ABILITY_BREAK
    jr      z,.collision

    ; store L block x coordinate
    ld      a,[playerX]; divide x by 16
    sub     8
    swap    a
    and     $f
    ld      [playerBreakBlockL],a

.check_blocks:

    ld      a,[playerY]; divide by 16
    swap    a
    and     $f
    ld      c,a

    ; check which 16x16 blocks need to be destroyed
    ld      a,[playerBreakBlockR]
    cp      255
    push    bc
    call    nz,break_vertical_blocks
    pop     bc

    ld      a,[playerBreakBlockM]
    cp      255
    push    bc
    call    nz,break_vertical_blocks
    pop     bc

    ld      a,[playerBreakBlockL]
    cp      255
    push    bc
    call    nz,break_vertical_blocks
    pop     bc

    and     a; fall through breakable blocks
    ret

.collision:
    scf      ; stop if we touch a normal collision block
    ret

