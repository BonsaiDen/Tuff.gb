entity_handler_load_platform: ; b = entity index, c = sprite index
    ld      a,c
    ld      b,ENTITY_ANIMATION_OFFSET + ENTITY_ANIMATION_PLATFORM
    call    sprite_set_animation

    ; TODO check initial flags and move platform by a few pixels
    ret

entity_handler_update_platform: ; generic, b = entity index, c = sprite index, de = screen data

    ld      l,0; flag = 1 if player is on THIS platform

    inc     e; skip type
    inc     e; skip flags
    ld      a,[de]; load direction flag
    ld      h,a
    inc     e

    ; load position
    ld      a,[de]; load y position and store into c
    ld      c,a
    inc     e
    ld      a,[de]; load x position and store into b
    ld      b,a

    ; see if player is standing clipping into platform
    ld      a,[playerY]
    add     16

    ; check overlap within in a certain range to handle higher fall speeds
    cp      c
    jr      c,.no_player
    sub     2
    cp      c
    jr      nc,.no_player

    ; ignore when jumping upwards
    ld      a,[playerJumpForce]
    cp      0
    jr      nz,.no_player

    ; check if player is on platform
    ld      a,[playerX]
    add     10; center of player sprite
    cp      b; compare with left end of platform
    jr      c,.no_player ; playerX + 8 => b
    sub     20; offset for right end of platform
    cp      b
    jr      nc,.no_player ; playerX + 8 <= b + 16

    ; correct player Y to be exactly on top of platform
    ld      a,c
    sub     16
    ld      [playerY],a

    ; store plaform direction
    ld      a,h
    ld      [playerPlatformDirection],a
    ld      l,1

.no_player:
    dec     e
    dec     e

    ; check if we should move on this frame
    ld      a,[coreLoopCounter]
    and     %0000_0001
    ret     z

    ; check if player is on this very platform
    ld      a,l
    cp      0
    jr      z,.no_player_speed

    ; if so, set platform speed
    ld      a,1
    ld      [playerPlatformSpeed],a

    ; check platform direction
.no_player_speed:
    ld      a,h
    cp      0
    jr      nz,.move_right

    ; flags = 0
.move_left:

    call    entity_col_left
    jr      c,.switch_to_right
    dec     b
    jr      .position

    ; flags = 1
.move_right:
    call    entity_col_right
    jr      c,.switch_to_left
    inc     b

.position:
    inc     e; skip direction
    ld      a,c
    ld      [de],a

    inc     de
    ld      a,b
    ld      [de],a

    ret

.switch_to_right:
    ld      a,1
    ld      [de],a
    ld      b,a
    jr      .switched

.switch_to_left:
    xor     a
    ld      [de],a
    ld      b,a

.switched:

    ; check if player is on this very platform
    ld      a,l
    cp      0
    ret     z

    ; if so apply new direction to avoid notches when platform toggles direction
    ld      a,b
    ld      [playerPlatformDirection],a
    ret

