# Gameplay

## Player

- Run ability (twice the running speed) (hold b for some time during running)

    - Breaks blocks horizontally
    - needs all sort of code
    - when active, won't trigger dissappearing blocks
    - hidden in lava zone

- Double Jump

    - 

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

# Other

## Fixes

- swimming bug across horizontal screens

## Tweaks

- For breakable blocks prevent patterns by checking x and y for default dark tiles
- Pounding when diving is disabled (is not cancelled perfectly just yet player is left to deep in water when swimming after the pound was cancelled)
- When starting pounding, move player away from top collision edge



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
