SECTION "GameRam",WRAM0[$C0DF]


; Game Constants --------------------------------------------------------------
GAME_MODE_LOGO      EQU 0
GAME_MODE_INIT      EQU 1
GAME_MODE_FADE_IN   EQU 2
GAME_MODE_TITLE     EQU 3
GAME_MODE_CONTINUE  EQU 4
GAME_MODE_START     EQU 5
GAME_MODE_PLAYING   EQU 6

GAME_DEBUG_MODE     EQU 0

; Game State ------------------------------------------------------------------
gameMode:           DB

