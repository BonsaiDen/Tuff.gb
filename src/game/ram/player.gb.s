SECTION "PlayerRam",WRAM0[$C0A0]

; Constants -------------------------------------------------------------------
PLAYER_DIRECTION_LEFT         EQU 1
PLAYER_DIRECTION_RIGHT        EQU 2

PLAYER_JUMP_FORCE             EQU 2
PLAYER_JUMP_WALL              EQU 2
PLAYER_JUMP_SCREEN_BOOST      EQU 2
PLAYER_FALL_MAX               EQU 3
PLAYER_SPEED_NORMAL           EQU 1
PLAYER_SPEED_FAST             EQU 2
PLAYER_SPEED_FULL             EQU 3
PLAYER_GRAVITY_MAX            EQU 2
PLAYER_GRAVITY_MAX_POUND      EQU 3
PLAYER_JUMP_SWIM              EQU 1
PLAYER_DOUBLE_JUMP_THRESHOLD  EQU $13; max jump frames are $1C
PLAYER_DOUBLE_JUMP_WATER_THRESHOLD  EQU $0B; max jump frames are $1C
PLAYER_RUNNING_DELAY          EQU 45; frames to be on ground and hold B before running mode sets in
PLAYER_RUNNING_DELAY_FULL     EQU 90; frames before full running speed

PLAYER_BOUNCE_FRAMES          EQU 30; number of frames without control after bouncing into a wall during running
PLAYER_DECELERATE_FRAMES      EQU 10

PLAYER_GRAVITY_INTERVAL       EQU 10

PLAYER_SLEEP_WAIT             EQU 255 ; ticks of 60ms timer = ~15.81 seconds
PLAYER_SPRITE_INDEX           EQU 0
PLAYER_HARDWARE_SPRITE_INDEX  EQU 8

PLAYER_ANIMATION_COUNT        EQU 16

PLAYER_ANIMATION_IDLE         EQU 0
PLAYER_ANIMATION_WALKING      EQU 1
PLAYER_ANIMATION_SLEEP        EQU 2
PLAYER_ANIMATION_PUSHING      EQU 3
PLAYER_ANIMATION_JUMP         EQU 4
PLAYER_ANIMATION_FALL         EQU 5
PLAYER_ANIMATION_RUNNING_FULL EQU 6
PLAYER_ANIMATION_SWIMMING     EQU 7
PLAYER_ANIMATION_DISSOLVE     EQU 8
PLAYER_ANIMATION_SURFACE      EQU 9
PLAYER_ANIMATION_SLIDE        EQU 10
PLAYER_ANIMATION_POUND_START  EQU 11
PLAYER_ANIMATION_POUND_END    EQU 12
PLAYER_ANIMATION_LANDING      EQU 13
PLAYER_ANIMATION_DOUBLE_JUMP  EQU 14
PLAYER_ANIMATION_RUNNING_HALF EQU 15

PLAYER_HALF_WIDTH             EQU 7
PLAYER_HEIGHT                 EQU 13
PLAYER_WATER_OFFSET_MAX       EQU 35

PLAYER_SLIDE_DURATION         EQU 40 ; in frames
PLAYER_SLIDE_SLOWDOWN         EQU 3 ; only apply fall speed every X other ticks while sliding
PLAYER_WALL_JUMP_WINDOW       EQU 5
PLAYER_WALL_JUMP_DURATION     EQU 12

PLAYER_LANDING_SOFT_THRESHOLD EQU 14
PLAYER_LANDING_HARD_THRESHOLD EQU 40

PLAYER_POUND_DELAY_START      EQU 45; delay in frames for pound start
PLAYER_POUND_DELAY_END        EQU 37; delay in frames for pound end
PLAYER_POUND_ALIGN_BORDER     EQU 4 ; number of x pixels in which players gets aligned with nearest breakable block

PLAYER_AIR_BUBBLE_INTERVAL    EQU 7; X * 60ms

