SECTION "ScreenLogic",ROM0


; Screen ----------------------------------------------------------------------
screen_timer:
    call    _screen_flash_timer
    call    _screen_fade_timer
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
    ld      a,0
    ld      [coreScrollX],a
    ld      [coreScrollY],a
    ret



; Screen Fading ---------------------------------------------------------------
screen_fade_out_light:
    ld      a,1
    ld      [screenFadeMode],a
    ld      a,0
    ld      [screenFadeIndex],a
    ret


screen_fade_in_light:
    ld      a,2
    ld      [screenFadeMode],a
    ld      a,4
    ld      [screenFadeIndex],a
    ret


_screen_fade_timer:

    ; check if fading
    ld      a,[screenFadeMode]
    cp      0
    ret     z

    ; fade index
    ld      a,[screenFadeIndex]
    ld      b,0
    ld      c,a
    
    ; bg mask
    ld      hl,screenFadePaletteBGLight
    add     hl,bc
    ld      a,[hl]
    ld      [corePaletteBG],a

    ; sprite mask
    ld      hl,screenFadePaletteSprite0Light
    add     hl,bc
    ld      a,[hl]
    ld      [corePaletteSprite0],a
    ld      [corePaletteSprite1],a

    ld      hl,screenFadePaletteSprite1Light
    add     hl,bc
    ld      a,[hl]
    ld      [corePaletteSprite1],a

    ; fade mode
    ld      a,[screenFadeMode]
    cp      2
    jr      z,.fade_in
        
    ; fade out
    ld      a,[screenFadeIndex]
    cp      4
    jr      z,.complete
    inc     a
    ld      [screenFadeIndex],a
    ret

    ; fade in
.fade_in:
    ld      a,[screenFadeIndex]
    cp      0
    jr      z,.complete
    dec     a
    ld      [screenFadeIndex],a
    ret

.complete:
    ld      a,0
    ld      [screenFadeMode],a
    ret


; Screen Flashing -------------------------------------------------------------
screen_flash_light:
    push    af
    push    hl
    push    bc
    ld      a,1
    ld      [screenFlashMode],a
    ld      a,0
    ld      [screenFlashColor],a
    ld      [screenFlashIndex],a
    call    _screen_flash_timer
    pop     bc
    pop     hl
    pop     af
    ret

screen_flash_fast_light:
    push    af
    push    hl
    push    bc
    ld      a,1
    ld      [screenFlashMode],a
    ld      a,0
    ld      [screenFlashColor],a
    ld      a,2
    ld      [screenFlashIndex],a
    call    _screen_flash_timer
    pop     bc
    pop     hl
    pop     af
    ret

screen_flash_dark:
    push    af
    push    hl
    push    bc
    ld      a,1
    ld      [screenFlashMode],a
    ld      [screenFlashColor],a
    ld      a,0
    ld      [screenFlashIndex],a
    call    _screen_flash_timer
    pop     bc
    pop     hl
    pop     af
    ret

screen_flash_fast_dark:
    push    af
    push    hl
    push    bc
    ld      a,1
    ld      [screenFlashMode],a
    ld      [screenFlashColor],a
    ld      a,2
    ld      [screenFlashIndex],a
    call    _screen_flash_timer
    pop     bc
    pop     hl
    pop     af
    ret


_screen_flash_timer:

    ; check if fading
    ld      a,[screenFlashMode]
    cp      0
    ret     z

    ; flash index
    ld      a,[screenFlashIndex]
    ld      b,0
    ld      c,a

    ; color
    ld      a,[screenFlashColor]
    cp      1
    jr      z,.dark
    
    ; bg mask
    ld      hl,screenFlashLightPaletteBG
    add     hl,bc
    ld      a,[hl]
    ld      [corePaletteBG],a

    ; sprite mask
    ld      hl,screenFlashLightPaletteSprite0
    add     hl,bc
    ld      a,[hl]
    ld      [corePaletteSprite0],a

    ld      hl,screenFlashLightPaletteSprite1
    add     hl,bc
    ld      a,[hl]
    ld      [corePaletteSprite1],a
    jr      .update

.dark:
    ; bg mask
    ld      hl,screenFlashDarkPaletteBG
    add     hl,bc
    ld      a,[hl]
    ld      [corePaletteBG],a

    ; sprite mask
    ld      hl,screenFlashDarkPaletteSprite0
    add     hl,bc
    ld      a,[hl]
    ld      [corePaletteSprite0],a

    ld      hl,screenFlashDarkPaletteSprite1
    add     hl,bc
    ld      a,[hl]
    ld      [corePaletteSprite1],a
    jr      .update

.update:

    ; update
    ld      a,[screenFlashIndex]
    cp      10
    jr      z,.complete
    inc     a
    ld      [screenFlashIndex],a
    ret

.complete:
    ld      a,0
    ld      [screenFlashMode],a
    ret


; Palette Data ----------------------------------------------------------------
screenFadePaletteBGDark:
    DB      %11100100
    DB      %11100101
    DB      %11101010
    DB      %11101011
    DB      %11111111

screenFadePaletteSprite0Dark:
    DB      %11010000 
    DB      %11100100 
    DB      %11101000 
    DB      %11101100 
    DB      %11111100 

screenFadePaletteSprite1Dark:
    DB      %10010000 
    DB      %11100100 
    DB      %11101000 
    DB      %11111000 
    DB      %11111100 


screenFadePaletteBGLight:
    DB      %11100100
    DB      %11100100
    DB      %10010000
    DB      %01000000
    DB      %00000000

screenFadePaletteSprite0Light:
    DB      %11010000
    DB      %10010000
    DB      %10000000
    DB      %01000000
    DB      %00000000

screenFadePaletteSprite1Light:
    DB      %10010000 
    DB      %01010000 
    DB      %01010000 
    DB      %01000000 
    DB      %00000000


; Flash Light
screenFlashLightPaletteBG:

    DB      %10100100
    DB      %01010100
    DB      %01010000

    DB      %00000000
    DB      %00000000
    DB      %00000000
    DB      %00000000

    DB      %01010000
    DB      %01010100
    DB      %10100100
    DB      %11100100

screenFlashLightPaletteSprite0:

    DB      %10010000 
    DB      %01010000 
    DB      %01010000 

    DB      %00000000
    DB      %00000000
    DB      %00000000
    DB      %00000000

    DB      %01010000 
    DB      %01010000 
    DB      %10010000 
    DB      %11010000 

screenFlashLightPaletteSprite1:

    DB      %10010000 
    DB      %01010000 
    DB      %01010000 

    DB      %00000000
    DB      %00000000
    DB      %00000000
    DB      %00000000

    DB      %01010000 
    DB      %01010000 
    DB      %10010000 
    DB      %10010000 

; Flash Dark
screenFlashDarkPaletteBG:

    DB      %11110101
    DB      %11111010

    DB      %11111111
    DB      %11111111
    DB      %11111111
    DB      %11111111
    DB      %11111111
    DB      %11111111

    DB      %11111010
    DB      %11110101
    DB      %11100100

screenFlashDarkPaletteSprite0:

    DB      %11100100 
    DB      %11101000 

    DB      %11111111
    DB      %11111111
    DB      %11111111
    DB      %11111111
    DB      %11111111
    DB      %11111111

    DB      %11101000 
    DB      %11100100 
    DB      %11010000 

screenFlashDarkPaletteSprite1:

    DB      %10100100 
    DB      %11101000 

    DB      %11111111
    DB      %11111111
    DB      %11111111
    DB      %11111111
    DB      %11111111
    DB      %11111111

    DB      %11100100 
    DB      %10100100 
    DB      %10010000 

