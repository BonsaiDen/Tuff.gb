SECTION "MapRam",WRAMX[$DE00]

; Constants -------------------------------------------------------------------
MAP_INDEX_SIZE              EQU     512
MAP_ROOM_WIDTH              EQU     15
MAP_ROOM_HEIGHT             EQU     13
MAP_ROOM_SIZE               EQU     MAP_ROOM_WIDTH * MAP_ROOM_HEIGHT
MAP_ROOM_EDGE_BOTTOM        EQU     (MAP_ROOM_HEIGHT * 16) - 1
MAP_ROOM_EDGE_RIGHT         EQU     (MAP_ROOM_WIDTH * 16) - 1
MAP_ENTITY_SIZE             EQU     8
MAP_EFFECT_SIZE             EQU     8
MAP_ROOM_DATA_BANK          EQU     2
MAP_WIDTH                   EQU     16
MAP_HEIGHT                  EQU     16

MAP_COLLISION_NONE          EQU     0
MAP_COLLISION_BLOCK         EQU     1
MAP_COLLISION_WATER         EQU     2
MAP_COLLISION_WATER_DEEP    EQU     3
MAP_COLLISION_LAVA          EQU     4
MAP_COLLISION_BREAKABLE     EQU     5
MAP_COLLISION_SPIKES        EQU     6
MAP_COLLISION_ELECTRIC      EQU     7

MAP_BLOCK_TILES_TOP         EQU     0
MAP_BLOCK_TILES_LEFT        EQU     1
MAP_BLOCK_TILES_BOTTOM      EQU     2
MAP_BLOCK_TILES_RIGHT       EQU     3

TILE_ANIMATION_COUNT        EQU     16
TILE_ANIMATION_DATA_COUNT   EQU     11

MAP_BACKGROUND_TILE_LIGHT   EQU     $5f
MAP_BACKGROUND_TILE_DARK_L  EQU     $64
MAP_BACKGROUND_TILE_DARK_R  EQU     $63
MAP_BACKGROUND_FADE_LEFT    EQU     $65
MAP_BACKGROUND_FADE_RIGHT   EQU     $66
MAP_BACKGROUND_FADE_TOP     EQU     $67
MAP_BACKGROUND_FADE_BOTTOM  EQU     $68

MAP_BREAKABLE_BLOCK_LIGHT   EQU     $39
MAP_BREAKABLE_BLOCK_DARK    EQU     $3a

MAP_MAX_FALLABLE_BLOCKS     EQU     16

MAP_FALLABLE_BLOCK_LIGHT    EQU     $2A
MAP_FALLABLE_BLOCK_DARK     EQU     $27
MAP_FALLING_TILE_LIGHT      EQU     $30
MAP_FALLING_TILE_DARK       EQU     $38
MAP_FALLABLE_BLOCK_DELAY    EQU     2

MAP_SCROLL_LOCK_VERTICAL    EQU     1
MAP_SCROLL_LOCK_HORIZOTNAL  EQU     2

MAP_MAX_OVERRIDE_BLOCKS     EQU     10 * 4


; Room drawing ----------------------------------------------------------------
mapRoomBlockBuffer:         DS MAP_ROOM_SIZE + MAP_ENTITY_SIZE + MAP_EFFECT_SIZE ; buffer for the decompressed room data
mapRoomUpdateRequired:      DB
mapRoomEntityCount:         DB
mapRoomEffectCount:         DB
mapCurrentScreenBuffer:     DB
mapRoomHeaderFlags:         DB
mapRoomTileBlockMap:        DB
mapRoomTileLastBlockMap:    DB


; -----------------------------------------------------------------------------
mapRoomX:                   DB ; current x index on the map
mapRoomY:                   DB ; current y index on the map
mapRoomLastX:               DB ; last x index on the map
mapRoomLastY:               DB ; last y index on the map
mapScrollFlags:             DB ; horizontal / vertical scroll lock
mapCollisionFlag:           DB ; flag that gets set by the map collision check
                               ; used by game logic to trigger special behavior
mapHazardFlag:              DB ; flag that gets once per game loop when a hazard
                               ; block was found


; Fallable Blocks -------------------------------------------------------------
mapFallableBlocks:          DS MAP_MAX_FALLABLE_BLOCKS * 4; [Delay4Non2Type1Active1][frame][x][y]
mapFallableBlockCount:      DB


; Tile Animations -------------------------------------------------------------
mapAnimationIndexes:        DS TILE_ANIMATION_COUNT
mapAnimationDelay:          DS TILE_ANIMATION_COUNT
mapAnimationUseMap:         DS TILE_ANIMATION_COUNT


; Breakable Blocks ------------------------------------------------------------
mapOverridenBlocks:         DS MAP_MAX_OVERRIDE_BLOCKS * 4; [roomId][x][y][tileValue]


; RAM Buffers -----------------------------------------------------------------
SECTION "MapBufferRam",WRAM0[$C100]; must be aligned at 256 bytes for tile buffer
mapBlockDefinitionBuffer:   DS 1024; buffer for tile definitions of the current room
mapTileAnimationBuffer:     DS 1024; buffer for tile animation graphics
mapRoomTileBuffer:          DS 32 * MAP_ROOM_HEIGHT * 2; tile buffer for the current room (8x8 tiles)

