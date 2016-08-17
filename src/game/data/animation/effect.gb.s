; animations
; - animation row
; - flags: [active][0][transparent][fg/bg] [color palette]
; - dy: 0-7, > 80 = negative movement
; - animation delay in frames
; - animation loop count

; Oxygen Bubble
DB $00, %0001_0000, $85,$15, $01,$FF, $FF,$FF

; Test
DB $01, %0001_0001, $00,$19, $01,$FF, $FF,$FF

