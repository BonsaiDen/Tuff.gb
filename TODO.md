
# Additions

- Conveyor Belts
- Moving Spikes
- Wind Gusts
- Gameboy Color Support
- Super Gameboy Border


# Fixes

- Finish horizontal block breaking

    - sound effects
    - screen shaking
    - movement delay
    - force running mode for a few more frames after each destroyed block


# Current Updates

- Switch Effects to Table based indexing
- Make patterns end not based on a $FF but by setting the highbyte of the second to last note index value
- Double Speed Mode



# Gameplay

## Player

- Run ability (twice the running speed) (hold b for some time during running)

    - Breaks blocks horizontally
    - bounces off when hitting a non-breakable wall
    - when active, trigger dissappearing blocks delayed

## World

- Warps (looking somehwat like save points) (implemted via entities?)
- Doors (or something the like, opened via keys or something similiar)

    - when removing, halt player and entities, shake screen, flash out, remove, flash in
    - rumble and "tada" sound

- Wind gusts accelerating tuff into different directions

    - Needs some sort of visual indicator
    - Needs additional x/y speed variables and acceleration

- Blocks which dissolve when standing on them

- Colletible stuff for end percentage
- Special ending based on percentage and save count

## Entities

- Butterflies
- Implement a simple function to check for adjacent block collision


## Collectables

- Keys and other collectables

    - Use entity flags to save state


# Design

## Sound

- Underwater sound effects (splash, swim, dive, jump out of water, pound into water)
- Background sounds (Waterfall, lava) (using sound channel 3 samples?)
- Different sounds for each hazard type (lava, spikes, electricity, water)
- Improve block breaking sound
- Running sound
- Bounce Sound
- Speed up falling block sound for better effect when running over the blocks

## Effects / Animation

- Cutscene when collecting a powerup

## Backgrounds

- Some distant objects to fill out the generic white backgrounds


# Engine

## Script System

- Scripts bound to rooms

    - Run while in the room / or once on entry?
    - Placed in separate files, compiled into a lookup table to save memory

## Map

- Mark Dark / Light Background tiles with different collision values (Might be useful for something?)


## Fixes

- fix random echo ram access during title screen and decompression of tile rows?


## Tweaks

- Pounding when diving is disabled (is not cancelled perfectly just yet player is left to deep in water when swimming after the pound was cancelled)
- Improve transition between pound end and diving up/down animation
- Double jump animation at top of jump
- disable double jump after wall jump, need to hit the ground before we can double jump again
- double jump out of water does not work (issue with jump threshold not being reached)
- Falling platforms should still trigger during running, but delayed so they disappear behind the player


# Route

- Intro
- Jump (Powerup)
- Portal Piece

- Swim (Powerup)
- Portal Piece

- Wall Jump (Powerup)
- Portal Piece
- Portal Piece

- Running (Powerup)
- Portal Piece
- Portal Piece

- Pounding (Powerup)
- Portal Piece
- Portal Piece

- Diving (Powerup)
- Portal Piece

- Double Jump (Powerup)
- Portal Piece
- Portal Piece
- Portal Piece

- Outro

