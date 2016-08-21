# Rework lava death animation

- Fall deeper into lava (slowly move in?)
- Fire effects


# GFX 

- GFX when running fast?

# Scripts

- Save script state / check if script was run

# Gems

- Gem Entity, save collected flag and increase gem counter


# Drowning

- Slowly fade out screen while under water until tuff drowns


# Graphics

- super gameboy border support
    - support gameboy color support?

- colorize water and lava on gameboy color etc.


# Outdated --------------------------------------------------------------------



# Additions

- Conveyor Belts
- Moving Spikes (In and out of blocks)
- Wind Gusts
- Super Gameboy Border
- Falling Blocks from above when walking underneath


# Gameplay

## World

- Warps (looking somehwat like save points) (implemted via entities?)
- Doors (or something the like, opened via keys or something similiar)

    - when removing, halt player and entities, shake screen, flash out, remove, flash in
    - rumble and "tada" sound

- Wind gusts accelerating tuff into different directions

    - Needs some sort of visual indicator
    - Needs additional x/y speed variables and acceleration

- Colletible stuff for end percentage
- Special ending based on percentage and save count

## Entities

- Butterflies
- Implement a simple function to check for adjacent block collision


## Collectables

- Keys and other collectables


# Design

## Sound

- Background sounds (Waterfall, lava) (using sound channel 3 samples?)
- Different sounds for each hazard type (lava, spikes, electricity, water)
- Running sound
- Bounce Sound
- Speed up falling block sound for better effect when running over the blocks

## Effects / Animation

- Cutscene when collecting a powerup

## Backgrounds

- Some distant objects to fill out the generic white backgrounds


# Engine

## Map

- Mark Dark / Light Background tiles with different collision values (Might be useful for something?)


## Fixes

- fix random echo ram access during title screen and decompression of tile rows?


## Tweaks

- Improve transition between pound end and diving up/down animation
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

