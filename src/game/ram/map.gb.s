SECTION "MapRam",WRAM0[$CF24]; must be aligned at 256 bytes for tile buffer

; Constants -------------------------------------------------------------------
MAP_INDEX_SIZE              EQU     512
MAP_ROOM_SIZE               EQU     80
MAP_ENTITY_SIZE             EQU     8
MAP_ROOM_DATA_BANK          EQU     2
MAP_WIDTH                   EQU     16
MAP_HEIGHT                  EQU     16

MAP_BACKGROUND_TILE_LIGHT   EQU     $5f
MAP_BACKGROUND_TILE_DARK    EQU     $70
MAP_BACKGROUND_FADE_LEFT    EQU     $65
MAP_BACKGROUND_FADE_RIGHT   EQU     $66
MAP_BACKGROUND_FADE_TOP     EQU     $67
MAP_BACKGROUND_FADE_BOTTOM  EQU     $68

MAP_BREAKABLE_BLOCK_LIGHT   EQU     $39
MAP_BREAKABLE_BLOCK_DARK    EQU     $3a

MAP_MAX_FALLABLE_BLOCKS     EQU     16
MAP_FALLABLE_BLOCK_LIGHT    EQU     $2a
MAP_FALLING_TILE_LIGHT      EQU     $30


; Room drawing ----------------------------------------------------------------
mapRoomBlockBuffer:         DS MAP_ROOM_SIZE + MAP_ENTITY_SIZE ; buffer for the decompressed room data
mapRoomUpdateRequired:      DB
mapRoomEntityCount:         DB
mapCurrentScreenBuffer:     DB


; -----------------------------------------------------------------------------
mapRoomX:                   DB ; current x index on the map
mapRoomY:                   DB ; current y index on the map
mapRoomLastX:               DB ; last x index on the map
mapRoomLastY:               DB ; last y index on the map
mapCollisionFlag:           DB ; flag that gets set by the map collision check
                               ; used by game logic to trigger special behavior

; Fallable Blocks -------------------------------------------------------------
mapFallableBlocks:          DS MAP_MAX_FALLABLE_BLOCKS * 4; [Type7Active1][frame][x][y]
mapFallableBlockCount:      DB


; Tile Animations -------------------------------------------------------------
TILE_ANIMATION_COUNT        EQU 16
TILE_ANIMATION_DATA_COUNT   EQU 11
mapAnimationIndexes         DS TILE_ANIMATION_COUNT
mapAnimationDelay           DS TILE_ANIMATION_COUNT
mapAnimationUseMap          DS TILE_ANIMATION_COUNT


; RAM Buffers -----------------------------------------------------------------
SECTION "MapBufferRam",WRAM0[$C100]; must be aligned at 256 bytes for tile buffer
mapRoomTileBuffer:          DS 512; tile buffer for the current room (8x8 tiles)
mapBlockDefinitionBuffer    DS 1024; buffer for tile definitions of the current room
mapTileAnimationBuffer      DS 1024; buffer for tile animation graphics

