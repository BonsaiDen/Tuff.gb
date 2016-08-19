; animations
; - animation row
; - flags: [active][water collision][transparent][bg/fg] [x][flip_y][flip_x][color palette]
; - dy: 0-7, > 80 = negative movement
; - animation delay in frames
; - animation loop count ($FF=endless loop)

; Oxygen Bubble
DB $00, %0101_0000, $85,$13, $01,$FF, $FF,$FF

; Fire flare
DB $01, %0001_0001, $00,$11, $FF,$FF, $FF,$FF

; Dust Cloud
DB $02, %0001_0001, $00,$07, $01,$FF, $FF,$FF

; Small Dust Cloud
DB $03, %0001_0001, $00,$05, $01,$FF, $FF,$FF

; Water Splash In Left
DB $04, %0001_0011, $00,$05, $01,$FF, $FF,$FF

; Water Splash In Right
DB $04, %0001_0001, $00,$05, $01,$FF, $FF,$FF

; Dust Cloud Fast
DB $02, %0001_0001, $00,$03, $01,$FF, $FF,$FF

; Water Splash Out Left
DB $04, %0001_0111, $00,$05, $01,$FF, $FF,$FF

; Water Splash Out Right
DB $04, %0001_0101, $00,$05, $01,$FF, $FF,$FF

; Wall Dust Left
DB $05, %0001_0001, $00,$03, $01,$FF, $FF,$FF

; Wall Dust Right
DB $05, %0001_0011, $00,$03, $01,$FF, $FF,$FF
