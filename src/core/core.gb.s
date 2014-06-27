; Variables -------------------------------------------------------------------
SECTION "CoreDMACode",HRAM[$FF80]
DS                  10 ; DMA code area


SECTION "CoreVars",HRAM[$FF8A] ; stored into high ram for quicker access
coreRandomHigh:     DB
coreRandomLow:      DB
coreVBlankDone:     DB
coreLoopCounter:    DB
coreTimerCounter:   DB
coreTimer:          DB; ~60ms timer interrupt
coreInput:          DB; [Down][Up][Left][Right][Start][Select][B][A]
coreInputOn:        DB
coreInputOff:       DB
corePaletteBG:      DB
corePaletteSprite0: DB
corePaletteSprite1: DB
coreScrollX:        DB
coreScrollY:        DB
coreDecodeLabel:    DS 3


; Code ------------------------------------------------------------------------
SECTION "Core $0040",ROM0[$0040]
    jp      core_vblank_handler ; Interrupt Handler

SECTION "Core $0050",ROM0[$0050]
    jp      core_timer_handler ; Interrupt Handler

SECTION "Core $0100",ROM0[$100]
    nop
    call    core_init


; Nintendo scrolling logo -----------------------------------------------------
DB $CE,$ED,$66,$66,$CC,$0D,$00,$0B,$03,$73,$00,$83,$00,$0C,$00,$0D
DB $00,$08,$11,$1F,$88,$89,$00,$0E,$DC,$CC,$6E,$E6,$DD,$DD,$D9,$99
DB $BB,$BB,$67,$63,$6E,$0E,$EC,$CC,$DD,$DC,$99,$9F,$BB,$B9,$33,$3E


; Catridge Name ---------------------------------------------------------------
DB STRUPR("{CART_NAME}")


; Cartridge Options -----------------------------------------------------------
SECTION "Core Rom Header",ROM0[$143]
DB 0                         ; $143
DB STRUPR("{CART_LICENSEE}") ; $144 - Licensee code (not important)
DB 0                         ; $146 - SGB Support indicator
DB CART_TYPE                 ; $147 - Cart type
DB CART_ROM_SIZE             ; $148 - ROM Size
DB CART_RAM_SIZE             ; $149 - RAM Size
DB CART_DEST                 ; $14a - Destination code
DB $33                       ; $14b - Old licensee code
DB 0                         ; $14c - Mask ROM version
DB 0                         ; $14d - Header checksum (important)
DW 0                         ; $14e - Global checksum (not important)


; Core Program ----------------------------------------------------------------
SECTION "CoreCode",ROM0[$0150]
    INCLUDE "core/include/gbhw.inc"
    INCLUDE "core/decode.gb.s"
    INCLUDE "core/dma.gb.s"
    INCLUDE "core/init.gb.s"
    INCLUDE "core/input.gb.s"
    INCLUDE "core/loop.gb.s"
    INCLUDE "core/math.gb.s"
    INCLUDE "core/memory.gb.s"
    INCLUDE "core/screen.gb.s"
    INCLUDE "core/timer.gb.s"
    INCLUDE "core/vblank.gb.s"
