cutscene_handler_debug_setup:
    xor     a; disable player control
    ld      [playerHasControl],a
    ld      [entityUpdateActive],a

    xor     a; how many ticks this stage should run for
    ret

cutscene_handler_debug_run:
    ld      a,30; how many ticks this stage should run for
    ret


cutscene_handler_debug_finish:
    ld      a,1; enable control
    ld      [playerHasControl],a
    ld      [entityUpdateActive],a
    call    cutscene_end; leaves 0 in a
    ret

