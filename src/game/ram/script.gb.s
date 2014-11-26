SECTION "ScriptRam",WRAM0[$CC9F]


; Scripting Triggers ----------------------------------------------------------
SCRIPT_TABLE_ENTRIES        EQU 1
SCRIPT_TRIGGER_ROOM_ENTER   EQU 0
SCRIPT_TRIGGER_ROOM_LEAVE   EQU 1
SCRIPT_TRIGGER_ROOM_ONCE    EQU 2


; Script State ----------------------------------------------------------------
scriptTableStatus:      DS 32
                        

; Script Macros ---------------------------------------------------------------
MACRO scriptTableEntry(@x, @y, @flags, @address)
    DB (@x << 4) | @y
    DB @flags
    DW @address
ENDMACRO

