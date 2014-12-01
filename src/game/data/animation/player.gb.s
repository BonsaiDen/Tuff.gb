; Player Animations -----------------------------------------------------------

; Each Animation takes 32 bytes
; The first 16 are the tile indexes (which are 16x16)
; The other 16 bytes are frame lengths, each frame is 16ms long.
; FF FD and FE are special values for frame lengths which are used to control
; the animation behavior. FF means STOP, FE means loop, FD means bounce

; Idle
DB $00; Image Row Index
DW DataPlayerImg ; Image Data Pointer
DB $FF; Unused
DB $03,$01,$03,$01, $03,$01,$03,$02, $03,$fe,$ff,$ff, $ff,$ff
DB $68,$0C,$C3,$0A, $08,$0A,$C0,$2f, $38,$00,$ff,$ff, $ff,$ff

; Walking
DB $01; Image Row Index
DW DataPlayerImg ; Image Data Pointer
DB $FF; Unused
DB $00,$01,$02,$03, $fe,$ff,$ff,$ff, $ff,$ff,$ff,$ff, $ff,$ff
DB $04,$05,$04,$06, $00,$ff,$ff,$ff, $ff,$ff,$ff,$ff, $ff,$ff

; Sleeping
DB $03; Image Row Index
DW DataPlayerImg ; Image Data Pointer
DB $FF; Unused
DB $00,$01,$02,$03, $fe,$ff,$ff,$ff, $ff,$ff,$ff,$ff, $ff,$ff
DB $25,$2A,$25,$2A, $00,$ff,$ff,$ff, $ff,$ff,$ff,$ff, $ff,$ff

; Wall Pushing
DB $04; Image Row Index
DW DataPlayerImg ; Image Data Pointer
DB $FF; Unused
DB $00,$01,$02,$03, $fe,$ff,$ff,$ff, $ff,$ff,$ff,$ff, $ff,$ff
DB $0B,$0D,$0B,$0D, $00,$ff,$ff,$ff, $ff,$ff,$ff,$ff, $ff,$ff

; Jumping 
DB $02; Image Row Index
DW DataPlayerImg ; Image Data Pointer
DB $FF; Unused
DB $03,$00,$ff,$ff, $ff,$ff,$ff,$ff, $ff,$ff,$ff,$ff, $ff,$ff
DB $05,$20,$00,$ff, $ff,$ff,$ff,$ff, $ff,$ff,$ff,$ff, $ff,$ff

; Falling / Diving down
DB $02; Image Row Index
DW DataPlayerImg ; Image Data Pointer
DB $FF; Unused
DB $02,$01,$ff,$ff, $ff,$ff,$ff,$ff, $ff,$ff,$ff,$ff, $ff,$ff
DB $02,$20,$00,$ff, $ff,$ff,$ff,$ff, $ff,$ff,$ff,$ff, $ff,$ff

; Running Full
DB $09; Image Row Index
DW DataPlayerImg ; Image Data Pointer
DB $FF; Unused
DB $00,$01,$02,$03, $fe,$ff,$ff,$ff, $ff,$ff,$ff,$ff, $ff,$ff
DB $02,$03,$02,$03, $00,$ff,$ff,$ff, $ff,$ff,$ff,$ff, $ff,$ff

; Swimming
DB $06; Image Row Index
DW DataPlayerImg ; Image Data Pointer
DB $FF; Unused
DB $00,$01,$02,$03, $fe,$ff,$ff,$ff, $ff,$ff,$ff,$ff, $ff,$ff
DB $06,$0B,$06,$0B, $00,$ff,$ff,$ff, $ff,$ff,$ff,$ff, $ff,$ff
    
; Dissolving 
DB $07; Image Row Index
DW DataPlayerImg ; Image Data Pointer
DB $FF; Unused
DB $00,$01,$02,$03, $04,$ff,$ff,$ff, $ff,$ff,$ff,$ff, $ff,$ff
DB $05,$04,$03,$02, $02,$00,$ff,$ff, $ff,$ff,$ff,$ff, $ff,$ff

; Swimming to the Surface
DB $02; Image Row Index
DW DataPlayerImg ; Image Data Pointer
DB $FF; Unused
DB $03,$00,$ff,$ff, $ff,$ff,$ff,$ff, $ff,$ff,$ff,$ff, $ff,$ff
DB $05,$20,$00,$ff, $ff,$ff,$ff,$ff, $ff,$ff,$ff,$ff, $ff,$ff

; Wall Sliding
DB $00; Image Row Index
DW DataPlayerImg ; Image Data Pointer
DB $FF; Unused
DB $00,$ff,$ff,$ff, $ff,$ff,$ff,$ff, $ff,$ff,$ff,$ff, $ff,$ff
DB $20,$00,$ff,$ff, $ff,$ff,$ff,$ff, $ff,$ff,$ff,$ff, $ff,$ff

; Start Pound
DB $05; Image Row Index
DW DataPlayerImg ; Image Data Pointer
DB $FF; Unused
DB $00,$01,$00,$01, $02,$01,$02,$ff, $ff,$ff,$ff,$ff, $ff,$ff
DB $06,$06,$06,$06, $06,$06,$06,$00, $ff,$ff,$ff,$ff, $ff,$ff

; Stop Pound
DB $05; Image Row Index
DW DataPlayerImg ; Image Data Pointer
DB $FF; Unused
DB $02,$01,$02,$01, $00,$01,$00,$ff, $ff,$ff,$ff,$ff, $ff,$ff
DB $04,$04,$04,$04, $04,$04,$04,$00, $ff,$ff,$ff,$ff, $ff,$ff

; Player Landing
DB $08; Image Row Index
DW DataPlayerImg ; Image Data Pointer
DB $FF; Unused
DB $00,$01,$02,$03, $ff,$ff,$ff,$ff, $ff,$ff,$ff,$ff, $ff,$ff
DB $09,$05,$04,$03, $00,$ff,$ff,$ff, $ff,$ff,$ff,$ff, $ff,$ff

; Double Jumping 
DB $02; Image Row Index
DW DataPlayerImg ; Image Data Pointer
DB $FF; Unused
DB $02,$03,$00,$ff, $ff,$ff,$ff,$ff, $ff,$ff,$ff,$ff, $ff,$ff
DB $04,$07,$20,$00, $ff,$ff,$ff,$ff, $ff,$ff,$ff,$ff, $ff,$ff

; Running Half
DB $01; Image Row Index
DW DataPlayerImg ; Image Data Pointer
DB $FF; Unused
DB $00,$01,$02,$03, $fe,$ff,$ff,$ff, $ff,$ff,$ff,$ff, $ff,$ff
DB $03,$04,$03,$05, $00,$ff,$ff,$ff, $ff,$ff,$ff,$ff, $ff,$ff

