; Player Water Movement (Swimming and Diving) ---------------------------------
playerWaterSwimOffsetTable:
    DB      1,1,2,2,1,1,0,0,1,1,2,2,1,1,0,0

playerWaterHitOffsetTable:
    DB      1,2,3,4,6,7,8,9,10,8,7,7,6,6,6,5,5,5,5,4
    DB      4,4,4,3,3,3,3,3,2,2,2,2,2,1,1,1


player_water_update:

    ; check for the intitial frame on which we hit the water
    ld      a,[playerInWater]
    cp      0
    jr      nz,.not_initial

    ; reset bounce frames
    xor     a
    ld      [playerBounceFrames],a

    ; correct player y for water line
    ld      a,[playerY]
    and     %1111_0000
    or      $0E
    ld      [playerY],a

    ; save speed
    ld      a,[playerFallFrames]
    ld      [playerWaterHitDepth],a


    ; reset fall frames
    xor     a
    ld      [playerFallFrames],a

    ; set water flag
    inc     a
    ld      [playerInWater],a

    ; play sound
    ld      a,[playerWasUnderWater]
    cp      0
    jr      nz,.sound_surface

    ; water in gfx
    ld      d,EFFECT_WATER_IN_OFFSET
    call    player_effect_water_splash

    ld      a,SOUND_EFFECT_PLAYER_WATER_ENTER
    jr      .sound

.sound_surface:
    ; water out gfx
    ld      d,EFFECT_WATER_OUT_OFFSET
    call    player_effect_water_splash

    ld      a,SOUND_EFFECT_PLAYER_WATER_LEAVE

.sound:
    ; water in / out sfx
    call    sound_play_effect_two

    ; check if we were previously under water, if so skip water offset
    ld      a,[playerWasUnderWater]
    cp      0
    jr      z,.not_initial

    ; if we are surfacing skip the offset, and correct the player y position
    ld      a,7
    ld      [playerWaterTick],a

    ; reset water state
    xor     a
    ld      [playerWasUnderWater],a
    ld      [playerUnderWater],a
    ld      [playerJumpForce],a

    ; force gravity
    inc     a
    ld      [playerWaterHitDone],a
    ld      [playerGravityTick],a

.not_initial:

    ; ignore water physics while pounding
    ld      a,[playerIsPounding]
    cp      0
    ret     nz

    ; prevent sleep and reset fall speed
    xor     a
    ld      [playerDoubleJumped],a
    ld      [playerSleepTick],a

    ; check if water hit done
    ld      a,[playerWaterHitDone]
    cp      0
    jr      z,.swim

    ; can we dive?
    ld      a,[playerAbility]
    and     PLAYER_ABILITY_DIVE
    jr      z,.swim

    ; check button for diving
    ld      a,[coreInput]
    and     BUTTON_B
    jr      z,.swim

    ; animation and speed
    ld      a,PLAYER_ANIMATION_FALL
    ld      [playerAnimation],a

    ld      a,PLAYER_JUMP_FORCE_SWIM
    ld      [playerFallSpeed],a
    jr      .offset

.swim:
    xor     a
    ld      [playerFallSpeed],a

    ; check swimming offset or initial hit offset
.offset:
    ld      a,[playerWaterHitDone]
    cp      0
    jr      nz,.animate_water

    ; initial "splash / hit" offset
    ld      a,[playerWaterTick]
    cp      PLAYER_WATER_OFFSET_MAX; check if we're done
    jr      z,.water_hit_done

    ld      a,[playerWaterTick]
    inc     a
    ld      [playerWaterTick],a

    ; load the y offset for the splash
    ld      hl,playerWaterHitOffsetTable
    ld      b,0
    ld      c,a
    add     hl,bc

    ; set diving / surfacing animation
    cp      14
    jr      c,.down
    ld      a,PLAYER_ANIMATION_SURFACE
    jr      .animate
.down:
    ld      a,PLAYER_ANIMATION_FALL

.animate:
    ld      [playerAnimation],a

    ; load y offset value
    ld      b,[hl]

    ; adjust the depth based on the fall speed
    ld      a,[playerWaterHitDepth]
    cp      15
    jr      nc,.fast
    srl     b; divide depth by 2 if speed was low

    ; apply water animation offset
.fast:
    ld      a,[playerY]
    add     b
    ld      [playerYOffset],a
    jr      .check_swim_dissolve

.water_hit_done:
    ld      a,1
    ld      [playerWaterHitDone],a
    ld      a,7; set the value so the first movement after the splash is up
    ld      [playerWaterTick],a

.check_swim_dissolve:

    ; can we swim if so, just fall into the water
    ld      a,[playerAbility]
    and     PLAYER_ABILITY_SWIM
    ret     nz

    ; if player cannot swim dissolve after entering water
    ld      a,[playerWaterTick]
    cp      6
    jp      nc,player_dissolve; >= 6
    ret

    ; swimming offset
.animate_water:

    ; load y offset from table
    ld      a,[playerWaterTick]
    ld      hl,playerWaterSwimOffsetTable
    ld      b,0
    ld      c,a
    add     hl,bc
    ld      b,[hl]

    ld      a,[playerWaterTick]
    cp      8
    jr      c,.move_down ; if 4 is greater than the tick, move the player down (0, 1, 2, 3)

.move_up: ; move the player up on 4, 5, 6, 7
    ld      a,[playerY]
    sub     b
    ld      [playerYOffset],a
    ret

.move_down:; move playerdown on all other frames
    ld      a,[playerY]
    add     b
    ld      [playerYOffset],a
    ret


player_water_timer:

    ; check if in water
    ld      a,[playerInWater]
    cp      0
    jr      z,.done

    ; check if we've finished the initial splash offseting
    ld      a,[playerWaterHitDone]
    cp      0
    jr      z,.bubble

    ; update offset tick
.tick:
    ld      a,[playerWaterTick]
    inc     a
    cp      16
    jr      nz,.done
    jr      c,.done
    xor     a

.done:
    ld      [playerWaterTick],a

.bubble:

    ; check if we're under water
    ld      a,[playerUnderWater]
    cp      0
    ret     z

    ; check if effect counter reached 0
    ld      a,[playerEffectCounter]
    cp      0
    jr      nz,.decrease_bubble_counter

    ; reset counter
    call    math_random
    and     %0000_0111
    add     PLAYER_AIR_BUBBLE_INTERVAL
    ld      [playerEffectCounter],a

    ; create air bubble effect above player
    ld      a,[playerYOffset]
    sub     PLAYER_HEIGHT
    add     6
    ld      b,a

    ld      a,[playerDirection]
    cp      PLAYER_DIRECTION_LEFT
    jr      z,.bubble_left

    ld      a,[playerX]
    add     PLAYER_HALF_WIDTH
    jr      .bubble_effect

.bubble_left:
    ld      a,[playerX]
    add     2

.bubble_effect:
    ld      c,a
    ld      a,0
    call    effect_create
    ret

.decrease_bubble_counter:
    dec     a
    ld      [playerEffectCounter],a
    ret

