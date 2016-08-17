; animations
; - animation row
; - flags: [active][water collision][transparent][fg/bg] [color palette]
; - dy: 0-7, > 80 = negative movement
; - animation delay in frames
; - animation loop count (TODO $FF=endless loop)

; Oxygen Bubble
DB $00, %0101_0000, $85,$15, $01,$FF, $FF,$FF

; Test
DB $01, %0001_0001, $00,$19, $01,$FF, $FF,$FF

