; Entity Animations -----------------------------------------------------------

; Each Animation takes 32 bytes
; The first 16 are the tile indexes (which are 16x16)
; The other 16 bytes are frame lengths, each frame is 16ms long.
; FF FD and FE are special values for frame lengths which are used to control
; the animation behavior. FF means STOP, FE means loop, FD means bounce

; Save Point Light
DB $00; Image Row Index
DW DataEntityImg ; Image Data Pointer
DB $FF; Unused
DB $00,$01,$02,$03, $fe,$ff,$ff,$ff, $ff,$ff,$ff,$ff, $ff,$ff
DB $09,$09,$09,$09, $00,$ff,$ff,$ff, $ff,$ff,$ff,$ff, $ff,$ff

; Save Point Dark
DB $01; Image Row Index
DW DataEntityImg ; Image Data Pointer
DB $FF; Unused
DB $00,$01,$02,$03, $fe,$ff,$ff,$ff, $ff,$ff,$ff,$ff, $ff,$ff
DB $09,$09,$09,$09, $00,$ff,$ff,$ff, $ff,$ff,$ff,$ff, $ff,$ff

; Glow Flicker
DB $02; Image Row Index
DW DataEntityImg ; Image Data Pointer
DB $FF; Unused
DB $00,$01,$02,$03, $fe,$ff,$ff,$ff, $ff,$ff,$ff,$ff, $ff,$ff
DB $02,$02,$02,$02, $00,$ff,$ff,$ff, $ff,$ff,$ff,$ff, $ff,$ff

; Powerup Hover
DB $03; Image Row Index
DW DataEntityImg ; Image Data Pointer
DB $FF; Unused
DB $00,$01,$02,$03, $fe,$ff,$ff,$ff, $ff,$ff,$ff,$ff, $ff,$ff
DB $b0,$06,$06,$06, $00,$ff,$ff,$ff, $ff,$ff,$ff,$ff, $ff,$ff

