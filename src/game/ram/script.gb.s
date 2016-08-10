SECTION "ScriptRam",WRAM0[$CC9F]


; Scripting Triggers ----------------------------------------------------------
SCRIPT_TABLE_MAX_ENTRIES    EQU 32
SCRIPT_TABLE_ENTRIES        EQU 2
SCRIPT_TRIGGER_ROOM_ENTER   EQU 0
SCRIPT_TRIGGER_ROOM_LEAVE   EQU 1
SCRIPT_TRIGGER_ROOM_STORE   EQU 2

SCRIPT_FLAG_TRIGGERED       EQU 1

; Script State ----------------------------------------------------------------
scriptTableStatus:      DS SCRIPT_TABLE_MAX_ENTRIES
                        

; Script Macros ---------------------------------------------------------------
MACRO scriptTableEntry(@x, @y, @flags, @address)
    DB (@x << 4) | @y
    DB @flags
    DW @address
ENDMACRO

