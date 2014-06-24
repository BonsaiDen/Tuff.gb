; Entity Animations -----------------------------------------------------------

; Each Animation takes 32 bytes
; The first 16 are the tile indexes (which are 16x16)
; The other 16 bytes are frame lengths, each frame is 16ms long.
; FF FD and FE are special values for frame lengths which are used to control
; the animation behavior. FF means STOP, FE means loop, FD means bounce

; Save Point
DB $00, $00,$01,$02,$03, $00,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff 
DB $fd, $09,$09,$09,$09, $fe,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff 

; Glow Flicker
DB $00, $00,$01,$02,$03, $00,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff 
DB $fd, $02,$02,$02,$02, $fe,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff 

; Powerup Hover
DB $00, $00,$01,$02,$03, $00,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff 
DB $fd, $b0,$06,$06,$06, $fe,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff 

