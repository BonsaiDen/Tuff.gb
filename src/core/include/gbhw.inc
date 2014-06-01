;*
;* GBHW.INC - Gameboy Hardware definitions for GALP
;*
;* by GABY. Inspired from work done by Carsten Sorensen & others.
;*
;* V1.0 - The original version
;*
VRAM_LOW    EQU $8000 ; $8000->$8800
VRAM_HIGH   EQU $8800 ; $8800->$9800
SCREEN1     EQU $9800 ; $9800->$9BFF
SCREEN2     EQU $9C00 ; $9C00->$9FFF

; --
; -- P1 ($FF00)
; -- Register for reading joy pad info. (R/W)
; --
rP1 EQU $FF00


; --
; -- LCDC ($FF40)
; -- LCD Control (R/W)
; --
rLCDC EQU $FF40

LCDCF_OFF EQU %00000000 ; LCD Control Operation
LCDCF_ON EQU %10000000 ; LCD Control Operation
LCDCF_WIN9800 EQU %00000000 ; Window Tile Map Display Select
LCDCF_WIN9C00 EQU %01000000 ; Window Tile Map Display Select
LCDCF_WINOFF EQU %00000000 ; Window Display
LCDCF_WINON EQU %00100000 ; Window Display
LCDCF_BG8800 EQU %00000000 ; BG & Window Tile Data Select
LCDCF_BG8000 EQU %00010000 ; BG & Window Tile Data Select
LCDCF_BG9800 EQU %00000000 ; BG Tile Map Display Select
LCDCF_BG9C00 EQU %00001000 ; BG Tile Map Display Select
LCDCF_OBJ8 EQU %00000000 ; OBJ Construction
LCDCF_OBJ16 EQU %00000100 ; OBJ Construction
LCDCF_OBJOFF EQU %00000000 ; OBJ Display
LCDCF_OBJON EQU %00000010 ; OBJ Display
LCDCF_BGOFF EQU %00000000 ; BG Display
LCDCF_BGON EQU %00000001 ; BG Display



; --
; -- STAT ($FF41)
; -- LCDC Status (R/W)
; --
rSTAT EQU $FF41

STATF_LYC EQU %01000000 ; LYCEQULY Coincidence (Selectable)
STATF_MODE10 EQU %00100000 ; Mode 10
STATF_MODE01 EQU %00010000 ; Mode 01 (V-Blank)
STATF_MODE00 EQU %00001000 ; Mode 00 (H-Blank)
STATF_LYCF EQU %00000100 ; Coincidence Flag
STATF_HB EQU %00000000 ; H-Blank
STATF_VB EQU %00000001 ; V-Blank
STATF_OAM EQU %00000010 ; OAM-RAM is used by system
STATF_LCD EQU %00000011 ; Both OAM and VRAM used by system
STATF_BUSY EQU %00000010 ; When set, VRAM access is unsafe


; --
; -- SCY ($FF42)
; -- Scroll Y (R/W)
; --
rSCY EQU $FF42


; --
; -- SCY ($FF43)
; -- Scroll X (R/W)
; --
rSCX EQU $FF43


; --
; -- LY ($FF44)
; -- LCDC Y-Coordinate (R)
; --
; -- Values range from 0->153. 144->153 is the VBlank period.
; --
rLY EQU $FF44


; --
; -- LYC ($FF45)
; -- LY Compare (R/W)
; --
; -- When LYEQUEQULYC, STATF_LYCF will be set in STAT
; --
rLYC EQU $FF45


; --
; -- WY ($FF4A)
; -- Window Y Position (R/W)
; --
; -- 0 <EQU WY <EQU 143
; --
rWY EQU $FF4A


; --
; -- WX ($FF4B)
; -- Window X Position (R/W)
; --
; -- 7 <EQU WX <EQU 166
; --
rWX EQU $FF4B


; --
; -- DMA ($FF46)
; -- DMA Transfer and Start Address (W)
; --
rDMA EQU $FF46


; --
; -- BGP ($FF47)
; -- BG Palette Data (W)
; --
; -- Bit 7-6 - Intensity for %11
; -- Bit 5-4 - Intensity for %10
; -- Bit 3-2 - Intensity for %01
; -- Bit 1-0 - Intensity for %00
; --
rBGP EQU $FF47


; --
; -- OBP0 ($FF48)
; -- Object Palette 0 Data (W)
; --
; -- See BGP for info
; --
rOBP0 EQU $FF48


; --
; -- OBP1 ($FF49)
; -- Object Palette 1 Data (W)
; --
; -- See BGP for info
; --
rOBP1 EQU $FF49


; --
; -- SB ($FF01)
; -- Serial Transfer Data (R/W)
; --
rSB EQU $FF01

; --
; -- SC ($FF02)
; -- Serial I/O Control (R/W)
; --
rSC EQU $FF02

; --
; -- DIV ($FF04)
; -- Divider register (R/W)
; --
rDIV EQU $FF04


; --
; -- TIMA ($FF05)
; -- Timer counter (R/W)
; --
rTIMA EQU $FF05


; --
; -- TMA ($FF06)
; -- Timer modulo (R/W)
; --
rTMA EQU $FF06


; --
; -- TAC ($FF07)
; -- Timer control (R/W)
; --
rTAC EQU $FF07

TACF_START EQU %00000100
TACF_STOP EQU %00000000
TACF_4KHZ EQU %00000000
TACF_16KHZ EQU %00000011
TACF_65KHZ EQU %00000010
TACF_262KHZ EQU %00000001


; --
; -- IF ($FF0F)
; -- Interrupt Flag (R/W)
; --
; -- IE ($FFFF)
; -- Interrupt Enable (R/W)
; --
rIF EQU $FF0F
rIE EQU $FFFF

IEF_HILO EQU %00010000 ; Transition from High to Low of Pin number P10-P13
IEF_SERIAL EQU %00001000 ; Serial I/O transfer end
IEF_TIMER EQU %00000100 ; Timer Overflow
IEF_LCDC EQU %00000010 ; LCDC (see STAT)
IEF_VBLANK EQU %00000001 ; V-Blank
