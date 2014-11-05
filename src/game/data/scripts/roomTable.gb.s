scriptRoomTable:
    room(8, 8, 0, label)

MACRO room(@x, @y, @flags, @address)
    DB @x << 8 | @y

ENDMACRO

