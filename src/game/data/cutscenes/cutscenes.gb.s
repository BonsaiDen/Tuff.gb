; Cutscene Handler Table ------------------------------------------------------
DataCutsceneHandlerTable:

    DB      $01; cutscene 1, stage 0
    DW      cutscene_handler_debug_setup 
    DB      $01
    DW      cutscene_handler_debug_run 
    DB      $01
    DW      cutscene_handler_debug_finish 

    DB      $FF; end marker for table


; Cutscene Logic Code Includes ------------------------------------------------
    INCLUDE "handler/debug.gb.s"

