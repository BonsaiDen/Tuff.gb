;*
;* GBHW.INC - Gameboy Hardware definitions for GALP
;*
;* by GABY. Inspired from work done by Carsten Sorensen & others.
;*
;* V1.0 - The original version
;*

;***************************************************************************
;*
;* Cart related
;*
;***************************************************************************
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

RAM_SIZE_0KBIT    EQU 0
RAM_SIZE_16KBIT   EQU 1
RAM_SIZE_64KBIT   EQU 2
RAM_SIZE_256KBIT  EQU 3
RAM_SIZE_1MBIT    EQU 4

RAM_SIZE_0KBYTE   EQU 0
RAM_SIZE_2KBYTE   EQU 1
RAM_SIZE_8KBYTE   EQU 2
RAM_SIZE_32KBYTE  EQU 3
RAM_SIZE_128KBYTE EQU 4

ROM_DEST_JAPANESE EQU 0
ROM_DEST_OTHER    EQU 1

