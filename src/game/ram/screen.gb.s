SECTION "ScreenRam",WRAM0[$C0E1]

; Palette Animation -----------------------------------------------------------
SCREEN_PALETTE_FADE_OUT     EQU %0000_0001
SCREEN_PALETTE_FADE_IN      EQU %0000_0101
SCREEN_PALETTE_FLASH        EQU %0000_0011
SCREEN_PALETTE_FLASH_FAST   EQU %0000_1011
SCREEN_PALETTE_DARK         EQU %0001_0000
SCREEN_PALETTE_LIGHT        EQU %0000_0000


; Screen State ----------------------------------------------------------------
screenAnimation:        DB
screenAnimationIndex:   DB
screenScrollX:          DB
screenScrollY:          DB
screenShakeTicks:       DB

