rSCY  EQU $FF42
rSCX  EQU $FF43
rLY   EQU $FF44

rSTAT EQU $FF41
STATF_BUSY    EQU  %00000010 ; When set, VRAM access is unsafe

_OAMRAM       EQU  $FE00 ; $FE00->$FE9F

rP1 EQU $FF00

rBGP  EQU $FF47
rOBP0 EQU $FF48
rOBP1 EQU $FF49

rIF EQU $FF0F
rIE EQU $FFFF
IEF_TIMER   EQU  %00000100 ; Timer Overflow
IEF_VBLANK  EQU  %00000001 ; V-Blank


rTAC EQU $FF07

TACF_START   EQU %00000100
TACF_STOP    EQU %00000000
TACF_4KHZ    EQU %00000000
TACF_16KHZ   EQU %00000011
TACF_65KHZ   EQU %00000010
TACF_262KHZ  EQU %00000001


rLCDC EQU $FF40

LCDCF_OFF     EQU  %00000000 ; LCD Control Operation
LCDCF_ON      EQU  %10000000 ; LCD Control Operation
LCDCF_WIN9800 EQU  %00000000 ; Window Tile Map Display Select
LCDCF_WIN9C00 EQU  %01000000 ; Window Tile Map Display Select
LCDCF_WINOFF  EQU  %00000000 ; Window Display
LCDCF_WINON   EQU  %00100000 ; Window Display
LCDCF_BG8800  EQU  %00000000 ; BG & Window Tile Data Select
LCDCF_BG8000  EQU  %00010000 ; BG & Window Tile Data Select
LCDCF_BG9800  EQU  %00000000 ; BG Tile Map Display Select
LCDCF_BG9C00  EQU  %00001000 ; BG Tile Map Display Select
LCDCF_OBJ8    EQU  %00000000 ; OBJ Construction
LCDCF_OBJ16   EQU  %00000100 ; OBJ Construction
LCDCF_OBJOFF  EQU  %00000000 ; OBJ Display
LCDCF_OBJON   EQU  %00000010 ; OBJ Display
LCDCF_BGOFF   EQU  %00000000 ; BG Display
LCDCF_BGON    EQU  %00000001 ; BG Display


ROM_NOMBC         EQU 0
ROM_MBC1          EQU 1
ROM_MBC1_RAM      EQU 2
ROM_MBC1_RAM_BAT  EQU 3
ROM_MBC2          EQU 5
ROM_MBC2_BAT      EQU 6
ROM_NOMBC_RAM     EQU 8
ROM_NOMBC_RAM_BAT EQU 9

ROM_SIZE_256KBIT  EQU 0
ROM_SIZE_512KBIT  EQU 1
ROM_SIZE_1M       EQU 2
ROM_SIZE_2M       EQU 3
ROM_SIZE_4M       EQU 4
ROM_SIZE_8M       EQU 5
ROM_SIZE_16M      EQU 6

ROM_SIZE_32KBYTE  EQU 0
ROM_SIZE_64KBYTE  EQU 1
ROM_SIZE_128KBYTE EQU 2
ROM_SIZE_256KBYTE EQU 3
ROM_SIZE_512KBYTE EQU 4
ROM_SIZE_1MBYTE   EQU 5
ROM_SIZE_2MBYTE   EQU 6

RAM_SIZE_0KBIT   EQU 0
RAM_SIZE_16KBIT  EQU 1
RAM_SIZE_64KBIT  EQU 2
RAM_SIZE_256KBIT EQU 3
RAM_SIZE_1MBIT   EQU 4

RAM_SIZE_0KBYTE   EQU 0
RAM_SIZE_2KBYTE   EQU 1
RAM_SIZE_8KBYTE   EQU 2
RAM_SIZE_32KBYTE  EQU 3
RAM_SIZE_128KBYTE EQU 4




NINTENDO_LOGO:   MACRO
;*
;* Nintendo scrolling logo
;* (Code won't work on a real GameBoy)
;* (if next six lines are altered.)
 DB $CE,$ED,$66,$66,$CC,$0D,$00,$0B,$03,$73,$00,$83,$00,$0C,$00,$0D
 DB $00,$08,$11,$1F,$88,$89,$00,$0E,$DC,$CC,$6E,$E6,$DD,$DD,$D9,$99
 DB $BB,$BB,$67,$63,$6E,$0E,$EC,$CC,$DD,$DC,$99,$9F,$BB,$B9,$33,$3E
        ENDM

ROM_HEADER:   MACRO


;*
;* Nintendo scrolling logo
;* (Code won't work on a real GameBoy)
;* (if next six lines are altered.)

;    0123456789ABCDEF
 DB $CE,$ED,$66,$66,$CC,$0D,$00,$0B,$03,$73,$00,$83,$00,$0C,$00,$0D
 DB $00,$08,$11,$1F,$88,$89,$00,$0E,$DC,$CC,$6E,$E6,$DD,$DD,$D9,$99
 DB $BB,$BB,$67,$63,$6E,$0E,$EC,$CC,$DD,$DC,$99,$9F,$BB,$B9,$33,$3E

 DB "Tuff",0,0,0,0,0,0,0,0,0,0,0 ; Cart name - 15bytes
 DB 0                         ; $143
 DB 0,0                       ; $144 - Licensee code (not important)
 DB 0                         ; $146 - SGB Support indicator
 DB \1                        ; $147 - Cart type
 DB \2                        ; $148 - ROM Size
 DB \3                        ; $149 - RAM Size
 DB 1                         ; $14a - Destination code
 DB $33                       ; $14b - Old licensee code
 DB 0                         ; $14c - Mask ROM version
 DB 0                         ; $14d - Complement check (important)
 DW 0                         ; $14e - Checksum (not important)

