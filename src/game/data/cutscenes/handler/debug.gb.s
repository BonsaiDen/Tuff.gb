cutscene_handler_debug_setup:
    xor     a; disable player control
    ld      [playerHasControl],a

    xor     a; how many ticks this stage should run for
    ret

cutscene_handler_debug_run:
    ld      a,255; how many ticks this stage should run for
    ret


cutscene_handler_debug_finish:
    ld      a,1; enable control
    ld      [playerHasControl],a
    call    cutscene_end; leaves 0 in a
    ret

