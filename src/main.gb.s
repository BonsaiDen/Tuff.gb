; ROM Definitions -------------------------------------------------------------
INCLUDE     "core/include/rom.inc"


; Catridge Information --------------------------------------------------------
CART_NAME       EQUS       "Tuff"
CART_LICENSEE   EQUS       "BD"
CART_TYPE       EQU        ROM_MBC5_RAM_BAT
CART_ROM_SIZE   EQU        ROM_SIZE_64KBYTE
CART_RAM_SIZE   EQU        RAM_SIZE_64KBIT
CART_DEST       EQU        ROM_DEST_OTHER


; Include Core Library --------------------------------------------------------
INCLUDE     "core/core.gb.s"


; Constants and Variables -----------------------------------------------------
INCLUDE     "game/ram/sprite.gb.s"
INCLUDE     "game/ram/map.gb.s"
INCLUDE     "game/ram/game.gb.s"
INCLUDE     "game/ram/title.gb.s"
INCLUDE     "game/ram/screen.gb.s"
INCLUDE     "game/ram/player.gb.s"
INCLUDE     "game/ram/entity.gb.s"
INCLUDE     "game/ram/sound.gb.s"


; Modules ---------------------------------------------------------------------
INCLUDE     "game/entity.gb.s"
INCLUDE     "game/map.gb.s"
INCLUDE     "game/player.gb.s"
INCLUDE     "game/save.gb.s"
INCLUDE     "game/sprite.gb.s"
INCLUDE     "game/screen.gb.s"
INCLUDE     "game/sound.gb.s"
INCLUDE     "game/title.gb.s"
INCLUDE     "game/tileset.gb.s"


; Main Game -------------------------------------------------------------------
INCLUDE     "game/game.gb.s"


; Data ------------------------------------------------------------------------
INCLUDE     "game/data/bank1.gb.s"
INCLUDE     "game/data/bank2.gb.s"

