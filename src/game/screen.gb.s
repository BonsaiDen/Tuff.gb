SECTION "ScreenLogic",ROM0


; Screen ----------------------------------------------------------------------
screen_timer:
    call    _screen_animate_palette
    call    _screen_shake_timer
    ret


; Screen Shaking --------------------------------------------------------------
screen_shake: ; a = duration in seconds / 8
    ld      [screenShakeTicks],a
    ret


_screen_shake_timer:
    ld      a,[screenShakeTicks]
    cp      0
    ret     z

    dec     a
    ld      [screenShakeTicks],a
    cp      0
    jr      z,.reset

.x:
    call    math_random
    ld      b,a
    and     %01000000 ; negative
    cp      %01000000
    jr      z,.negative_x

.positive_x:
    ld      a,b
    and     %00000011 ; 0-8
    ld      [coreScrollX],a
    jr      .y

.negative_x:
    ld      a,b
    and     %00000011 ; 0-8
    add     254
    ld      [coreScrollX],a

.y:
    call    math_random
    ld      b,a
    and     %01000000 ; negative
    cp      %01000000
    jr      z,.negative_y

.positive_y:
    ld      a,b
    and     %00000011 ; 0-8
    ld      [coreScrollY],a
    jr      .done

.negative_y:
    ld      a,b
    and     %00000011 ; 0-8
    add     254
    ld      [coreScrollY],a

.done:
    ret

.reset:
    xor     a
    ld      [coreScrollX],a
    ld      [coreScrollY],a
    ret



; Screen Fading ---------------------------------------------------------------
screen_animate:; a = animation type
    ld      [screenAnimation],a
    call    _screen_animate_palette
    ret
            

; Color Mixing ----------------------------------------------------------------
_screen_animate_palette:

    ; check if active
    ld      a,[screenAnimation]
    bit     0,a
    ret     z

    ; check whether fade or flash
    bit     1,a
    jr      z,.fade
.flash:
    ld      hl,_screen_flash_map
    jr      .color

.fade:
    ; check whether fade out or in
    bit     2,a
    jr      nz,.fade_in
.fade_out:
    ld      hl,_screen_fade_out_map
    jr      .color

.fade_in:
    ld      hl,_screen_fade_in_map

.color:
    ; check whether dark or light mode
    bit     3,a
    jr      nz,.dark

.light:
    ld      b,5; offset into lighter color table
    jr      .update

.dark:
    ld      b,0; offset into darker color table
    
.update:

    ; load animation index
    ld      a,[screenAnimationIndex]
    
    ; add to table
    ld      d,0
    ld      e,a
    add     hl,de
    
    ; next index
    inc     a
    ld      [screenAnimationIndex],a

    ; load offset value
    ld      a,[hl]

    ; check if end of table and disable animation
    cp      $FF
    jr      z,.done

    ; otherwise combine with color offset
    add     b

    ; and update palette
    ld      d,a
    call    _screen_update_palette

    ; flag palette as changed for update during next vblank
    ld      a,$01
    ld      [corePaletteChanged],a

    ret

.done:
    xor     a
    ld      [screenAnimation],a
    ld      [screenAnimationIndex],a
    ret


_screen_update_palette:; d = fade value

    ld      hl,_screen_palette_bg
    call    _color_from_palette
    ld      [corePaletteBG],a

    ld      hl,_screen_palette_sprite0
    call    _color_from_palette
    ld      [corePaletteSprite0],a

    ld      hl,_screen_palette_sprite1
    call    _color_from_palette
    ld      [corePaletteSprite1],a

    ret

_color_from_palette:; hl = palette pointer; d = offset
    xor     a
    ld      e,%11000000
    call    _screen_mix_color_two
    ld      e,%00110000
    call    _screen_mix_color_two
    ld      e,%00001100
    call    _screen_mix_color_two
    ld      e,%00000011
    call    _screen_mix_color_two
    ret

_screen_mix_color_two:; hl = color pointer, d = offset, e = mask, a = color input -> color output

    ; store current color into c
    ld      c,a
    push    bc

    ; load color palette pointer
    ld      a,[hli]
    ld      c,a
    ld      a,[hli]
    ld      b,a

    ; add offset value to bc
    ld      a,d; offset value
    add     a,c
    ld      c,a
    adc     a,b
    sub     c
    ld      b,a

    ; load mix color value
    ld      a,[bc]

    ; restore current color
    pop     bc

    ; mix colors
    and     e; apply mask
    or      c; combine

    ret


; Fading and Flashing Data ----------------------------------------------------
_screen_flash_map:
    DB      $02,$03,$04,$04,$04,$04,$04,$04,$04,$03,$02,$01,$00,$FF

_screen_fade_out_map:
    DB      $00,$00,$00,$00,$01,$02,$03,$04,$FF

_screen_fade_in_map:
    DB      $04,$04,$04,$04,$03,$02,$01,$00,$FF


; Palette and Color Data ------------------------------------------------------
_screen_palette_bg:
    DW _screen_color_back
    DW _screen_color_dark_gray
    DW _screen_color_light_gray
    DW _screen_color_white

_screen_palette_sprite0:
    DW _screen_color_back
    DW _screen_color_light_gray
    DW _screen_color_white
    DW _screen_color_white; not used, always transparent

_screen_palette_sprite1:
    DW _screen_color_dark_gray
    DW _screen_color_light_gray
    DW _screen_color_white
    DW _screen_color_white; not used, always transparent

_screen_color_back:
    ; darker
    DB      %11_11_11_11
    DB      %11_11_11_11
    DB      %11_11_11_11
    DB      %11_11_11_11
    DB      %11_11_11_11

    ; lighter
    DB      %11_11_11_11
    DB      %11_11_11_11
    DB      %10_10_10_10
    DB      %01_01_01_01
    DB      %00_00_00_00

_screen_color_dark_gray:
    ; darker
    DB      %10_10_10_10
    DB      %10_10_10_10
    DB      %10_10_10_10
    DB      %11_11_11_11
    DB      %11_11_11_11

    ; lighter
    DB      %10_10_10_10
    DB      %10_10_10_10
    DB      %01_01_01_01
    DB      %01_01_01_01
    DB      %00_00_00_00

_screen_color_light_gray:
    ; darker
    DB      %01_01_01_01
    DB      %01_01_01_01
    DB      %10_10_10_10
    DB      %10_10_10_10
    DB      %11_11_11_11

    ; lighter
    DB      %01_01_01_01
    DB      %01_01_01_01
    DB      %01_01_01_01
    DB      %00_00_00_00
    DB      %00_00_00_00

_screen_color_white:
    ; darker
    DB      %00_00_00_00
    DB      %01_01_01_01
    DB      %10_10_10_10
    DB      %10_10_10_10
    DB      %11_11_11_11

    ; lighter
    DB      %00_00_00_00
    DB      %00_00_00_00
    DB      %00_00_00_00
    DB      %00_00_00_00
    DB      %00_00_00_00