PLAYER_ABILITY_JUMP           EQU 1 << 0; 1=1
PLAYER_ABILITY_WALL_JUMP      EQU 1 << 1; 2=2
PLAYER_ABILITY_SWIM           EQU 1 << 2; 3=4
PLAYER_ABILITY_DIVE           EQU 1 << 3; 4=8
PLAYER_ABILITY_POUND          EQU 1 << 4; 5=16
PLAYER_ABILITY_RUN            EQU 1 << 5; 6=32
PLAYER_ABILITY_DOUBLE_JUMP    EQU 1 << 6; 7=64
PLAYER_ABILITY_BREAK          EQU 1 << 7; 8=128

PLAYER_PLATFORM_DIR_LEFT      EQU 0
PLAYER_PLATFORM_DIR_RIGHT     EQU 1
PLAYER_PLATFORM_DIR_UP        EQU 2
PLAYER_PLATFORM_DIR_DOWN      EQU 3


; Player Variables for Save State ---------------------------------------------
playerX:                   DB
playerY:                   DB
playerDirection:           DB
playerAbility:             DB


; Variables -------------------------------------------------------------------
playerHasControl:          DB
playerYOffset:             DB ; y offset the player is rendered at, only visual
playerSpeedRight:          DB
playerSpeedLeft:           DB
playerRunningTick:         DB
playerMoveTick:            DB
playerMovementDelay:       DB

playerSleepTick:           DB
playerDecTick:             DB

playerAnimation:           DB
playerAnimationLast:       DB
playerAnimationRow:        DB

playerDirectionLast:       DB
playerDirectionWall:       DB
playerBounceFrames:        DB

; Pounding
playerIsPounding:          DB
playerPoundTick:           DB
playerPoundCenterX:        DB

; Running
playerIsRunning:           DB

; Breaking
playerBreakDelayed:        DB
playerBreakBlockM:         DB
playerBreakBlockR:         DB
playerBreakBlockL:         DB
playerBreakBlockOffset:    DB
playerBreakContinue:       DB ; frames for which the player will not loose speed or can control after a horizontal block has been broken

; Wall Jump
playerWallSlideDir:        DB ; direction of the wall which the player is/was sliding on
playerWallSlideTick:       DB ; number of ticks the player is sliding down the wall
playerWallJumpWindow:      DB ; number of ticks left in which a wall jump can be started
playerWallJumpDir:         DB ; direction of the wall from which the player jumped of
playerWallJumpTick:        DB ; ticks left during which the player movement will be forced into the direction of the wall jump
playerWallJumpPressed:     DB

; Gravity and Jumping
playerFallSpeed:           DB ; current fall speed per frame
playerFallFrames:          DB ; number of frames the player is falling (max 255)
playerLandingFrames:       DB ; number of frames for which the controls should be delayed after landing on ground

playerGravityTick:         DB ; ticker for applying gravity
playerGravityMax:          DB ; maximum gravity per tick
playerGravityDelay:        DB ; ticks for which gravity should not be applied
playerJumpPressed:         DB ; whether the jump button is still continously pressed
playerOnGround:            DB ; is the player on ground
playerJumpForce:           DB ; current jump force per frame
playerJumpFrames:          DB ; number of frames the current jump is active
playerDoubleJumped:        DB ; wether the double jump was performed since the last wall touch / on ground
playerJumpHold:            DB ; number of frames the jump button was hold down
playerDoubleJumpThreshold: DB

; Water and Swimming
playerInWater:             DB ; is the player in water?
playerUnderWater:          DB ; is the player in water?
playerWasUnderWater:       DB ; is the player in water?
playerWaterHitDone:        DB ; whether the intitial splash hit is done
playerWaterTick:           DB ; player water offset ticker
playerWaterHitDepth:       DB ; value to check how deep the player should splash into the water

; Dissolving
playerDissolveTick:        DB ; tick for when the player is dissolving

; Effects
playerEffectCounter:       DB ; counter used for periodic effects (air bubbles)

; Platforms
playerPlatformDirection:   DB
playerPlatformSpeed:       DB
playerPlatformY:           DB

