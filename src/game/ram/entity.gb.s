SECTION "EntityRam",WRAM0[$CD00]; must be aligned at 256 bytes for screenState

; Constants -------------------------------------------------------------------
ENTITY_PER_ROOM               EQU 4
ENTITY_SPRITE_OFFSET          EQU 1
ENTITY_BG_SPRITE_INDEX        EQU 5; start indexes to use for entity sprites that are in the background
ENTITY_FG_SPRITE_INDEX        EQU 0; start indexes to use for entity sprites that are in the foreground

ENTITY_ANIMATION_OFFSET       EQU PLAYER_ANIMATION_COUNT
ENTITY_ANIMATION_SAVE_LIGHT   EQU 0
ENTITY_ANIMATION_SAVE_DARK    EQU 1
ENTITY_ANIMATION_GLOW         EQU 2
ENTITY_ANIMATION_POWERUP      EQU 3
ENTITY_ANIMATION_GEM          EQU 4

ENTITY_DIRECTION_UP           EQU 0
ENTITY_DIRECTION_RIGHT        EQU 1
ENTITY_DIRECTION_DOWN         EQU 2
ENTITY_DIRECTION_LEFT         EQU 3

ENTITY_MAX_STORE_BUCKETS      EQU 128
ENTITY_STORED_STATE_SIZE      EQU ENTITY_MAX_STORE_BUCKETS * 4


; RAM storage for entity positions / states -----------------------------------
; mapStorage format is 2 bytes per entity [ddtttttt] xxxxyyyy (type, direction, x, y)
entityScreenState:      DS  32 ; 8 bytes per entity 
                               ; [type][flags][direction][y] 
                               ; [x][tileslot][custom][custom]
                               ; type > 0 = entity is active

entityTileRowMap:       DS  4 ; which entity tile rows are currently mapped into vram

entityStoredState:      DS  ENTITY_STORED_STATE_SIZE 
                              ; 4 bytes per bucket entry

entityUpdateActive:     DS  1  ; whether entity logic updates are performed


